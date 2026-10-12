import { createHmac, timingSafeEqual } from "node:crypto";

/** `yyyy-MM-dd` in India Standard Time. */
export function istDateKey(d: Date = new Date()): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Kolkata" }).format(d);
}

/** `MM-dd` in IST, matching DevoteeProfile.dobMonthDay. */
export function istMonthDay(d: Date = new Date()): string {
  return istDateKey(d).slice(5);
}

export function addDays(key: string, days: number): string {
  const d = new Date(`${key}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

export function formatSequence(prefix: string, n: number): string {
  return `${prefix}-${String(n).padStart(6, "0")}`;
}

export function hmacSha256Hex(secret: string, payload: string): string {
  return createHmac("sha256", secret).update(payload).digest("hex");
}

/** Constant-time comparison of two hex signatures. */
export function safeEqualHex(a: string, b: string): boolean {
  const ba = Buffer.from(a, "utf8");
  const bb = Buffer.from(b, "utf8");
  return ba.length === bb.length && timingSafeEqual(ba, bb);
}

/** Razorpay Checkout signature: HMAC_SHA256(order_id + "|" + payment_id, key_secret). */
export function verifyCheckoutSignature(orderId: string, paymentId: string, signature: string, secret: string): boolean {
  return safeEqualHex(hmacSha256Hex(secret, `${orderId}|${paymentId}`), signature);
}

/** Razorpay webhook signature: HMAC_SHA256(raw_body, webhook_secret). */
export function verifyWebhookSignature(rawBody: string | Buffer, signature: string, secret: string): boolean {
  return safeEqualHex(createHmac("sha256", secret).update(rawBody).digest("hex"), signature);
}

export function normaliseIndianMobile(input: string): string | null {
  let digits = String(input ?? "").replace(/\D/g, "");
  if (digits.length === 12 && digits.startsWith("91")) digits = digits.slice(2);
  if (digits.length === 11 && digits.startsWith("0")) digits = digits.slice(1);
  if (digits.length !== 10 || !/^[6-9]/.test(digits)) return null;
  return `+91${digits}`;
}

export function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}

/** UPI transaction reference (UTR / "UPI Ref No."): 12 digits. */
export function normaliseUtr(raw: unknown): string | null {
  const utr = String(raw ?? "").replace(/\s+/g, "");
  return /^\d{12}$/.test(utr) ? utr : null;
}

/** Short reference printed in the UPI note so the office can match payments. */
export function upiReference(paymentId: string): string {
  return `KJD${paymentId.replace(/[^A-Za-z0-9]/g, "").slice(0, 8).toUpperCase()}`;
}

/** A VPA such as `name@bank`. */
export function isValidUpiId(v: unknown): v is string {
  return typeof v === "string" && /^[A-Za-z0-9._-]{2,256}@[A-Za-z][A-Za-z0-9.-]{1,64}$/.test(v.trim());
}
