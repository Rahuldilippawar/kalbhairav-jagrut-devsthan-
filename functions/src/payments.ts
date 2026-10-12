import { getFirestore, FieldValue, Timestamp, type Transaction } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

import { formatSequence } from "./util.js";
import {
  DEFAULT_SETTINGS, parseBooking, parseDonation, slotDocId,
  type BookingInput, type DonationInput, type SevaDoc, type Settings,
} from "./validation.js";

const db = () => getFirestore();

export async function loadSettings(): Promise<Settings> {
  const snap = await db().doc("app_settings/main").get();
  return { ...DEFAULT_SETTINGS, ...(snap.data() ?? {}) } as Settings;
}

type Intent =
  | { purpose: "donation"; input: DonationInput }
  | { purpose: "seva"; input: BookingInput; seva: SevaDoc };

/** Validates a donation/seva request and prices it server-side. */
export async function resolveIntent(raw: Record<string, unknown>, settings: Settings): Promise<{ intent: Intent; amountPaise: number }> {
  if (raw.purpose === "donation") {
    const r = parseDonation(raw, settings);
    if (!r.ok) throw new HttpsError("invalid-argument", r.error);
    return { intent: { purpose: "donation", input: r.value }, amountPaise: r.value.amountPaise };
  }
  if (raw.purpose === "seva") {
    const sevaSnap = await db().doc(`sevas/${String(raw.sevaId ?? "")}`).get();
    const seva = sevaSnap.data() as SevaDoc | undefined;
    const slot = await db()
      .doc(`seva_slot_counts/${slotDocId(sevaSnap.id, String(raw.date ?? ""), String(raw.timeSlot ?? ""))}`)
      .get();
    const r = parseBooking(raw, seva, settings, Number(slot.data()?.count ?? 0));
    if (!r.ok) throw new HttpsError("invalid-argument", r.error);
    // Never trust a client-side price.
    return { intent: { purpose: "seva", input: r.value, seva: seva! }, amountPaise: seva!.pricePaise };
  }
  throw new HttpsError("invalid-argument", "Unknown purpose");
}

/** What is stored in `payments.intent`. */
export const storedIntent = (intent: Intent) =>
  intent.purpose === "seva" ? { ...intent.input, sevaName: intent.seva.name } : intent.input;

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
 * Idempotently turns a verified payment (UPI approved by the office) into
 * donation/booking + receipt documents.
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
    if (pay.status === "REJECTED") throw new HttpsError("failed-precondition", "हे पेमेंट नाकारले गेले आहे");
    if (pay.status === "REFUND_REQUIRED") {
      throw new HttpsError("failed-precondition", "या वेळेसाठी जागा भरल्या. आपली रक्कम परत केली जाईल.");
    }

    const now = FieldValue.serverTimestamp();
    const receiptRef = db().collection("receipts").doc();

    if (pay.purpose === "donation") {
      const input = pay.intent as DonationInput;
      const receiptSeq = await nextNumber(tx, "receipt");
      const receiptNo = formatSequence("KJD-RCPT", receiptSeq);
      const donationRef = db().collection("donations").doc();
      tx.set(db().doc("counters/receipt"), { value: receiptSeq }, { merge: true });
      tx.set(donationRef, {
        ...input, receiptNo, userId: pay.userId, status: "SUCCESS", paymentId, orderId, createdAt: now,
      });
      tx.set(receiptRef, {
        receiptNo, purpose: "donation", refId: donationRef.id, userId: pay.userId, name: input.name,
        mobile: input.mobile, description: input.category, amountPaise: input.amountPaise, status: "SUCCESS",
        paymentId, createdAt: now,
      });
      tx.update(paymentRef, {
        status: "SUCCESS", paymentRef: paymentId, refId: donationRef.id, receiptId: receiptRef.id,
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
    // A UPI payment reserved its place when the devotee submitted the UTR.
    const held = pay.slotHeld === true;
    if (!held && used >= capacity) {
      tx.update(paymentRef, {
        status: "REFUND_REQUIRED", paymentRef: paymentId, failureReason: "SLOT_FULL", updatedAt: now,
      });
      return { refId: "", receiptId: "", number: "", refundRequired: true };
    }
    const bookingSeq = await nextNumber(tx, "seva_booking");
    const receiptSeq = await nextNumber(tx, "receipt");
    const bookingNo = formatSequence("KJD-SEVA", bookingSeq);
    const receiptNo = formatSequence("KJD-RCPT", receiptSeq);
    const bookingRef = db().collection("seva_bookings").doc();
    tx.set(db().doc("counters/seva_booking"), { value: bookingSeq }, { merge: true });
    tx.set(db().doc("counters/receipt"), { value: receiptSeq }, { merge: true });
    if (!held) tx.set(slotRef, { count: used + 1, sevaId: input.sevaId, date: input.date, timeSlot: input.timeSlot }, { merge: true });
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
      status: "SUCCESS", paymentRef: paymentId, refId: bookingRef.id, receiptId: receiptRef.id,
      number: bookingNo, verifiedBy: source, updatedAt: now,
    });
    return { refId: bookingRef.id, receiptId: receiptRef.id, number: bookingNo };
  });

  if (result.refundRequired) {
    throw new HttpsError("failed-precondition", "या वेळेसाठी जागा भरल्या. रक्कम परत करण्यासाठी भाविकाशी संपर्क साधा.");
  }
  if (result.number) await notifyPaymentSuccess(orderId);
  return result;
}

/** Confirmation push (sent by the notifications trigger). Only once per order. */
export async function notifyPaymentSuccess(orderId: string): Promise<void> {
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
