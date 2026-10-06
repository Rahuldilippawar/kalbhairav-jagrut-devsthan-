import { getFirestore, FieldValue, Timestamp, type Transaction } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { defineSecret, defineString } from "firebase-functions/params";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";

import { formatSequence, verifyCheckoutSignature, verifyWebhookSignature } from "./util.js";
import {
  DEFAULT_SETTINGS, parseBooking, parseDonation, slotDocId,
  type BookingInput, type DonationInput, type SevaDoc, type Settings,
} from "./validation.js";

export const RAZORPAY_KEY_ID = defineString("RAZORPAY_KEY_ID");
export const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");
export const RAZORPAY_WEBHOOK_SECRET = defineSecret("RAZORPAY_WEBHOOK_SECRET");

const REGION = "asia-south1";
const db = () => getFirestore();

async function loadSettings(): Promise<Settings> {
  const snap = await db().doc("app_settings/main").get();
  return { ...DEFAULT_SETTINGS, ...(snap.data() ?? {}) } as Settings;
}

function authHeader(): string {
  return "Basic " + Buffer.from(`${RAZORPAY_KEY_ID.value()}:${RAZORPAY_KEY_SECRET.value()}`).toString("base64");
}

async function razorpay<T>(path: string, body: unknown): Promise<T> {
  const res = await fetch(`https://api.razorpay.com/v1/${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: authHeader() },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const text = await res.text();
    logger.error("Razorpay API error", { path, status: res.status, text });
    throw new HttpsError("unavailable", "पेमेंट सेवा सध्या उपलब्ध नाही. कृपया पुन्हा प्रयत्न करा.");
  }
  return (await res.json()) as T;
}

type Intent =
  | { purpose: "donation"; input: DonationInput }
  | { purpose: "seva"; input: BookingInput; seva: SevaDoc };

/**
 * Step 1 – validates the request, prices it server-side and creates a
 * Razorpay order. Nothing is booked or receipted until verification.
 */
export const createPaymentOrder = onCall(
  { region: REGION, secrets: [RAZORPAY_KEY_SECRET], enforceAppCheck: false },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "कृपया लॉगिन करा");
    const raw = (req.data ?? {}) as Record<string, unknown>;
    const settings = await loadSettings();

    let intent: Intent;
    let amountPaise: number;
    if (raw.purpose === "donation") {
      const r = parseDonation(raw, settings);
      if (!r.ok) throw new HttpsError("invalid-argument", r.error);
      intent = { purpose: "donation", input: r.value };
      amountPaise = r.value.amountPaise;
    } else if (raw.purpose === "seva") {
      const sevaSnap = await db().doc(`sevas/${String(raw.sevaId ?? "")}`).get();
      const seva = sevaSnap.data() as SevaDoc | undefined;
      const slot = await db()
        .doc(`seva_slot_counts/${slotDocId(sevaSnap.id, String(raw.date ?? ""), String(raw.timeSlot ?? ""))}`)
        .get();
      const r = parseBooking(raw, seva, settings, Number(slot.data()?.count ?? 0));
      if (!r.ok) throw new HttpsError("invalid-argument", r.error);
      intent = { purpose: "seva", input: r.value, seva: seva! };
      amountPaise = seva!.pricePaise; // never trust a client-side price
    } else {
      throw new HttpsError("invalid-argument", "Unknown purpose");
    }

    const order = await razorpay<{ id: string; amount: number }>("orders", {
      amount: amountPaise,
      currency: "INR",
      receipt: `${intent.purpose}-${Date.now()}`.slice(0, 40),
      notes: { uid, purpose: intent.purpose },
    });

    await db().doc(`payments/${order.id}`).set({
      orderId: order.id,
      purpose: intent.purpose,
      userId: uid,
      amountPaise,
      status: "CREATED",
      intent: intent.purpose === "seva" ? { ...intent.input, sevaName: intent.seva.name } : intent.input,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { orderId: order.id, amountPaise, keyId: RAZORPAY_KEY_ID.value() };
  },
);

export interface FinalizeResult {
  refId: string;
  receiptId: string;
  number: string;
  refundRequired?: boolean;
}

async function nextNumber(tx: Transaction, counter: string): Promise<number> {
  const ref = db().doc(`counters/${counter}`);
  const snap = await tx.get(ref);
  return Number(snap.data()?.value ?? 0) + 1;
}

/** IST midnight of a `yyyy-MM-dd` key. */
const istMidnight = (key: string) => Timestamp.fromDate(new Date(`${key}T00:00:00+05:30`));

/**
 * Step 3 (shared by `verifyPayment` and the webhook) – idempotently turns
 * a paid order into donation/booking + receipt documents.
 */
export async function finalizePayment(orderId: string, paymentId: string, source: string): Promise<FinalizeResult> {
  const paymentRef = db().doc(`payments/${orderId}`);
  const result = await db().runTransaction<FinalizeResult>(async (tx) => {
    const paySnap = await tx.get(paymentRef);
    if (!paySnap.exists) throw new HttpsError("not-found", "Order not found");
    const pay = paySnap.data()!;
    if (pay.status === "SUCCESS") {
      return { refId: pay.refId, receiptId: pay.receiptId, number: pay.number };
    }
    if (pay.status === "REFUND_REQUIRED") {
      throw new HttpsError("failed-precondition", "या वेळेसाठी जागा भरल्या. आपली रक्कम परत केली जाईल.");
    }

    const now = FieldValue.serverTimestamp();
    const receiptRef = db().collection("receipts").doc();

    if (pay.purpose === "donation") {
      const input = pay.intent as DonationInput;
      const receiptNo = formatSequence("KJD-RCPT", await nextNumber(tx, "receipt"));
      const donationRef = db().collection("donations").doc();
      tx.set(db().doc("counters/receipt"), { value: Number(receiptNo.slice(-6)) }, { merge: true });
      tx.set(donationRef, {
        ...input, receiptNo, userId: pay.userId, status: "SUCCESS", paymentId, orderId, createdAt: now,
      });
      tx.set(receiptRef, {
        receiptNo, purpose: "donation", refId: donationRef.id, userId: pay.userId, name: input.name,
        mobile: input.mobile, description: input.category, amountPaise: input.amountPaise, status: "SUCCESS",
        paymentId, createdAt: now,
      });
      tx.update(paymentRef, {
        status: "SUCCESS", razorpayPaymentId: paymentId, refId: donationRef.id, receiptId: receiptRef.id,
        number: receiptNo, verifiedBy: source, updatedAt: now,
      });
      return { refId: donationRef.id, receiptId: receiptRef.id, number: receiptNo };
    }

    // Seva booking: re-check capacity inside the transaction.
    const input = pay.intent as BookingInput & { sevaName: string };
    const slotRef = db().doc(`seva_slot_counts/${slotDocId(input.sevaId, input.date, input.timeSlot)}`);
    const sevaSnap = await tx.get(db().doc(`sevas/${input.sevaId}`));
    const slotSnap = await tx.get(slotRef);
    const used = Number(slotSnap.data()?.count ?? 0);
    const capacity = Number((sevaSnap.data() as SevaDoc | undefined)?.capacityPerSlot ?? 0);
    if (used >= capacity) {
      tx.update(paymentRef, {
        status: "REFUND_REQUIRED", razorpayPaymentId: paymentId, failureReason: "SLOT_FULL", updatedAt: now,
      });
      return { refId: "", receiptId: "", number: "", refundRequired: true };
    }
    const bookingNo = formatSequence("KJD-SEVA", await nextNumber(tx, "seva_booking"));
    const receiptNo = formatSequence("KJD-RCPT", await nextNumber(tx, "receipt"));
    const bookingRef = db().collection("seva_bookings").doc();
    tx.set(db().doc("counters/seva_booking"), { value: Number(bookingNo.slice(-6)) }, { merge: true });
    tx.set(db().doc("counters/receipt"), { value: Number(receiptNo.slice(-6)) }, { merge: true });
    tx.set(slotRef, { count: used + 1, sevaId: input.sevaId, date: input.date, timeSlot: input.timeSlot }, { merge: true });
    tx.set(bookingRef, {
      bookingNo, userId: pay.userId, sevaId: input.sevaId, sevaName: input.sevaName, date: istMidnight(input.date),
      dateKey: input.date, timeSlot: input.timeSlot, devoteeName: input.devoteeName, mobile: input.mobile,
      gotra: input.gotra ?? null, sankalp: input.sankalp ?? null, amountPaise: pay.amountPaise, status: "BOOKED",
      paymentId, orderId, receiptNo, createdAt: now,
    });
    tx.set(receiptRef, {
      receiptNo, purpose: "seva", refId: bookingRef.id, userId: pay.userId, name: input.devoteeName,
      mobile: input.mobile, description: `${input.sevaName} – ${input.date}, ${input.timeSlot} (${bookingNo})`,
      amountPaise: pay.amountPaise, status: "SUCCESS", paymentId, createdAt: now,
    });
    tx.update(paymentRef, {
      status: "SUCCESS", razorpayPaymentId: paymentId, refId: bookingRef.id, receiptId: receiptRef.id,
      number: bookingNo, verifiedBy: source, updatedAt: now,
    });
    return { refId: bookingRef.id, receiptId: receiptRef.id, number: bookingNo };
  });

  if (result.refundRequired) {
    await refund(paymentId, orderId);
    throw new HttpsError("failed-precondition", "या वेळेसाठी जागा भरल्या. आपली रक्कम परत केली जाईल.");
  }
  if (result.number) await notifyPaymentSuccess(orderId);
  return result;
}

async function refund(paymentId: string, orderId: string): Promise<void> {
  try {
    await razorpay(`payments/${paymentId}/refund`, { speed: "normal", notes: { reason: "slot_full", orderId } });
    await db().doc(`payments/${orderId}`).update({ refundStatus: "INITIATED", updatedAt: FieldValue.serverTimestamp() });
  } catch (e) {
    logger.error("Refund failed – handle manually from Razorpay dashboard", { paymentId, orderId, e });
    await db().doc(`payments/${orderId}`).update({ refundStatus: "FAILED", updatedAt: FieldValue.serverTimestamp() });
  }
}

/** Confirmation push (sent by the notifications trigger). Only once per order. */
async function notifyPaymentSuccess(orderId: string): Promise<void> {
  const ref = db().doc(`payments/${orderId}`);
  const sent = await db().runTransaction(async (tx) => {
    const p = (await tx.get(ref)).data();
    if (!p || p.notified) return null;
    tx.update(ref, { notified: true });
    return p;
  });
  if (!sent) return;
  const seva = sent.purpose === "seva";
  await db().collection("notifications").add({
    title: seva ? "🪔 सेवा बुकिंग निश्चित" : "🙏 देणगी प्राप्त झाली",
    body: seva
      ? `बुकिंग क्रमांक ${sent.number}. आपला QR सेवा पास ॲपमध्ये उपलब्ध आहे.`
      : `पावती क्रमांक ${sent.number}. आपल्या देणगीबद्दल मनःपूर्वक धन्यवाद.`,
    type: seva ? "seva" : "donation",
    target: "user",
    targetId: sent.userId,
    route: seva ? `/pass/${sent.refId}` : `/receipt/${sent.receiptId}`,
    createdAt: FieldValue.serverTimestamp(),
    system: true,
  });
}

/** Step 2 → 3: verify the Checkout signature, then finalise. */
export const verifyPayment = onCall({ region: REGION, secrets: [RAZORPAY_KEY_SECRET] }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "कृपया लॉगिन करा");
  const { orderId, paymentId, signature } = (req.data ?? {}) as Record<string, string>;
  if (!orderId || !paymentId || !signature) throw new HttpsError("invalid-argument", "Missing payment details");
  if (!verifyCheckoutSignature(orderId, paymentId, signature, RAZORPAY_KEY_SECRET.value())) {
    logger.warn("Bad Razorpay signature", { uid, orderId });
    throw new HttpsError("permission-denied", "पेमेंट पडताळणी अयशस्वी");
  }
  const pay = await db().doc(`payments/${orderId}`).get();
  if (pay.data()?.userId !== uid) throw new HttpsError("permission-denied", "Order does not belong to you");
  return finalizePayment(orderId, paymentId, "checkout");
});

/**
 * Razorpay webhook (payment.captured / payment.failed). Reconciles payments
 * whose app-side verification never arrived (app killed, network loss).
 * Configure in Razorpay Dashboard → Webhooks with the RAZORPAY_WEBHOOK_SECRET.
 */
export const razorpayWebhook = onRequest(
  { region: REGION, secrets: [RAZORPAY_KEY_SECRET, RAZORPAY_WEBHOOK_SECRET] },
  async (req, res) => {
    const signature = req.header("x-razorpay-signature") ?? "";
    if (req.method !== "POST" || !verifyWebhookSignature(req.rawBody, signature, RAZORPAY_WEBHOOK_SECRET.value())) {
      res.status(400).send("invalid");
      return;
    }
    const event = req.body?.event as string | undefined;
    const payment = req.body?.payload?.payment?.entity as { id: string; order_id?: string; error_description?: string } | undefined;
    try {
      if (payment?.order_id) {
        const exists = (await db().doc(`payments/${payment.order_id}`).get()).exists;
        if (exists && (event === "payment.captured" || event === "order.paid")) {
          await finalizePayment(payment.order_id, payment.id, "webhook");
        } else if (exists && event === "payment.failed") {
          await db().runTransaction(async (tx) => {
            const ref = db().doc(`payments/${payment.order_id}`);
            const cur = (await tx.get(ref)).data();
            if (cur && cur.status === "CREATED") {
              tx.update(ref, { status: "FAILED", failureReason: payment.error_description ?? "failed", updatedAt: FieldValue.serverTimestamp() });
            }
          });
        }
      }
      res.status(200).send("ok");
    } catch (e) {
      // Slot-full refunds surface as HttpsError but are handled; ack them.
      if (e instanceof HttpsError && e.code === "failed-precondition") {
        res.status(200).send("handled");
        return;
      }
      logger.error("Webhook processing failed", e);
      res.status(500).send("error");
    }
  },
);
