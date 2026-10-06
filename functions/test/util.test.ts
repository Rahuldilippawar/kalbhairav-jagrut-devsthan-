import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import { test } from "node:test";

import { can } from "../src/rbac.js";
import { addDays, formatSequence, istDateKey, normaliseIndianMobile, verifyCheckoutSignature, verifyWebhookSignature } from "../src/util.js";
import { DEFAULT_SETTINGS, parseBooking, parseDonation, slotDocId } from "../src/validation.js";

test("razorpay checkout signature", () => {
  const secret = "test_secret";
  const sig = createHmac("sha256", secret).update("order_1|pay_1").digest("hex");
  assert.equal(verifyCheckoutSignature("order_1", "pay_1", sig, secret), true);
  assert.equal(verifyCheckoutSignature("order_1", "pay_2", sig, secret), false);
  assert.equal(verifyCheckoutSignature("order_1", "pay_1", "short", secret), false);
});

test("razorpay webhook signature", () => {
  const body = JSON.stringify({ event: "payment.captured" });
  const sig = createHmac("sha256", "wh").update(body).digest("hex");
  assert.equal(verifyWebhookSignature(body, sig, "wh"), true);
  assert.equal(verifyWebhookSignature(body + " ", sig, "wh"), false);
});

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
