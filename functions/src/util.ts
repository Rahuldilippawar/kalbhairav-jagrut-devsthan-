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

export interface QuoteDoc {
  id: string;
  text: string;
  author?: string | null;
  status?: string;
  scheduledDate?: string | null;
}

/** Firestore quotes plus built-in ones whose id is not taken; mirrors ContentRepository.watchQuotes. */
export function mergeQuoteLibrary(own: QuoteDoc[], library: QuoteDoc[]): QuoteDoc[] {
  const ids = new Set(own.map((q) => q.id));
  return [...own, ...library.filter((q) => !ids.has(q.id))];
}

/** Today's suvichar; mirrors DailyQuote.pickForDay in kjd_core. */
export function pickQuoteForDay(quotes: QuoteDoc[], dayKey: string): QuoteDoc | null {
  const published = quotes.filter((q) => q.status === "published").sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
  if (published.length === 0) return null;
  const scheduled = published.find((q) => q.scheduledDate === dayKey);
  if (scheduled) return scheduled;
  const unscheduled = published.filter((q) => !q.scheduledDate);
  const pool = unscheduled.length ? unscheduled : published;
  const dayNumber = Math.floor(Date.parse(`${dayKey}T00:00:00Z`) / 86400000);
  return pool[dayNumber % pool.length];
}
