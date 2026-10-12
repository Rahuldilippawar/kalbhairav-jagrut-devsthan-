import { randomBytes } from "node:crypto";

import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { defineString } from "firebase-functions/params";
import { HttpsError, onCall, type CallableRequest } from "firebase-functions/v2/https";

import { can, isRole, type Module } from "./rbac.js";

const REGION = "asia-south1";
const db = () => getFirestore();

/** Comma separated list of emails allowed to claim the first super admin seat. */
const BOOTSTRAP_SUPER_ADMIN_EMAILS = defineString("BOOTSTRAP_SUPER_ADMIN_EMAILS", { default: "" });

export function requireModule(req: CallableRequest, module: Module) {
  const role = req.auth?.token.role;
  if (!req.auth || !can(role, module)) throw new HttpsError("permission-denied", "You do not have access to this action");
  return { uid: req.auth.uid, role: role as string, name: (req.auth.token.name as string) ?? req.auth.token.email ?? req.auth.uid };
}

export async function audit(actorId: string, actorName: string, action: string, collection: string, recordId: string, summary: string) {
  await db().collection("audit_logs").add({ actorId, actorName, action, collection, recordId, summary, at: FieldValue.serverTimestamp() });
}

/**
 * Super admin assigns (or removes, with role = null) an admin role. Creates
 * the Firebase Auth account if needed and returns a password-setup link.
 */
export const setAdminRole = onCall({ region: REGION }, async (req) => {
  const actor = requireModule(req, "users");
  const { email, role, name } = (req.data ?? {}) as { email?: string; role?: string | null; name?: string };
  if (!email || !/^[^@\s]+@[^@\s]+$/.test(email)) throw new HttpsError("invalid-argument", "Valid email required");
  if (role !== null && !isRole(role)) throw new HttpsError("invalid-argument", "Unknown role");

  const auth = getAuth();
  let user;
  let setupLink: string | undefined;
  try {
    user = await auth.getUserByEmail(email);
  } catch {
    if (role === null) throw new HttpsError("not-found", "No such user");
    user = await auth.createUser({ email, displayName: name, password: randomBytes(18).toString("base64url") });
    setupLink = await auth.generatePasswordResetLink(email);
  }
  if (user.uid === actor.uid && role !== "super_admin") {
    throw new HttpsError("failed-precondition", "You cannot remove your own super admin role");
  }

  await auth.setCustomUserClaims(user.uid, { ...(user.customClaims ?? {}), role: role ?? null });
  const ref = db().doc(`admin_users/${user.uid}`);
  if (role === null) {
    await ref.set({ active: false, role: null, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  } else {
    await ref.set(
      { email, name: name ?? user.displayName ?? "", role, active: true, updatedAt: FieldValue.serverTimestamp(), createdAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  }
  await audit(actor.uid, actor.name, "role_change", "admin_users", user.uid, `${email} → ${role ?? "removed"}`);
  return { uid: user.uid, setupLink };
});

/** One-time: the configured owner email claims super admin when none exists. */
export const claimSuperAdmin = onCall({ region: REGION }, async (req) => {
  const email = req.auth?.token.email;
  const allowed = BOOTSTRAP_SUPER_ADMIN_EMAILS.value().split(",").map((e) => e.trim().toLowerCase()).filter(Boolean);
  if (!req.auth || !email || !allowed.includes(email.toLowerCase())) {
    throw new HttpsError("permission-denied", "Email not in BOOTSTRAP_SUPER_ADMIN_EMAILS");
  }
  const existing = await db().collection("admin_users").where("role", "==", "super_admin").limit(1).get();
  if (!existing.empty) throw new HttpsError("already-exists", "A super admin already exists");
  await getAuth().setCustomUserClaims(req.auth.uid, { role: "super_admin" });
  await db().doc(`admin_users/${req.auth.uid}`).set({
    email, name: req.auth.token.name ?? "", role: "super_admin", active: true, createdAt: FieldValue.serverTimestamp(),
  });
  await audit(req.auth.uid, email, "role_change", "admin_users", req.auth.uid, "bootstrap super_admin");
  return { ok: true };
});

/**
 * Volunteer scans a QR Seva Pass (`KJD|SEVA|<id>|<bookingNo>`) or types the
 * booking number. Moves BOOKED → CHECK-IN (or CHECK-IN → COMPLETED).
 */
export const checkInBooking = onCall({ region: REGION }, async (req) => {
  const actor = requireModule(req, "checkIn");
  const { qr, bookingNo, complete } = (req.data ?? {}) as { qr?: string; bookingNo?: string; complete?: boolean };

  let ref;
  if (qr) {
    const p = qr.trim().split("|");
    if (p.length !== 4 || p[0] !== "KJD" || p[1] !== "SEVA") throw new HttpsError("invalid-argument", "Not a Seva Pass QR");
    ref = db().doc(`seva_bookings/${p[2]}`);
    const snap = await ref.get();
    if (!snap.exists || snap.data()!.bookingNo !== p[3]) throw new HttpsError("not-found", "Booking not found");
  } else if (bookingNo) {
    const q = await db().collection("seva_bookings").where("bookingNo", "==", bookingNo.trim().toUpperCase()).limit(1).get();
    if (q.empty) throw new HttpsError("not-found", "Booking not found");
    ref = q.docs[0].ref;
  } else {
    throw new HttpsError("invalid-argument", "QR or booking number required");
  }

  const booking = await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const b = snap.data()!;
    const from = b.status as string;
    const to = complete ? "COMPLETED" : "CHECK-IN";
    const allowed = complete ? ["BOOKED", "CHECK-IN"] : ["BOOKED"];
    if (!allowed.includes(from)) throw new HttpsError("failed-precondition", `Booking is ${from}`);
    tx.update(ref, {
      status: to,
      ...(complete ? { completedAt: FieldValue.serverTimestamp() } : { checkedInAt: FieldValue.serverTimestamp(), checkedInBy: actor.uid }),
    });
    return { id: snap.id, ...b, status: to };
  });
  await audit(actor.uid, actor.name, complete ? "complete" : "check_in", "seva_bookings", booking.id, String((booking as { bookingNo?: string }).bookingNo));
  return booking;
});

/** Seva manager cancels a booking and frees its slot. Any refund is made from the UPI app. */
export const cancelBooking = onCall({ region: REGION }, async (req) => {
  const actor = requireModule(req, "bookings");
  const { bookingId, reason } = (req.data ?? {}) as { bookingId?: string; reason?: string };
  if (!bookingId) throw new HttpsError("invalid-argument", "bookingId required");
  const ref = db().doc(`seva_bookings/${bookingId}`);
  await db().runTransaction(async (tx) => {
    const b = (await tx.get(ref)).data();
    if (!b) throw new HttpsError("not-found", "Booking not found");
    if (b.status === "CANCELLED" || b.status === "COMPLETED") throw new HttpsError("failed-precondition", `Booking is ${b.status}`);
    const slotRef = db().doc(`seva_slot_counts/${b.sevaId}_${b.dateKey}_${String(b.timeSlot).replace(":", "")}`);
    tx.update(ref, { status: "CANCELLED", cancelReason: reason ?? null, cancelledAt: FieldValue.serverTimestamp(), cancelledBy: actor.uid });
    tx.set(slotRef, { count: FieldValue.increment(-1) }, { merge: true });
  });
  await audit(actor.uid, actor.name, "cancel", "seva_bookings", bookingId, reason ?? "");
  return { ok: true };
});
