import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { audit, requireModule } from "./admin.js";
import { finalizePayment, loadSettings, resolveIntent, storedIntent } from "./payments.js";
import { isValidUpiId, normaliseUtr, upiReference } from "./util.js";
import { slotDocId, type SevaDoc } from "./validation.js";

/**
 * Direct UPI payments to the temple's own UPI ID (no gateway, no fees).
 *
 * 1. `createUpiPayment` validates and prices the request and returns the
 *    UPI ID, amount and a reference for the QR / UPI-app link.
 * 2. The devotee pays in any UPI app and submits the 12-digit UTR with
 *    `submitUpiPayment`. A seva place is held from this point.
 * 3. The office checks the bank / UPI-app statement and approves or rejects
 *    with `reviewUpiPayment`. Only approval creates the donation/booking and
 *    receipt (through `finalizePayment`).
 *
 * UPI gives no automatic confirmation for a personal or plain merchant UPI
 * ID, so step 3 is a human check against the statement.
 */

const REGION = "asia-south1";
const db = () => getFirestore();

export const createUpiPayment = onCall({ region: REGION }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "कृपया पुन्हा प्रयत्न करा");
  const settings = await loadSettings();
  if (!isValidUpiId(settings.upiId)) throw new HttpsError("failed-precondition", "मंदिराचा UPI ID अजून सेट केलेला नाही");
  const raw = (req.data ?? {}) as Record<string, unknown>;
  const { intent, amountPaise } = await resolveIntent(raw, settings);

  const ref = db().collection("payments").doc();
  const reference = upiReference(ref.id);
  const name = intent.purpose === "donation" ? intent.input.name : intent.input.devoteeName;
  const description = intent.purpose === "donation"
    ? intent.input.category
    : `${intent.seva.name} – ${intent.input.date}, ${intent.input.timeSlot}`;
  await ref.set({
    orderId: ref.id,
    method: "upi",
    reference,
    purpose: intent.purpose,
    userId: uid,
    amountPaise,
    name,
    mobile: intent.input.mobile,
    description,
    status: "CREATED",
    intent: storedIntent(intent),
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return {
    paymentId: ref.id,
    amountPaise,
    upiId: settings.upiId!.trim(),
    payeeName: settings.upiPayeeName?.trim() || "Shri Kalbhairav Jagrut Devsthan",
    reference,
  };
});

