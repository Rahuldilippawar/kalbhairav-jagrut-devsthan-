import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging, type MulticastMessage } from "firebase-admin/messaging";
import { logger } from "firebase-functions";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { addDays, chunk, istDateKey, istMonthDay } from "./util.js";

const REGION = "asia-south1";
const TZ = "Asia/Kolkata";
const db = () => getFirestore();

interface NotificationDoc {
  title: string;
  body: string;
  type?: string;
  target?: "all" | "user" | "eventFollowers" | "sevaUsers";
  targetId?: string;
  imageUrl?: string;
  route?: string;
  scheduledAt?: Timestamp;
  sentAt?: Timestamp;
}

async function tokensForUsers(uids: string[]): Promise<string[]> {
  const unique = [...new Set(uids)];
  const tokens: string[] = [];
  for (const group of chunk(unique, 30)) {
    // Respect each devotee's notification preference.
    const users = await db().getAll(...group.map((u) => db().doc(`users/${u}`)));
    const enabled = users.filter((u) => u.exists && u.data()?.notificationsEnabled !== false).map((u) => u.id);
    for (const uid of enabled) {
      const t = await db().collection(`users/${uid}/tokens`).get();
      tokens.push(...t.docs.map((d) => d.id));
    }
  }
  return tokens;
}

async function recipients(n: NotificationDoc): Promise<string[] | "topic"> {
  switch (n.target ?? "all") {
    case "all":
      return "topic";
    case "user":
      return n.targetId ? tokensForUsers([n.targetId]) : [];
    case "eventFollowers": {
      const r = await db().collection("event_reminders").where("eventId", "==", n.targetId ?? "").get();
      return tokensForUsers(r.docs.map((d) => d.data().userId as string));
    }
    case "sevaUsers": {
      let q = db().collection("seva_bookings").where("status", "==", "BOOKED");
      if (n.targetId) q = q.where("sevaId", "==", n.targetId);
      const r = await q.get();
      return tokensForUsers(r.docs.map((d) => d.data().userId as string));
    }
  }
}

/** Sends one notification document over FCM and stamps sentAt/sentCount. */
export async function deliver(id: string, n: NotificationDoc): Promise<void> {
  const ref = db().doc(`notifications/${id}`);
  const claimed = await db().runTransaction(async (tx) => {
    const cur = (await tx.get(ref)).data();
    if (!cur || cur.sentAt || cur.sending) return false;
    tx.update(ref, { sending: true });
    return true;
  });
  if (!claimed) return;

  const notification = { title: n.title, body: n.body, ...(n.imageUrl ? { imageUrl: n.imageUrl } : {}) };
  const data = { type: n.type ?? "announcement", route: n.route ?? "", id };
  const android = { priority: "high" as const, notification: { color: "#B71C1C" } };
  let sent = 0;
  try {
    const to = await recipients(n);
    if (to === "topic") {
      await getMessaging().send({ topic: "all", notification, data, android });
      sent = -1; // topic: unknown audience size
    } else {
      for (const tokens of chunk(to, 500)) {
        const msg: MulticastMessage = { tokens, notification, data, android };
        const res = await getMessaging().sendEachForMulticast(msg);
        sent += res.successCount;
        // Drop tokens that are no longer registered.
        await Promise.all(
          res.responses.map(async (r, i) => {
            if (!r.success && r.error?.code === "messaging/registration-token-not-registered") {
              const stale = await db().collectionGroup("tokens").where("token", "==", tokens[i]).get();
              await Promise.all(stale.docs.map((d) => d.ref.delete()));
            }
          }),
        );
      }
    }
    await ref.update({ sentAt: FieldValue.serverTimestamp(), sentCount: sent, sending: FieldValue.delete() });
  } catch (e) {
    logger.error("Notification delivery failed", { id, e });
    await ref.update({ sending: FieldValue.delete(), error: String(e) });
  }
}

/** Admin (or a system job) creates a notification → deliver now unless scheduled. */
export const onNotificationCreated = onDocumentCreated({ document: "notifications/{id}", region: REGION }, async (event) => {
  const n = event.data?.data() as NotificationDoc | undefined;
  if (!n) return;
  if (n.scheduledAt && n.scheduledAt.toMillis() > Date.now()) return;
  await deliver(event.params.id, n);
});

/** Sends scheduled notifications that are now due. */
export const sendScheduledNotifications = onSchedule({ schedule: "every 15 minutes", timeZone: TZ, region: REGION }, async () => {
  const due = await db().collection("notifications").where("scheduledAt", "<=", Timestamp.now()).get();
  await Promise.all(due.docs.filter((d) => !d.data().sentAt).map((d) => deliver(d.id, d.data() as NotificationDoc)));
});

