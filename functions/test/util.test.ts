import assert from "node:assert/strict";
import { test } from "node:test";

import { can } from "../src/rbac.js";
import { addDays, formatSequence, istDateKey, normaliseIndianMobile } from "../src/util.js";
import { DEFAULT_SETTINGS, parseBooking, parseDonation, slotDocId } from "../src/validation.js";

test("helpers", () => {
  assert.equal(formatSequence("KJD-SEVA", 42), "KJD-SEVA-000042");
  assert.equal(normaliseIndianMobile("098765 43210"), "+919876543210");
  assert.equal(normaliseIndianMobile("12345"), null);
  assert.equal(addDays("2026-12-31", 1), "2027-01-01");
  // 2026-10-05T20:00Z is already 6 Oct in IST.
  assert.equal(istDateKey(new Date("2026-10-05T20:00:00Z")), "2026-10-06");
  assert.equal(slotDocId("abhishek", "2026-10-07", "06:30"), "abhishek_2026-10-07_0630");
});

test("rbac", () => {
  assert.equal(can("super_admin", "users"), true);
  assert.equal(can("temple_admin", "users"), false);
  assert.equal(can("volunteer", "checkIn"), true);
  assert.equal(can("volunteer", "donations"), false);
  assert.equal(can("hacker", "dashboard"), false);
});

test("donation validation", () => {
  const ok = parseDonation({ category: "अन्नदान", amountPaise: 50100, name: "राम", mobile: "9876543210" }, DEFAULT_SETTINGS);
  assert.equal(ok.ok, true);
  assert.equal(parseDonation({ category: "अन्नदान", amountPaise: 100, name: "राम", mobile: "9876543210" }, DEFAULT_SETTINGS).ok, false);
  assert.equal(parseDonation({ category: "x", amountPaise: 50100, name: "राम", mobile: "9876543210" }, DEFAULT_SETTINGS).ok, false);
  assert.equal(parseDonation({ category: "अन्नदान", amountPaise: 501.5, name: "राम", mobile: "9876543210" }, DEFAULT_SETTINGS).ok, false);
});

test("booking validation", () => {
  const seva = { name: "अभिषेक", pricePaise: 50100, timeSlots: ["07:00", "10:00"], capacityPerSlot: 2, availableWeekdays: [1, 2, 3, 4, 5, 6] };
  const now = new Date("2026-10-06T04:00:00Z"); // 09:30 IST, Tuesday
  const req = (date: string, timeSlot: string) => ({ sevaId: "s", date, timeSlot, devoteeName: "राम", mobile: "9876543210" });
  assert.equal(parseBooking(req("2026-10-06", "10:00"), seva, DEFAULT_SETTINGS, 0, now).ok, true);
  assert.equal(parseBooking(req("2026-10-06", "07:00"), seva, DEFAULT_SETTINGS, 0, now).ok, false); // passed
  assert.equal(parseBooking(req("2026-10-11", "10:00"), seva, DEFAULT_SETTINGS, 0, now).ok, false); // Sunday
  assert.equal(parseBooking(req("2026-10-05", "10:00"), seva, DEFAULT_SETTINGS, 0, now).ok, false); // past
  assert.equal(parseBooking(req("2026-10-07", "10:00"), seva, DEFAULT_SETTINGS, 2, now).ok, false); // full
  assert.equal(parseBooking(req("2026-10-07", "10:00"), undefined, DEFAULT_SETTINGS, 0, now).ok, false);
});

test("upi helpers", async () => {
  const { isValidUpiId, normaliseUtr, upiReference } = await import("../src/util.js");
  assert.equal(normaliseUtr("4123 4567 8901"), "412345678901");
  assert.equal(normaliseUtr("41234567890"), null);
  assert.equal(normaliseUtr("ABC345678901"), null);
  assert.equal(upiReference("aB3-dE5fGh9Z"), "KJDAB3DE5FG");
  assert.equal(isValidUpiId("kalbhairav.devsthan@sbi"), true);
  assert.equal(isValidUpiId("9876543210@ybl"), true);
  assert.equal(isValidUpiId("no-at-sign"), false);
  assert.equal(isValidUpiId(undefined), false);
});

test("daily suvichar matches the app's pick", async () => {
  const { pickQuoteForDay } = await import("../src/util.js");
  const q = (id: string, extra: Record<string, unknown> = {}) => ({ id, text: id, status: "published", ...extra });
  const quotes = [q("b"), q("a"), q("c", { scheduledDate: "2026-10-12" }), q("d", { status: "draft" })];
  assert.equal(pickQuoteForDay(quotes, "2026-10-12")?.id, "c");
  // Unscheduled pool sorted by id = [a, b]; day 20736 (2026-10-10) is even → "a", 20737 → "b".
  assert.equal(pickQuoteForDay(quotes, "2026-10-10")?.id, "a");
  assert.equal(pickQuoteForDay(quotes, "2026-10-11")?.id, "b");
  assert.equal(pickQuoteForDay([], "2026-10-12"), null);
});

test("mergeQuoteLibrary: Firestore docs override built-ins by id", async () => {
  const { mergeQuoteLibrary } = await import("../src/util.js");
  const { SUVICHAR_LIBRARY } = await import("../src/suvichar_library.js");
  assert.ok(SUVICHAR_LIBRARY.length >= 100);
  const merged = mergeQuoteLibrary(
    [{ id: "sv001", text: "x", status: "draft" }, { id: "own", text: "y", status: "published" }],
    SUVICHAR_LIBRARY,
  );
  assert.equal(merged.length, SUVICHAR_LIBRARY.length + 1);
  assert.equal(merged.find((q) => q.id === "sv001")?.status, "draft");
});

test("shishyaReviewMessage names the shishya and the reason", async () => {
  const { shishyaReviewMessage } = await import("../src/util.js");
  assert.match(shishyaReviewMessage("approved", "गणेश", "").body, /^गणेश, .*मान्य/);
  assert.match(shishyaReviewMessage("rejected", "", "माहिती अपूर्ण").body, /कारण: माहिती अपूर्ण/);
  assert.doesNotMatch(shishyaReviewMessage("blocked", "", "").body, /कारण/);
});
