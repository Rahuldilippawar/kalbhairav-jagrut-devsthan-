# Going live – setup guide

These steps take the project from demo mode to production. Commands are run from the repository root unless noted.

## 1. Tools

- Flutter (stable) – `flutter --version`
- Node.js 22 and the Firebase CLI – `npm i -g firebase-tools`
- FlutterFire CLI – `dart pub global activate flutterfire_cli`
- Java 21 (only for the rules emulator tests)

## 2. Firebase project

1. Create a project in the [Firebase console](https://console.firebase.google.com), on the **Blaze** plan. Cloud Functions and outbound calls to Razorpay need Blaze.
2. Enable these services:
   - **Authentication:** turn on the *Phone* provider (devotees) and the *Email/Password* provider (admins). For Phone auth on Android, add the app's SHA-1 and SHA-256 fingerprints in Project settings.
   - **Firestore** (production mode). Choose region `asia-south1` (Mumbai).
   - **Storage**
   - **Cloud Messaging**
3. Copy `.firebaserc.example` to `.firebaserc` and put in your project id.
4. Connect the apps:

   ```bash
   cd app   && flutterfire configure   # Android + iOS → writes lib/firebase_options.dart and google-services.json
   cd admin && flutterfire configure   # Web
   ```

   Once `firebase_options.dart` has real values, the apps leave demo mode. Pass `--dart-define=KJD_DEMO=true` to force demo mode again.

## 3. Razorpay

1. Create a Razorpay account. Use **Test mode** keys first.
2. Configure Functions:

   ```bash
   cp functions/.env.example functions/.env.<project-id>
   # edit RAZORPAY_KEY_ID and BOOTSTRAP_SUPER_ADMIN_EMAILS
   firebase functions:secrets:set RAZORPAY_KEY_SECRET
   firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET
   ```

3. After deploying (step 4), add a webhook in Razorpay Dashboard → Settings → Webhooks:
   - URL: `https://asia-south1-<project-id>.cloudfunctions.net/razorpayWebhook`
   - Events: `payment.captured`, `payment.failed`, `order.paid`
   - Secret: the same value as `RAZORPAY_WEBHOOK_SECRET`

## 4. Deploy

```bash
cd functions && npm ci && cd ..
cd admin && flutter build web --release && cd ..
firebase deploy --only firestore:rules,firestore:indexes,storage,functions,hosting
```

The admin panel is then served at `https://<project-id>.web.app`.

## 5. First Super Admin

1. In Firebase console → Authentication, add an Email/Password user for the temple owner. The email must be listed in `BOOTSTRAP_SUPER_ADMIN_EMAILS`.
2. Sign in to the admin panel. The panel says the account has no role; click **Claim Super Admin**. This works only while no super admin exists.
3. On the Dashboard, click **Load starter content**. This adds event categories, settings, darshan timings, sample sevas, banner templates, quotes and temple info. Then edit Temple Info (phone, WhatsApp, coordinates, history) and the seva prices.
4. Add other staff under **Admin Users & Roles**. If a staff member has no account yet, the panel gives you a password-setup link to send them.

## 6. Android release

1. Create an upload keystore and `app/android/key.properties` (both are git-ignored), then add a `release` signing config in `app/android/app/build.gradle.kts`.
2. `cd app && flutter build appbundle --release`
3. Play Console checklist:
   - Privacy policy URL.
   - Data safety form: phone number, name and payment info are processed by Razorpay.
   - Content rating.
   - Target API level as required by Play.

## 7. Day-to-day content (admin panel)

| Task | Where |
|---|---|
| Tomorrow's Subhechha | Content → Daily Subhechha (pick the date; it is pushed at 06:30 IST) |
| Today's tithi | Content → Tithi / Panchang (document id = date) |
| New festival year | Utsav → Events & Archive → Add (e.g. *नवरात्र उत्सव 2027*), then **Manage** to add the schedule/route and photos |
| Live aarti | Temple → Live Darshan → paste the YouTube Live URL and turn on *Live now* |
| Urgent notice | Content → Announcements (Urgent + Published) and Notifications → Send |
| Seva counter | Seva → QR Check-in (scan the devotee's pass) |
| Monthly accounts | Finance → Reports → Monthly → CSV |