/**
 * 06:30 IST daily:
 *  - push today's published Subhechha,
 *  - event reminders (1 day before and on the event day) to followers,
 *  - birthday / anniversary greetings (respecting privacy),
 *  - mark finished events as completed so they move to the archive.
 */
export const dailyJobs = onSchedule({ schedule: "30 6 * * *", timeZone: TZ, region: REGION }, async () => {
  const today = istDateKey();
  const tomorrow = addDays(today, 1);
  const notifications = db().collection("notifications");
  const now = FieldValue.serverTimestamp();

  // Daily greeting.
  const greetings = await db().collection("daily_greetings").where("date", "==", today).where("status", "==", "published").limit(1).get();
  if (!greetings.empty) {
    const g = greetings.docs[0].data();
    await notifications.doc(`greeting-${today}`).create({
      title: g.title, body: g.message, type: "greeting", target: "all", route: "/greetings", imageUrl: g.imageUrl ?? null, createdAt: now, system: true,
    }).catch(() => undefined); // already sent today
  }

  // Event reminders.
  const istStart = (key: string) => Timestamp.fromDate(new Date(`${key}T00:00:00+05:30`));
  const events = await db().collection("events")
    .where("startDate", ">=", istStart(today))
    .where("startDate", "<", istStart(addDays(tomorrow, 1)))
    .get();
  for (const e of events.docs) {
    const ev = e.data();
    if (ev.status !== "published") continue;
    const startKey = istDateKey((ev.startDate as Timestamp).toDate());
    const isToday = startKey === today;
    await notifications.doc(`reminder-${e.id}-${startKey}-${isToday ? "day" : "eve"}`).create({
      title: isToday ? `🎉 आज: ${ev.title}` : `🔔 उद्या: ${ev.title}`,
      body: isToday ? "आज उत्सवाचा दिवस. सहकुटुंब दर्शनाचा लाभ घ्या." : "उद्या उत्सव सुरू होत आहे. आपण आठवण सेट केली होती.",
      type: "event", target: "eventFollowers", targetId: e.id, route: `/event/${e.id}`, createdAt: now, system: true,
    }).catch(() => undefined);
  }

  // Birthdays & anniversaries.
  const md = istMonthDay();
  const publicEntries: { name: string; village: string | null; kind: string }[] = [];
  for (const [field, title, body] of [
    ["dobMonthDay", "🎂 वाढदिवसाच्या हार्दिक शुभेच्छा", "श्री काळभैरव महाराजांची कृपा सदैव राहो. आपला शुभेच्छा बॅनर तयार आहे."],
    ["anniversaryMonthDay", "💍 विवाह वर्धापन दिनाच्या हार्दिक शुभेच्छा", "आपले सहजीवन सुखाचे व आनंदाचे जावो."],
  ] as const) {
    const users = await db().collection("users").where(field, "==", md).get();
    for (const u of users.docs) {
      const p = u.data();
      if (p.birthdayPrivacy === "private") continue;
      const category = field === "dobMonthDay" ? "birthday" : "anniversary";
      if (p.birthdayPrivacy === "public" && p.name) {
        const name = category === "anniversary" && p.spouseName ? `${p.name} व ${p.spouseName}` : p.name;
        publicEntries.push({ name, village: p.village ?? null, kind: category });
      }
      await notifications.doc(`${category}-${u.id}-${today}`).create({
        title: p.name ? `${title}, ${p.name}` : title,
        body,
        type: "greeting", target: "user", targetId: u.id,
        route: `/banner?category=${category}&name=${encodeURIComponent(p.name ?? "")}`,
        createdAt: now, system: true,
      }).catch(() => undefined);
    }
  }

  // Only names/villages of devotees who opted into "Public" are published.
  await db().doc(`public_greetings/${today}`).set({ entries: publicEntries, updatedAt: now });

  // Archive finished events.
  const finished = await db().collection("events").where("status", "==", "published").get();
  const batch = db().batch();
  let changed = 0;
  for (const e of finished.docs) {
    const end = (e.data().endDate ?? e.data().startDate) as Timestamp | undefined;
    if (end && istDateKey(end.toDate()) < today) {
      batch.update(e.ref, { status: "completed", updatedAt: now });
      changed++;
    }
  }
  if (changed) await batch.commit();
  logger.info("dailyJobs done", { today, events: events.size, archived: changed });
});