export const submitUpiPayment = onCall({ region: REGION }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "कृपया पुन्हा प्रयत्न करा");
  const { paymentId } = (req.data ?? {}) as { paymentId?: string };
  const utr = normaliseUtr((req.data as { utr?: unknown } | undefined)?.utr);
  if (!paymentId) throw new HttpsError("invalid-argument", "Missing payment");
  if (!utr) throw new HttpsError("invalid-argument", "UTR / UPI Ref No. 12 अंकी असावा");

  const payRef = db().doc(`payments/${paymentId}`);
  const utrRef = db().doc(`upi_utrs/${utr}`);
  await db().runTransaction(async (tx) => {
    const pay = (await tx.get(payRef)).data();
    if (!pay || pay.userId !== uid || pay.method !== "upi") throw new HttpsError("not-found", "Payment not found");
    if (pay.status === "PENDING_VERIFICATION" && pay.utr === utr) return; // retry of the same submit
    if (pay.status !== "CREATED") throw new HttpsError("failed-precondition", "हे पेमेंट आधीच पाठवले आहे");
    if ((await tx.get(utrRef)).exists) {
      throw new HttpsError("already-exists", "हा UTR क्रमांक आधीच वापरला गेला आहे");
    }

    let slotHeld = false;
    if (pay.purpose === "seva") {
      const i = pay.intent as { sevaId: string; date: string; timeSlot: string };
      const slotRef = db().doc(`seva_slot_counts/${slotDocId(i.sevaId, i.date, i.timeSlot)}`);
      const seva = (await tx.get(db().doc(`sevas/${i.sevaId}`))).data() as SevaDoc | undefined;
      const used = Number((await tx.get(slotRef)).data()?.count ?? 0);
      if (used >= Number(seva?.capacityPerSlot ?? 0)) {
        throw new HttpsError("resource-exhausted", "या वेळेसाठी जागा भरल्या. कृपया मंदिर कार्यालयाशी संपर्क साधा.");
      }
      tx.set(slotRef, { count: used + 1, sevaId: i.sevaId, date: i.date, timeSlot: i.timeSlot }, { merge: true });
      slotHeld = true;
    }
    tx.set(utrRef, { paymentId, userId: uid, at: FieldValue.serverTimestamp() });
    tx.update(payRef, {
      status: "PENDING_VERIFICATION", utr, slotHeld, submittedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  return { status: "PENDING_VERIFICATION" };
});

export const reviewUpiPayment = onCall({ region: REGION }, async (req) => {
  const actor = requireModule(req, "payments");
  const { paymentId, approve, reason } = (req.data ?? {}) as { paymentId?: string; approve?: boolean; reason?: string };
  if (!paymentId) throw new HttpsError("invalid-argument", "Missing payment");
  const payRef = db().doc(`payments/${paymentId}`);
  const pay = (await payRef.get()).data();
  if (!pay || pay.method !== "upi") throw new HttpsError("not-found", "Payment not found");

  if (approve === true) {
    if (pay.status === "SUCCESS") return { status: "SUCCESS", number: pay.number };
    if (pay.status !== "PENDING_VERIFICATION") throw new HttpsError("failed-precondition", `Payment is ${pay.status}`);
    const r = await finalizePayment(paymentId, `UPI-${pay.utr}`, `upi:${actor.uid}`);
    await payRef.update({ reviewedBy: actor.uid, reviewedByName: actor.name, reviewedAt: FieldValue.serverTimestamp() });
    await audit(actor.uid, actor.name, "upi_approve", "payments", paymentId, `${pay.utr} ₹${pay.amountPaise / 100} → ${r.number}`);
    return { status: "SUCCESS", number: r.number };
  }

  const why = String(reason ?? "").trim().slice(0, 200) || "पेमेंट बँक खात्यात आढळले नाही";
  await db().runTransaction(async (tx) => {
    const cur = (await tx.get(payRef)).data();
    if (!cur || cur.status !== "PENDING_VERIFICATION") throw new HttpsError("failed-precondition", `Payment is ${cur?.status}`);
    if (cur.slotHeld && cur.purpose === "seva") {
      const i = cur.intent as { sevaId: string; date: string; timeSlot: string };
      const slotRef = db().doc(`seva_slot_counts/${slotDocId(i.sevaId, i.date, i.timeSlot)}`);
      const used = Number((await tx.get(slotRef)).data()?.count ?? 0);
      tx.set(slotRef, { count: Math.max(0, used - 1) }, { merge: true });
    }
    // Free the UTR so a mistyped number can be corrected on a new attempt.
    if (cur.utr) tx.delete(db().doc(`upi_utrs/${cur.utr}`));
    tx.update(payRef, {
      status: "REJECTED", slotHeld: false, rejectReason: why, reviewedBy: actor.uid, reviewedByName: actor.name,
      reviewedAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
    });
  });
  await db().collection("notifications").add({
    title: "UPI पेमेंट पडताळणी",
    body: `₹${pay.amountPaise / 100} (UTR ${pay.utr}) चे पेमेंट स्वीकारता आले नाही: ${why}. कृपया मंदिर कार्यालयाशी संपर्क साधा.`,
    type: "donation",
    target: "user",
    targetId: pay.userId,
    route: "/profile/donations",
    createdAt: FieldValue.serverTimestamp(),
    system: true,
  });
  await audit(actor.uid, actor.name, "upi_reject", "payments", paymentId, `${pay.utr}: ${why}`);
  return { status: "REJECTED" };
});
