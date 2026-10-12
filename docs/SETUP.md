# Going live – setup guide

These steps take the project from demo mode to production. Commands are run from the repository root unless noted.

## 1. Tools

- Flutter (stable) – `flutter --version`
- Node.js 22 and the Firebase CLI – `npm i -g firebase-tools`
- FlutterFire CLI – `dart pub global activate flutterfire_cli`
- Java 21 (only for the rules emulator tests)

## 2. Firebase project

1. Create a project in the [Firebase console](https://console.firebase.google.com), on the **Blaze** plan. Cloud Functions need Blaze.
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

## 3. Payments (UPI, e.g. PhonePe Business)

Devotees pay by UPI straight to the temple; there is no payment gateway or fee.

1. Configure Functions:

   ```bash
   cp functions/.env.example functions/.env.<project-id>
   # edit BOOTSTRAP_SUPER_ADMIN_EMAILS
   ```

2. After deploying, open the admin panel → **App Settings** and set **Temple UPI ID** (from the PhonePe Business app), the **UPI payee name** in English and, optionally, a photo of the temple's PhonePe Business QR.
3. The app offers PhonePe, Google Pay, Paytm and any other UPI app, plus a QR with the amount filled in. The devotee enters the 12-digit UTR; the office matches it against the PhonePe Business statement under **Finance → UPI Verification** and approves, which issues the receipt or seva pass.

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
3. On the Dashboard, click **Load starter content**. This adds event categories, settings, darshan timings, sample sevas, banner templates, quotes, mantras and temple info. Then edit Temple Info (phone, WhatsApp, coordinates, history, and the **trust registration no., PAN and 80G no.** printed on receipts), check the mantra texts, and set the seva prices.
4. Add other staff under **Admin Users & Roles**. If a staff member has no account yet, the panel gives you a password-setup link to send them.

## 6. Android release

1. Create an upload keystore (keep it and its passwords safe – losing it blocks future updates):

   ```bash
   keytool -genkey -v -keystore ~/kjd-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `app/android/key.properties` (git-ignored):

   ```properties
   storeFile=/home/you/kjd-upload-keystore.jks
   storePassword=…
   keyAlias=upload
   keyPassword=…
   ```

   The Gradle config picks it up automatically and enables R8 shrinking (`app/android/app/proguard-rules.pro`).
3. Add the upload key's SHA-1/SHA-256 (and, after the first upload, Play App Signing's) to the Firebase Android app – phone OTP needs them.
4. Bump `version:` in `app/pubspec.yaml`, then `cd app && flutter build appbundle --release`.
5. Play Console checklist:
   - Privacy policy URL.
   - Data safety form: phone number, name, photos (optional) and UPI transaction references (UTR).
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
