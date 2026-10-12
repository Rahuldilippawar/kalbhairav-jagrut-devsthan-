# फक्त मोबाईलवरून सेटअप (Computer शिवाय)

Deploy करणे आणि APK बनवणे ही कामे **GitHub च्या servers** वर होतात. तुम्ही मोबाईलच्या Chrome मधून फक्त माहिती भरायची आणि बटण दाबायचे.

> **टीप:** सगळी पाने Chrome मध्ये उघडा आणि ⋮ मेनूमधून **"Desktop site"** चालू ठेवा. Firebase, Google Cloud आणि GitHub ची काही बटणे मोबाईल view मध्ये दिसत नाहीत.

खालील values एका note मध्ये लिहून ठेवत चला. त्या टप्पा 4 मध्ये GitHub वर भराव्या लागतील.

---

## टप्पा 1: Firebase प्रोजेक्ट (console.firebase.google.com)

1. **Create a project** → नाव द्या (उदा. `kalbhairav-devsthan`) → Google Analytics बंद ठेवले तरी चालेल → **Create project**.
   **Project ID** लिहून ठेवा → `FIREBASE_PROJECT_ID`
2. डावीकडे खाली **Spark → Upgrade** → **Blaze** → billing account जोडा (card/UPI).
   Google Cloud Billing मध्ये **Budget alert** (उदा. ₹500) नक्की लावा. छोट्या वापराला मोफत मर्यादा पुरेशी असते.
3. **Build → Authentication → Get started → Sign-in method**:
   - **Anonymous** → Enable. भक्तांना लॉगिन करावे लागत नाही; ॲप प्रत्येक फोनसाठी आपोआप अनामिक खाते बनवते.
   - **Email/Password** → Enable (ॲडमिन / "मंदिर व्यवस्थापन" लॉगिनसाठी).
4. **Build → Firestore Database → Create database**:
   - Location: **`asia-south1 (Mumbai)`**. ⚠️ ही location नंतर बदलता येत नाही आणि दुसरी location निवडली तर deploy अयशस्वी होईल.
   - **Production mode**.
5. **Build → Storage → Get started** → Production mode → शक्यतो तीच location.

## टप्पा 2: ॲप्स नोंदवणे (⚙️ Project settings → General → Your apps)

### Android ॲप
1. **Add app → Android**:
   - Package name: **`org.kalbhairav.kjd_app`** (अगदी असेच लिहा)
   - App nickname: `Kalbhairav App`
2. **Register app** दाबा. पुढील download पायऱ्यांवर फक्त **Next → Next → Continue to console** करा.
3. Android ॲपच्या कार्डमध्ये **Add fingerprint** दाबून हे दोन्ही जोडा. यांच्याशिवाय OTP लॉगिन चालणार नाही.
   ```
   SHA-1:   2A:AD:32:25:8F:58:52:A3:47:3A:85:C7:EB:99:00:2B:15:0C:36:1D
   SHA-256: 1D:DC:92:4E:3F:6C:F8:33:9A:DA:EC:DA:A3:E1:61:71:5D:2D:87:18:FC:CE:AD:B1:55:E4:37:78:55:68:70:A2
   ```
4. कार्डमधील **App ID** (`1:1234…:android:abcd…`) लिहून ठेवा → `FIREBASE_ANDROID_APP_ID`

### Web ॲप (ॲडमिन पॅनेलसाठी)
1. **Add app → Web (</>)** → nickname `KJD Admin` → **Register app**.
2. `firebaseConfig = { … }` असा मजकूर दिसेल. त्यातील values लिहून ठेवा:

| firebaseConfig मधील नाव | GitHub Variable |
|---|---|
| `apiKey` | `FIREBASE_API_KEY` |
| `authDomain` | `FIREBASE_AUTH_DOMAIN` |
| `projectId` | `FIREBASE_PROJECT_ID` |
| `storageBucket` | `FIREBASE_STORAGE_BUCKET` |
| `messagingSenderId` | `FIREBASE_SENDER_ID` |
| `appId` | `FIREBASE_WEB_APP_ID` |

या values गुप्त नसतात; त्या प्रत्येक ॲपमध्ये असतातच.

