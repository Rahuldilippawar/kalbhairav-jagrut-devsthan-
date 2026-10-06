# 🛕 Kalbhairav Jagrut Devsthan

**श्री काळभैरव जागृत देवस्थान, रुंधाटी** (ता. अमळनेर, जि. जळगाव)

*दर्शन • सेवा • उत्सव • भक्ती • संस्कृती*

This is the temple's digital system: an Android-first Flutter app for devotees, a web admin panel for temple staff, and a Firebase backend with Razorpay payments.

| Part | Path | Tech |
|---|---|---|
| Devotee app | [`app/`](app) | Flutter (Android first, iOS-ready), Riverpod, go_router, Marathi / Hindi / Gujarati / English |
| Admin panel (CMS) | [`admin/`](admin) | Flutter Web, hosted on Firebase Hosting |
| Shared core | [`packages/kjd_core/`](packages/kjd_core) | Models, data layer, business rules, RBAC, theme, logo |
| Backend | [`functions/`](functions), [`firestore.rules`](firestore.rules), [`storage.rules`](storage.rules) | Cloud Functions (TypeScript, `asia-south1`), Firestore, Storage, FCM |
| Rules tests | [`rules-test/`](rules-test) | Firestore emulator + `@firebase/rules-unit-testing` |

## Try it in 1 minute (demo mode)

You don't need a Firebase project to try it. If Firebase isn't configured, both apps start in **demo mode**: an in-memory database is seeded with sample festivals (Navratri, Payi Dindi with its day-wise route, Guru Purnima, past years for the archive), sevas, darshan timings, greetings and tithi.

```bash
# Devotee app (Android emulator/device)
cd app && flutter run                      # login with any mobile number, OTP 123456

# Admin panel
cd admin && flutter run -d chrome          # one-click demo login for every role
```

Demo payments succeed instantly and produce real receipts and QR passes. Nothing is saved to a server.

## Features

