import { addDays, istDateKey, normaliseIndianMobile } from "./util.js";

/** Mirrors AppSettings in kjd_core. */
export interface Settings {
  donationCategories: string[];
  minDonationRupees: number;
  maxDonationRupees: number;
  bookingWindowDays: number;
  /** Temple UPI ID; when set, devotees pay by UPI QR instead of Razorpay. */
  upiId?: string;
  upiPayeeName?: string;
}

export const DEFAULT_SETTINGS: Settings = {
  donationCategories: ["सामान्य देणगी", "मंदिर विकास", "अन्नदान", "उत्सव", "विशेष पूजा", "इतर"],
  minDonationRupees: 11,
  maxDonationRupees: 500000,
  bookingWindowDays: 60,
};

export interface SevaDoc {
  name: string;
  pricePaise: number;
  timeSlots: string[];
  capacityPerSlot: number;
  availableWeekdays?: number[];
  active?: boolean;
}

export interface DonationInput {
  category: string;
  amountPaise: number;
  name: string;
  mobile: string;
  email?: string;
  address?: string;
  pan?: string;
  note?: string;
}

export interface BookingInput {
  sevaId: string;
  date: string; // yyyy-MM-dd
  timeSlot: string; // HH:mm
  devoteeName: string;
  mobile: string;
  gotra?: string;
  sankalp?: string;
}

const str = (v: unknown, max = 200): string | undefined => {
  if (typeof v !== "string") return undefined;
  const t = v.trim();
  return t.length === 0 ? undefined : t.slice(0, max);
};

export type Result<T> = { ok: true; value: T } | { ok: false; error: string };

export function parseDonation(raw: Record<string, unknown>, s: Settings): Result<DonationInput> {
  const name = str(raw.name, 120);
  const mobile = normaliseIndianMobile(String(raw.mobile ?? ""));
  const category = str(raw.category, 60);
  const amountPaise = Number(raw.amountPaise);
  const pan = str(raw.pan, 10)?.toUpperCase();
  if (!name || name.length < 2) return { ok: false, error: "कृपया नाव भरा" };
  if (!mobile) return { ok: false, error: "कृपया योग्य मोबाईल नंबर भरा" };
  if (!category || !s.donationCategories.includes(category)) return { ok: false, error: "कृपया देणगी प्रकार निवडा" };
  if (!Number.isInteger(amountPaise)) return { ok: false, error: "अवैध रक्कम" };
  if (amountPaise < s.minDonationRupees * 100) return { ok: false, error: `किमान देणगी ₹${s.minDonationRupees}` };
  if (amountPaise > s.maxDonationRupees * 100) return { ok: false, error: `कमाल ऑनलाइन देणगी ₹${s.maxDonationRupees}` };
  if (pan && !/^[A-Z]{5}[0-9]{4}[A-Z]$/.test(pan)) return { ok: false, error: "PAN क्रमांक अवैध आहे" };
  return {
    ok: true,
    value: { name, mobile, category, amountPaise, pan, email: str(raw.email, 120), address: str(raw.address, 300), note: str(raw.note, 300) },
  };
}

/** ISO weekday (1 = Monday … 7 = Sunday) of a `yyyy-MM-dd` key. */
function isoWeekday(key: string): number {
  const d = new Date(`${key}T00:00:00Z`).getUTCDay();
  return d === 0 ? 7 : d;
}

/** Current IST wall-clock minutes since midnight. */
function istMinutesNow(now: Date): number {
  const parts = new Intl.DateTimeFormat("en-GB", { timeZone: "Asia/Kolkata", hour: "2-digit", minute: "2-digit", hourCycle: "h23" })
    .format(now)
    .split(":");
  return Number(parts[0]) * 60 + Number(parts[1]);
}

export function parseBooking(
  raw: Record<string, unknown>,
  seva: SevaDoc | undefined,
  s: Settings,
  alreadyBooked: number,
  now: Date = new Date(),
): Result<BookingInput> {
  if (!seva || seva.active === false) return { ok: false, error: "ही सेवा सध्या उपलब्ध नाही" };
  const devoteeName = str(raw.devoteeName, 120);
  const mobile = normaliseIndianMobile(String(raw.mobile ?? ""));
  const date = str(raw.date, 10);
  const timeSlot = str(raw.timeSlot, 5);
  if (!devoteeName || devoteeName.length < 2) return { ok: false, error: "कृपया भक्ताचे नाव भरा" };
  if (!mobile) return { ok: false, error: "कृपया योग्य मोबाईल नंबर भरा" };
  if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) return { ok: false, error: "कृपया तारीख निवडा" };
  const today = istDateKey(now);
  if (date < today) return { ok: false, error: "मागील तारीख निवडता येणार नाही" };
  if (date > addDays(today, s.bookingWindowDays)) {
    return { ok: false, error: `फक्त पुढील ${s.bookingWindowDays} दिवसांसाठी बुकिंग उपलब्ध आहे` };
  }
  const weekdays = seva.availableWeekdays?.length ? seva.availableWeekdays : [1, 2, 3, 4, 5, 6, 7];
  if (!weekdays.includes(isoWeekday(date))) return { ok: false, error: "या दिवशी ही सेवा उपलब्ध नाही" };
  if (!timeSlot || !seva.timeSlots.includes(timeSlot)) return { ok: false, error: "कृपया वेळ निवडा" };
  if (date === today) {
    const [h, m] = timeSlot.split(":").map(Number);
    if (h * 60 + (m || 0) <= istMinutesNow(now)) return { ok: false, error: "ही वेळ निघून गेली आहे" };
  }
  if (alreadyBooked >= seva.capacityPerSlot) return { ok: false, error: "या वेळेसाठी सर्व जागा भरल्या आहेत" };
  return {
    ok: true,
    value: {
      sevaId: String(raw.sevaId),
      date,
      timeSlot,
      devoteeName,
      mobile,
      gotra: str(raw.gotra, 80),
      sankalp: str(raw.sankalp, 300),
    },
  };
}

export function slotDocId(sevaId: string, date: string, slot: string): string {
  return `${sevaId}_${date}_${slot.replace(":", "")}`;
}