## टप्पा 3: Deploy साठी किल्ली (Service account) – 🔒 गुप्त

1. ⚙️ **Project settings → Service accounts → Generate new private key → Generate key**. एक `.json` फाइल download होईल.
2. Deploy साठी या खात्याला परवानग्या द्या:
   1. https://console.cloud.google.com/iam-admin/iam उघडा. वर तुमचा प्रोजेक्ट निवडलेला आहे ना ते पाहा.
   2. `firebase-adminsdk-…@….iam.gserviceaccount.com` या ओळीवरचे ✏️ (Edit) दाबा.
   3. **Add another role** ने हे 5 roles जोडा:
      - **Editor**
      - **Cloud Functions Admin**
      - **Cloud Run Admin**
      - **Secret Manager Admin**
      - **Service Account User**
   4. **Save** दाबा.
3. ही JSON फाइल मोबाईलवरच उघडा (Files ॲप → फाइल → "Open with" → कोणताही text viewer), **सगळा मजकूर** select करून कॉपी करा. तो टप्पा 4 मध्ये लागेल.

> ⚠️ ही फाइल किंवा तिचा मजकूर कोणालाही पाठवू नका, WhatsApp वर किंवा chat मध्येही नाही. फक्त GitHub Secrets मध्ये ठेवा आणि नंतर फाइल delete करा.

## टप्पा 3A: UPI पेमेंट (PhonePe Business)

भाविक PhonePe, Google Pay, Paytm किंवा कोणत्याही UPI ॲपने थेट मंदिराच्या खात्यात पैसे भरतात. यासाठी कोणतेही शुल्क नाही.

1. **PhonePe Business** ॲप उघडा → Profile / Settings मध्ये **UPI ID** पाहा (उदा. `xxxx@ybl`). तो लिहून ठेवा.
2. PhonePe Business मधील **QR** चा screenshot घ्या (ऐच्छिक).
3. ॲडमिन पॅनेल → **App Settings**:
   - **Temple UPI ID** → PhonePe Business चा UPI ID
   - **UPI payee name** → इंग्रजीत, उदा. `Shri Kalbhairav Jagrut Devsthan`
   - **PhonePe Business QR (photo)** → QR चा screenshot upload करा (ऐच्छिक)
   - **Save** दाबा.
4. भाविकाला देणगी / सेवा बुकिंगमध्ये **"PhonePe ने पैसे भरा"**, Google Pay, Paytm, इतर UPI ॲप ही बटणे, रकमेसह QR आणि मंदिराचा PhonePe QR दिसतो. पैसे भरल्यावर तो 12 अंकी **UTR** भरतो.
5. ॲडमिन → **Finance → UPI Verification** मध्ये PhonePe Business च्या व्यवहार यादीत तो UTR व रक्कम शोधा:
   - सापडले → **Approve** (पावती / सेवा पास तयार होतो, भाविकाला सूचना जाते)
   - सापडले नाही → **Reject** (सेवेची जागा परत मोकळी होते)

UPI ID भरेपर्यंत ॲपमध्ये "ऑनलाइन पेमेंट अजून सुरू झालेले नाही" असा संदेश दिसतो.

## टप्पा 4: GitHub मध्ये माहिती भरणे

Repository उघडा: https://github.com/Rahuldilippawar/kalbhairav-jagrut-devsthan-

1. **Settings → General → Default branch** → ⇄ दाबून **`main`** निवडा → Update.
2. **Settings → Secrets and variables → Actions**:

**Secrets** tab → **New repository secret** (🔒 गुप्त):

| Name | Value |
|---|---|
| `FIREBASE_SERVICE_ACCOUNT` | टप्पा 3 मधील JSON चा संपूर्ण मजकूर |

**Variables** tab → **New repository variable**:

| Name | Value |
|---|---|
| `FIREBASE_PROJECT_ID` | projectId |
| `FIREBASE_API_KEY` | apiKey |
| `FIREBASE_AUTH_DOMAIN` | authDomain |
| `FIREBASE_STORAGE_BUCKET` | storageBucket |
| `FIREBASE_SENDER_ID` | messagingSenderId |
| `FIREBASE_WEB_APP_ID` | Web ॲपचा appId |
| `FIREBASE_ANDROID_APP_ID` | Android ॲपचा App ID |
| `BOOTSTRAP_SUPER_ADMIN_EMAILS` | पहिल्या Super Admin चा ईमेल |

