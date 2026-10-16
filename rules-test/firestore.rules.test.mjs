import { readFileSync } from "node:fs";
import { after, before, beforeEach, test } from "node:test";

import { assertFails, assertSucceeds, initializeTestEnvironment } from "@firebase/rules-unit-testing";
import { addDoc, collection, deleteDoc, doc, getDoc, getDocs, query, serverTimestamp, setDoc, updateDoc, where } from "firebase/firestore";

let env;
const devotee = () => env.authenticatedContext("u1", { phone_number: "+919876543210" }).firestore();
const other = () => env.authenticatedContext("u2", { phone_number: "+919000000000" }).firestore();
const guest = () => env.unauthenticatedContext().firestore();
const admin = (role, uid = `admin-${role}`) => env.authenticatedContext(uid, { role, email: `${role}@x.org` }).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-kjd",
    firestore: { rules: readFileSync(new URL("../firestore.rules", import.meta.url), "utf8") },
  });
});
after(() => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "events/pub"), { title: "Navratri", status: "published" });
    await setDoc(doc(db, "events/draft"), { title: "Secret", status: "draft" });
    await setDoc(doc(db, "donations/d1"), { userId: "u1", amountPaise: 50100 });
    await setDoc(doc(db, "receipts/r1"), { userId: "u1", amountPaise: 50100 });
    await setDoc(doc(db, "seva_bookings/b1"), { userId: "u1", status: "BOOKED" });
    await setDoc(doc(db, "notifications/all1"), { target: "all", title: "t", sentAt: new Date() });
    await setDoc(doc(db, "notifications/u2only"), { target: "user", targetId: "u2", title: "t" });
  });
});

test("guests read public content but not drafts", async () => {
  await assertSucceeds(getDoc(doc(guest(), "events/pub")));
  await assertFails(getDoc(doc(guest(), "events/draft")));
  await assertSucceeds(getDocs(query(collection(guest(), "events"), where("status", "in", ["published", "completed"]))));
  await assertFails(getDocs(collection(guest(), "events")));
  await assertSucceeds(getDoc(doc(admin("event_manager"), "events/draft")));
});

test("content writes need the right module", async () => {
  await assertFails(setDoc(doc(devotee(), "events/x"), { title: "x", status: "published" }));
  await assertFails(setDoc(doc(admin("gallery_manager"), "events/x"), { title: "x" }));
  await assertSucceeds(setDoc(doc(admin("event_manager"), "events/x"), { title: "x", status: "draft" }));
  await assertSucceeds(setDoc(doc(admin("content_manager"), "daily_quotes/q"), { text: "x" }));
  await assertFails(setDoc(doc(admin("volunteer"), "daily_quotes/q"), { text: "x" }));
  await assertSucceeds(setDoc(doc(admin("temple_admin"), "app_settings/main"), { maintenanceMode: false }));
  await assertFails(setDoc(doc(admin("not_a_role"), "temple_info/main"), { name: "x" }));
});

test("money documents are never client-writable", async () => {
  for (const db of [devotee(), admin("super_admin")]) {
    await assertFails(setDoc(doc(db, "donations/new"), { userId: "u1", amountPaise: 1 }));
    await assertFails(setDoc(doc(db, "receipts/new"), { userId: "u1" }));
    await assertFails(setDoc(doc(db, "payments/new"), { userId: "u1" }));
    await assertFails(updateDoc(doc(db, "seva_bookings/b1"), { status: "CHECK-IN" }));
    await assertFails(setDoc(doc(db, "counters/receipt"), { value: 0 }));
  }
});

test("devotees read only their own money documents", async () => {
  await assertSucceeds(getDoc(doc(devotee(), "donations/d1")));
  await assertFails(getDoc(doc(other(), "donations/d1")));
  await assertSucceeds(getDocs(query(collection(devotee(), "receipts"), where("userId", "==", "u1"))));
  await assertFails(getDocs(collection(devotee(), "receipts")));
  await assertSucceeds(getDoc(doc(admin("accounts_manager"), "donations/d1")));
  await assertFails(getDoc(doc(admin("gallery_manager"), "donations/d1")));
  await assertSucceeds(getDoc(doc(admin("volunteer"), "seva_bookings/b1")));
});

test("profile is self-only and cannot carry extra fields", async () => {
  await assertSucceeds(setDoc(doc(devotee(), "users/u1"), { name: "राम", mobile: "+919876543210", language: "mr" }));
  await assertFails(setDoc(doc(devotee(), "users/u1"), { name: "राम", mobile: "+919876543210", role: "super_admin" }));
  await assertFails(setDoc(doc(devotee(), "users/u1"), { name: "राम", mobile: "+911111111111" }));
  await assertFails(setDoc(doc(other(), "users/u1"), { name: "x", mobile: "+919000000000" }));
  await assertFails(getDoc(doc(other(), "users/u1")));
  await assertSucceeds(getDoc(doc(admin("seva_manager"), "users/u1")));
  await assertFails(getDoc(doc(admin("event_manager"), "users/u1")));
  await assertFails(getDoc(doc(admin("content_manager"), "users/u1")));
});