**Devotee app**: Splash and onboarding · Mobile OTP login (guests can browse) · Admin-driven Home with hero banners, quick actions, today's Subhechha (shareable), today's tithi (computed automatically when the temple hasn't published it), notices, upcoming festivals, darshan status and quote of the day, plus a prominent Donate card · Profile photo · Darshan and aarti timings with an open/closed indicator and closure notices · Live Darshan (YouTube) · Events by category, with a **year-wise archive** · Event detail pages with schedule, photos by album, videos, *Remind me*, directions and the live link · **Pavitra Payi Dindi** route (day, location, departure, mukkaam, instructions, contact) · Seva booking (date → slot with live capacity → devotee details → Razorpay) · **QR Seva Pass** · Donations (category, preset/custom amount, PAN) · **Digital receipt**, downloadable as PDF and shareable as an image · **Digital Banner Studio** (daily greeting, tithi, birthday, anniversary, festival, event, jayanti, announcement and special message, each with templates, your own photo and a live preview), shareable to WhatsApp, Status, Instagram, Facebook and Telegram, or saved · Birthday and anniversary greeting card with privacy setting · Gallery and viewer · Temple info, history, tradition, call/WhatsApp/directions · Search · Notifications · Profile, family, My Seva, My Donations/Receipts, My Events, My Banners, language setting.

**Admin panel**: The dashboard has the 8 KPI cards from the plan. Staff manage temple info, darshan, live darshan, home banners, categories, events and the archive (with schedules, the Dindi route and media albums), the seva catalogue, bookings (check-in, complete, cancel), **QR check-in counter** (USB or Bluetooth scanner, or typed booking no.), donations, payments, reports (daily, monthly or yearly; seva-wise; date-wise; payments; event participation; devotees) with **CSV/Excel export**, daily Subhechha, quote library, tithi/Panchang (with a 30-day auto-generator), announcements (publish, schedule, expire), banner templates, gallery, videos, devotee lookup, a notification composer (all users, one user, event followers or seva users, sent now or scheduled), admin users and roles, audit logs, app settings, and a one-click starter-content loader for a new project.

**Backend**:
- Payments: `createPaymentOrder` validates the request and sets the price on the server, then creates the Razorpay order. `verifyPayment` checks the HMAC signature and then finalises inside one **idempotent Firestore transaction**, which creates the donation or booking, the receipt, sequential numbers (`KJD-RCPT-000001`, `KJD-SEVA-000001`) and the slot count. `razorpayWebhook` reconciles payments where the app closed before verifying. If a slot fills during payment, the payment is refunded automatically.
- Notifications and scheduled jobs: notification fan-out over FCM, and a 15-minute scheduler for scheduled notifications. `dailyJobs` runs at 06:30 IST: it pushes the daily greeting, sends event reminders the day before and on the day, sends birthday and anniversary greetings (respecting privacy), and archives finished events.
- Admin access: roles are set with `setAdminRole` or `claimSuperAdmin` and stored as custom claims. `checkInBooking` and `cancelBooking` handle passes.

## Security model

- **No secret in the app.** The Razorpay key secret and webhook secret are Cloud Functions secrets. The app only receives the publishable key id with each order.
- **Money documents** (`payments`, `donations`, `receipts`, `seva_bookings`, `counters`, `seva_slot_counts`) are written **only** by Cloud Functions. The rules deny all client writes, and devotees can read only their own documents.
- **RBAC:** the role is a Firebase Auth custom claim. The same role → module map is in [`rbac.dart`](packages/kjd_core/lib/src/rbac.dart), [`rbac.ts`](functions/src/rbac.ts) and [`firestore.rules`](firestore.rules).

| Role | Modules |
|---|---|
| Super Admin | everything |
| Temple Admin | everything except admin users |
| Event Manager | events, gallery, live, notifications |
| Seva Manager | seva, bookings, check-in, devotees, reports |
| Accounts Manager | donations, payments, bookings, reports |
| Content Manager | temple, darshan, content, banners, live, notifications |
| Gallery Manager | gallery |
| Volunteer | check-in |

- Every admin write is written to `audit_logs` (who, action, record, when). The log is append-only and attributed to the signed-in admin by the rules.
- Devotee data is isolated per user: profile, family, reminders and banners are owner-only.

## Going live

See **[docs/SETUP.md](docs/SETUP.md)** for step-by-step instructions: Firebase project, `flutterfire configure`, Razorpay keys and webhook, deploying rules, indexes, functions and hosting, claiming the first Super Admin, and Android release builds.

## Tests

```bash
cd packages/kjd_core && flutter test     # models, validation, demo checkout, store
cd app && flutter test                   # end-to-end flows in demo mode
cd admin && flutter test                 # RBAC menu, CRUD + audit, QR check-in
cd functions && npm test                 # signatures, validation, RBAC
cd rules-test && npm test                # Firestore rules on the emulator (needs Java)
```

CI runs all of these on every pull request ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

## Data model

There is one Firestore collection per plan item: `users`, `family_members`, `events`, `event_categories`, `event_schedules`, `event_media`, `event_reminders`, `sevas`, `seva_bookings`, `seva_slot_counts`, `donations`, `payments`, `receipts`, `daily_quotes`, `daily_greetings`, `tithi_content`, `banner_templates`, `generated_banners`, `home_banners`, `announcements`, `notifications`, `gallery`, `videos`, `temple_info`, `darshan_schedule`, `live_darshan`, `admin_users`, `audit_logs`, `app_settings` and `counters`. Fields are documented in the model classes in [`packages/kjd_core/lib/src/models`](packages/kjd_core/lib/src/models).

## Known gaps / next steps

- **Panchang accuracy:** tithi, nakshatra, yoga, karana, masa (incl. adhik) and sunrise/sunset are computed for Rundhati at sunrise and checked against published dates, but festivals fixed by a tithi at another time of day (pradosh, midnight) can differ by a day. Staff can correct any day; corrected days are never overwritten.
- **Camera QR scanning in the admin panel:** check-in uses a hardware scanner or typing. A phone-camera scanner could be added to the app later for volunteers.
- **In-app Dindi route map:** the route is shown as day-wise stops plus a Google Maps link.
- **Admin pagination:** lists load whole collections, which is fine for a temple's volume. Add pagination if a collection grows past a few thousand documents.
- **Release:** signing is configured (see setup guide); the Play Store listing and an iOS build still need to be done with the temple's developer accounts.