## टप्पा 5: Deploy (बटण दाबा)

1. GitHub → **Actions → Deploy to Firebase → Run workflow**.
2. Branch: `main`, target: **all** → **Run workflow**.
3. 10–15 मिनिटे थांबा. ✅ हिरवे झाल्यावर run उघडा. Summary मध्ये **ॲडमिन पॅनेल** (`https://<project-id>.web.app`) आणि **भाविकांचे वेब ॲप** (`https://<project-id>-app.web.app`) यांचे पत्ते दिसतील.

❌ लाल झाले तर run उघडून लाल step मधील शेवटच्या ओळी कॉपी करा आणि Claude ला पाठवा.

## टप्पा 6: APK (ॲप) बनवणे

1. **Actions → Build Android APK → Run workflow** (branch `main`).
2. सुमारे 10 मिनिटांनी repository च्या **Releases** मध्ये `Test APK #…` येईल. त्यातील `.apk` फाइल download करा.
3. फाइल उघडा → "Install unknown apps" ला परवानगी द्या → **Install**.

Firebase Variables भरण्यापूर्वी बनवलेली APK **डेमो मोड**मध्ये चालते. Variables भरल्यानंतर पुन्हा Run करा.

## टप्पा 7: पहिला Super Admin आणि माहिती

1. Firebase → **Authentication → Users → Add user**: `BOOTSTRAP_SUPER_ADMIN_EMAILS` मधील ईमेल आणि एक password.
2. ॲडमिन पॅनेल (`https://<project-id>.web.app`) उघडून लॉगिन करा. "No admin role" संदेश येईल, तिथे **Claim Super Admin** दाबा.
3. Dashboard → **Load starter content**.
4. **Temple Info** मध्ये खरी माहिती भरा: फोन, WhatsApp, पत्ता, latitude/longitude, इतिहास, ट्रस्ट नोंदणी, PAN, 80G. **Seva Catalogue** मध्ये खरे दर भरा.
5. **App Settings** मध्ये PhonePe Business चा UPI ID भरा (टप्पा 3A).

## टप्पा 8: चाचणी

- APK उघडताच लॉगिनशिवाय थेट Home दिसायला हवे. Profile → **मंदिर व्यवस्थापन** ने ॲडमिन लॉगिन उघडते का ते पाहा.
- देणगी: ₹1 देणगी PhonePe ने भरा, UTR भरा, मग ॲडमिनच्या UPI Verification मध्ये Approve करा. पावती येते का ते पाहा.
- सेवा बुक करा → QR पास → ॲडमिनमधील **QR Check-in** ने मोबाईल कॅमेऱ्याने scan करा.
- ॲडमिनमधून एक Notification पाठवा. फोनवर येते का ते पाहा.

## नंतर बदल केल्यावर

| काय बदलले | काय Run करायचे |
|---|---|
| कोड (Claude ने बदल केले) | Deploy → **all**, आणि Build Android APK |
| फक्त ॲडमिन पॅनेल | Deploy → **admin** |

## अडचणी

| संदेश | उपाय |
|---|---|
| `Missing: …` | टप्पा 4 मधील ते Secret/Variable भरा |
| `Permission denied` / `403` | टप्पा 3 मधील 5 roles जोडले का ते तपासा |
| `Billing account not configured` | प्रोजेक्ट Blaze plan वर आहे का ते तपासा |
| Region / location error | Firestore `asia-south1` मध्ये नाही; नवीन प्रोजेक्ट Mumbai मध्ये बनवावा लागेल |
| Build service account error (पहिल्या deploy ला) | काही मिनिटांनी पुन्हा Run करा; तरी आला तर संदेश Claude ला पाठवा |
| ॲपमध्ये "operation is not allowed" | Authentication → Sign-in method मध्ये **Anonymous** Enable केले का |

> Play Store साठीची खरी signing key वेगळी असते. ती नंतर सुरक्षितपणे बनवू. ही APK फक्त चाचणीसाठी आहे.