test("a devotee can watch their own not-yet-created reminder", async () => {
  // The app's "Remind me" button watches event_reminders/{uid}_{eventId}
  // before the document exists.
  await assertSucceeds(getDoc(doc(devotee(), "event_reminders/u1_pub")));
  await assertFails(getDoc(doc(devotee(), "event_reminders/u2_pub")));
  await assertFails(getDoc(doc(guest(), "event_reminders/u1_pub")));
});

test("reminders and family are owner-scoped", async () => {
  await assertSucceeds(setDoc(doc(devotee(), "event_reminders/u1_pub"), { userId: "u1", eventId: "pub" }));
  await assertFails(setDoc(doc(devotee(), "event_reminders/u2_pub"), { userId: "u2", eventId: "pub" }));
  await assertFails(setDoc(doc(devotee(), "event_reminders/u1_pub"), { userId: "u1", eventId: "other" }));
  const ref = await assertSucceeds(addDoc(collection(devotee(), "family_members"), { userId: "u1", name: "सीता" }));
  await assertFails(getDoc(doc(other(), `family_members/${ref.id}`)));
  await assertFails(updateDoc(doc(devotee(), `family_members/${ref.id}`), { userId: "u2" }));
  await assertSucceeds(deleteDoc(doc(devotee(), `family_members/${ref.id}`)));
});

test("notifications visibility and creation", async () => {
  await assertSucceeds(getDocs(query(collection(guest(), "notifications"), where("target", "==", "all"))));
  await assertFails(getDoc(doc(devotee(), "notifications/u2only")));
  await assertSucceeds(getDoc(doc(other(), "notifications/u2only")));
  await assertFails(addDoc(collection(devotee(), "notifications"), { title: "spam", target: "all" }));
  await assertSucceeds(addDoc(collection(admin("event_manager"), "notifications"), { title: "x", target: "all" }));
  await assertFails(addDoc(collection(admin("event_manager"), "notifications"), { title: "x", target: "all", sentAt: new Date() }));
  await assertFails(updateDoc(doc(admin("super_admin"), "notifications/all1"), { title: "rewrite history" }));
});

test("mantras and public greetings", async () => {
  await assertSucceeds(getDoc(doc(guest(), "mantras/m1")));
  await assertSucceeds(setDoc(doc(admin("content_manager"), "mantras/m1"), { text: "ॐ" }));
  await assertFails(setDoc(doc(admin("event_manager"), "mantras/m1"), { text: "ॐ" }));
  await assertSucceeds(getDoc(doc(guest(), "public_greetings/2026-10-06")));
  // Only the dailyJobs function may publish names.
  await assertFails(setDoc(doc(devotee(), "public_greetings/2026-10-06"), { entries: [] }));
  await assertFails(setDoc(doc(admin("super_admin"), "public_greetings/2026-10-06"), { entries: [] }));
});

test("audit logs are append-only and attributed", async () => {
  const db = admin("content_manager");
  await assertSucceeds(addDoc(collection(db, "audit_logs"), { actorId: "admin-content_manager", action: "update" }));
  await assertFails(addDoc(collection(db, "audit_logs"), { actorId: "someone-else", action: "update" }));
  await assertFails(addDoc(collection(devotee(), "audit_logs"), { actorId: "u1", action: "x" }));
  await assertFails(getDocs(collection(db, "audit_logs")));
  await assertSucceeds(getDocs(collection(admin("temple_admin"), "audit_logs")));
});

test("admin_users are function-managed", async () => {
  await assertFails(setDoc(doc(admin("temple_admin"), "admin_users/x"), { role: "super_admin" }));
  await assertSucceeds(getDoc(doc(admin("volunteer"), "admin_users/admin-volunteer")));
  await assertSucceeds(getDocs(collection(admin("temple_admin"), "admin_users"))); // auditLogs module
  await assertFails(getDocs(collection(admin("seva_manager"), "admin_users")));
});

