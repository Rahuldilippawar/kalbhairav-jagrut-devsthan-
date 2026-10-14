import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { audit, requireModule } from "./admin.js";
import { shishyaReviewMessage, type ShishyaDecision } from "./util.js";

const REGION = "asia-south1";
const db = () => getFirestore();

/**
 * Temple management approves, rejects or blocks a shishya's Guru Gyan
 * request. The shishya gets a push notification that opens Guru Gyan.
 */
export const reviewShishya = onCall({ region: REGION }, async (req) => {
  const actor = requireModule(req, "devotees");
  const { uid, status, reason } = (req.data ?? {}) as { uid?: string; status?: string; reason?: string };
  if (!uid) throw new HttpsError("invalid-argument", "Missing shishya");
  if (status !== "approved" && status !== "rejected" && status !== "blocked") {
    throw new HttpsError("invalid-argument", "Unknown status");
  }
  const ref = db().doc(`shishyas/${uid}`);
  const cur = (await ref.get()).data();
  if (!cur) throw new HttpsError("not-found", "Request not found");
  const why = String(reason ?? "").trim().slice(0, 200);
  await ref.update({
    status,
    rejectReason: status === "approved" ? FieldValue.delete() : why || null,
    reviewedBy: actor.uid,
    reviewedByName: actor.name,
    reviewedAt: FieldValue.serverTimestamp(),
  });
  await audit(actor.uid, actor.name, `shishya_${status}`, "shishyas", uid, `${cur.name ?? ""} ${cur.mobile ?? ""} ${why}`.trim());
  if (cur.status !== status) {
    const msg = shishyaReviewMessage(status as ShishyaDecision, String(cur.name ?? ""), why);
    await db().collection("notifications").add({
      ...msg,
      type: "announcement",
      target: "user",
      targetId: uid,
      route: "/guru",
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  return { status };
});

/** Sets a new password for a shishya who forgot theirs. */
export const resetShishyaPassword = onCall({ region: REGION }, async (req) => {
  const actor = requireModule(req, "devotees");
  const { uid, password } = (req.data ?? {}) as { uid?: string; password?: string };
  if (!uid) throw new HttpsError("invalid-argument", "Missing shishya");
  if (!password || password.length < 6) throw new HttpsError("invalid-argument", "Password must be at least 6 characters");
  const shishya = (await db().doc(`shishyas/${uid}`).get()).data();
  if (!shishya) throw new HttpsError("not-found", "Shishya not found");
  const user = await getAuth().getUser(uid).catch(() => null);
  // Only shishya logins (never an admin account) can be reset here.
  if (!user?.email?.endsWith("@shishya.kalbhairav.app")) throw new HttpsError("failed-precondition", "No shishya login for this account");
  await getAuth().updateUser(uid, { password });
  await audit(actor.uid, actor.name, "shishya_password_reset", "shishyas", uid, String(shishya.name ?? ""));
  return { ok: true };
});