test("guru gyan: shishya requests and lessons need approval", async () => {
  const req = { name: "गणेश", mobile: "+919876543210", village: "रुंधाटी", status: "pending", requestedAt: new Date() };
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), "guru_gyan/l1"), { title: "कथा", body: "..." }));
  // Only for yourself, only as pending.
  await assertFails(setDoc(doc(devotee(), "shishyas/u2"), req));
  await assertFails(setDoc(doc(devotee(), "shishyas/u1"), { ...req, status: "approved" }));
  await assertSucceeds(setDoc(doc(devotee(), "shishyas/u1"), req));
  await assertFails(getDoc(doc(other(), "shishyas/u1")));
  // Waiting shishya: no lessons, cannot approve themselves.
  await assertFails(getDoc(doc(devotee(), "guru_gyan/l1")));
  await assertFails(getDoc(doc(devotee(), "granth_text/kk-s2-a08")));
  await assertFails(updateDoc(doc(devotee(), "shishyas/u1"), { status: "approved" }));
  await assertFails(getDocs(collection(guest(), "guru_gyan")));
  // Staff approve; then lessons open and progress can be saved.
  await assertFails(updateDoc(doc(admin("gallery_manager"), "shishyas/u1"), { status: "approved" }));
  await assertSucceeds(getDocs(collection(admin("seva_manager"), "shishyas")));
  await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), "shishyas/u1"), { status: "approved" }));
  await assertSucceeds(getDocs(collection(devotee(), "guru_gyan")));
  await assertSucceeds(getDoc(doc(devotee(), "granth/kathakalpataru")));
  await assertSucceeds(getDoc(doc(devotee(), "granth_text/kk-s2-a08")));
  await assertFails(getDoc(doc(other(), "granth_text/kk-s2-a08")));
  await assertFails(setDoc(doc(devotee(), "granth_text/kk-s2-a08"), { body: "x" }));
  await assertSucceeds(updateDoc(doc(devotee(), "shishyas/u1"), { completed: ["l1"] }));
  await assertFails(updateDoc(doc(devotee(), "shishyas/u1"), { completed: ["l1"], name: "x" }));
  await assertFails(setDoc(doc(devotee(), "guru_gyan/l2"), { title: "x" }));
  await assertSucceeds(setDoc(doc(admin("content_manager"), "guru_gyan/l2"), { title: "x", body: "y" }));
  // Blocked: lessons close again; a rejected shishya may ask again.
  await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), "shishyas/u1"), { status: "blocked" }));
  await assertFails(getDoc(doc(devotee(), "guru_gyan/l1")));
  await assertFails(updateDoc(doc(devotee(), "shishyas/u1"), { status: "pending" }));
  await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), "shishyas/u1"), { status: "rejected" }));
  await assertSucceeds(setDoc(doc(devotee(), "shishyas/u1"), { ...req, note: "पुन्हा" }, { merge: true }));
});

test("guru gyan: shishya reading activity is seen by gadhipatis only", async () => {
  const shishya = { name: "गणेश", mobile: "+919876543210", status: "approved" };
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), "shishyas/u1"), shishya);
    await setDoc(doc(ctx.firestore(), "shishyas/u2"), { ...shishya, name: "महाराज", mobile: "+919000000000" });
  });
  const visit = (uid = "u1") => ({
    uid, name: "गणेश", kind: "granth", itemId: "ms-a04", title: "मूळस्तंभ – अध्याय ४",
    startedAt: serverTimestamp(), lastAt: serverTimestamp(), seconds: 0,
  });
  // Approved shishya records their own visit, not someone else's.
  const ref = await assertSucceeds(addDoc(collection(devotee(), "shishya_activity"), visit()));
  await assertFails(addDoc(collection(devotee(), "shishya_activity"), visit("u2")));
  await assertFails(addDoc(collection(devotee(), "shishya_activity"), { ...visit(), seconds: 500 }));
  await assertFails(addDoc(collection(guest(), "shishya_activity"), visit()));
  // Only the time can change, only upwards, only by its owner.
  await assertSucceeds(updateDoc(doc(devotee(), ref.path), { seconds: 60, lastAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(devotee(), ref.path), { seconds: 30, lastAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(devotee(), ref.path), { seconds: 90, lastAt: serverTimestamp(), title: "x" }));
  await assertFails(updateDoc(doc(other(), ref.path), { seconds: 90, lastAt: serverTimestamp() }));
  // Shishyas cannot read the log, nor make themselves gadhipati.
  await assertFails(getDocs(collection(devotee(), "shishya_activity")));
  await assertFails(setDoc(doc(other(), "gadhipatis/u2"), { name: "महाराज" }));
  await assertFails(setDoc(doc(admin("temple_admin"), "gadhipatis/u2"), { name: "महाराज" }));
  // Super admin assigns a gadhipati, who then sees everyone's reading.
  await assertSucceeds(setDoc(doc(admin("super_admin"), "gadhipatis/u2"), { name: "महाराज" }));
  await assertSucceeds(getDoc(doc(other(), "gadhipatis/u2")));
  await assertSucceeds(getDocs(collection(other(), "shishya_activity")));
  await assertSucceeds(getDocs(collection(admin("seva_manager"), "shishya_activity")));
  await assertSucceeds(deleteDoc(doc(admin("super_admin"), "gadhipatis/u2")));
  await assertFails(getDocs(collection(other(), "shishya_activity")));
});
