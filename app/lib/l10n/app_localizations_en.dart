// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kalbhairav Jagrut Devsthan';

  @override
  String get tagline => 'Darshan • Seva • Utsav • Bhakti • Sanskriti';

  @override
  String get navHome => 'Home';

  @override
  String get navDarshan => 'Darshan';

  @override
  String get navEvents => 'Events';

  @override
  String get navSeva => 'Seva';

  @override
  String get navProfile => 'Profile';

  @override
  String get quickDarshan => 'Darshan';

  @override
  String get quickSeva => 'Seva';

  @override
  String get quickDonate => 'Donate';

  @override
  String get quickEvents => 'Utsav';

  @override
  String get quickLive => 'Live';

  @override
  String get quickTemple => 'Temple';

  @override
  String get quickGallery => 'Gallery';

  @override
  String get quickBanner => 'Banners';

  @override
  String get todaysGreeting => 'Today\'s Subhechha';

  @override
  String get todaysTithi => 'Today\'s Tithi';

  @override
  String get todaysNotice => 'Today\'s Notice';

  @override
  String get todaysDarshan => 'Today\'s Darshan';

  @override
  String get todaysQuote => 'Thought of the Day';

  @override
  String get upcomingEvents => 'Upcoming Utsav';

  @override
  String get viewAll => 'View all';

  @override
  String get viewEvent => 'View Event';

  @override
  String get share => 'Share';

  @override
  String get download => 'Save';

  @override
  String get donateNow => 'Donate Now';

  @override
  String get donateCta => 'Support the temple with your offering';

  @override
  String get liveDarshan => 'Live Darshan';

  @override
  String get liveNow => 'LIVE';

  @override
  String get notLive => 'Live darshan is not running right now.';

  @override
  String get openInYoutube => 'Open in YouTube';

  @override
  String get darshanOpenNow => 'Darshan open now';

  @override
  String get darshanClosedNow => 'Darshan closed now';

  @override
  String get darshanTimings => 'Darshan Timings';

  @override
  String get aartiTimings => 'Aarti Timings';

  @override
  String get specialDarshan => 'Special Darshan';

  @override
  String get tithi => 'Tithi';

  @override
  String get vaar => 'Day';

  @override
  String get paksha => 'Paksha';

  @override
  String get nakshatra => 'Nakshatra';

  @override
  String get yoga => 'Yoga';

  @override
  String get karana => 'Karana';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get sunset => 'Sunset';

  @override
  String get masa => 'Month';

  @override
  String get specialDay => 'Special Day';

  @override
  String get sampleData => 'Sample data – will be updated by the temple';

  @override
  String get tithiNotAvailable => 'Today\'s tithi has not been published yet.';

  @override
  String get events => 'Utsav & Events';

  @override
  String get allCategories => 'All';

  @override
  String get archive => 'Archive';

  @override
  String get schedule => 'Schedule';

  @override
  String get photos => 'Photos';

  @override
  String get videos => 'Videos';

  @override
  String get details => 'Details';

  @override
  String get route => 'Route';

  @override
  String get remindMe => 'Remind Me';

  @override
  String get reminderOn => 'Reminder set';

  @override
  String get getDirections => 'Get Directions';

  @override
  String get watchLive => 'Watch Live';

  @override
  String day(int n) {
    return 'Day $n';
  }

  @override
  String get departure => 'Departure';

  @override
  String get mukkaam => 'Night halt';

  @override
  String get startPoint => 'Start';

  @override
  String get destination => 'Destination';

  @override
  String get instructions => 'Important instructions';

  @override
  String get contact => 'Contact';

  @override
  String get ongoing => 'Ongoing';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get completed => 'Completed';

  @override
  String get religiousInfo => 'Religious significance';

  @override
  String get highlights => 'Highlights';

  @override
  String get noEvents => 'No events found.';

  @override
  String get nothingHereYet => 'Nothing here yet.';

  @override
  String get seva => 'Seva';

  @override
  String get bookSeva => 'Book Seva';

  @override
  String get selectDate => 'Select date';

  @override
  String get selectTime => 'Select time';

  @override
  String slotsLeft(int n) {
    return '$n left';
  }

  @override
  String get full => 'Full';

  @override
  String get devoteeDetails => 'Devotee details';

  @override
  String get devoteeName => 'Devotee name';

  @override
  String get mobile => 'Mobile number';

  @override
  String get gotra => 'Gotra (optional)';

  @override
  String get sankalp => 'Sankalp / Prayer (optional)';

  @override
  String confirmAndPay(String amount) {
    return 'Confirm & Pay $amount';
  }

  @override
  String get bookingConfirmed => 'Booking confirmed';

  @override
  String get sevaPass => 'QR Seva Pass';

  @override
  String get showPassAtTemple => 'Show this pass at the temple counter.';

  @override
  String get bookingId => 'Booking ID';

  @override
  String get status => 'Status';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get donation => 'Donation';

  @override
  String get donationPurpose => 'Purpose';

  @override
  String get donationAmount => 'Amount';

  @override
  String get customAmount => 'Other amount (₹)';

  @override
  String get yourDetails => 'Your details';

  @override
  String get fullName => 'Full name';

  @override
  String get email => 'Email (optional)';

  @override
  String get address => 'Address (optional)';

  @override
  String get pan => 'PAN (optional, for 80G)';

  @override
  String proceedToPay(String amount) {
    return 'Proceed to pay $amount';
  }

  @override
  String get paymentSuccess => 'Thank you! Your offering is received.';

  @override
  String get paymentFailed => 'Payment failed';

  @override
  String get paymentCancelled => 'Payment cancelled';

  @override
  String get processing => 'Processing…';

  @override
  String get receipt => 'Receipt';

  @override
  String get receiptNo => 'Receipt No';

  @override
  String get paymentId => 'Payment ID';

  @override
  String get purpose => 'Purpose';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get securePayment =>
      'Pay by UPI directly to the temple (PhonePe, GPay, Paytm, BHIM)';

  @override
  String get login => 'Login';

  @override
  String get loginTitle => 'Login with mobile number';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get enterOtp => 'Enter the 6 digit OTP';

  @override
  String get verify => 'Verify';

  @override
  String get continueAsGuest => 'Continue without login';

  @override
  String get loginRequired => 'Please login to continue';

  @override
  String get demoMode => 'Demo mode – data is not saved to the server';

  @override
  String get demoOtpHint => 'Demo OTP: 123456';

  @override
  String get invalidMobile => 'Enter a valid 10 digit mobile number';

  @override
  String get required => 'Required';

  @override
  String get profile => 'My Profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get name => 'Name';

  @override
  String get village => 'Village';

  @override
  String get dob => 'Date of birth';

  @override
  String get anniversary => 'Wedding anniversary';

  @override
  String get spouseName => 'Spouse name';

  @override
  String get birthdayPrivacy => 'Birthday greeting';

  @override
  String get privacyPrivate => 'Private';

  @override
  String get privacyTemple => 'Greeting from temple';

  @override
  String get privacyPublic => 'Public';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get family => 'Family';

  @override
  String get addFamilyMember => 'Add family member';

  @override
  String get relation => 'Relation';

  @override
  String get mySeva => 'My Seva';

  @override
  String get myDonations => 'My Donations';

  @override
  String get myReceipts => 'My Receipts';

  @override
  String get myPasses => 'My Passes';

  @override
  String get myEvents => 'My Events';

  @override
  String get myBanners => 'My Banners';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get logout => 'Logout';

  @override
  String get templeInfo => 'About Temple';

  @override
  String get history => 'History';

  @override
  String get importance => 'Importance';

  @override
  String get tradition => 'Tradition';

  @override
  String get parampara => 'Gadi / Parampara';

  @override
  String get location => 'Location';

  @override
  String get call => 'Call';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get gallery => 'Gallery';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search events, seva, gallery…';

  @override
  String get noResults => 'No results';

  @override
  String get bannerStudio => 'Digital Banner Studio';

  @override
  String get selectCategory => 'Category';

  @override
  String get selectTemplate => 'Template';

  @override
  String get headline => 'Headline';

  @override
  String get message => 'Message';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get preview => 'Preview';

  @override
  String get happyBirthday => 'Happy Birthday';

  @override
  String birthdayWish(String name) {
    return 'Happy birthday, $name! May Shri Kalbhairav bless you always.';
  }

  @override
  String anniversaryWish(String name) {
    return 'Happy wedding anniversary, $name!';
  }

  @override
  String get createBanner => 'Create banner';

  @override
  String get announcements => 'Announcements';

  @override
  String get error => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get closureNotice => 'Notice';

  @override
  String get free => 'Free';

  @override
  String get maintenance =>
      'The app is under maintenance. Please check back soon.';

  @override
  String get onboard1Title => 'Darshan & Live';

  @override
  String get onboard1Body =>
      'Darshan timings, aarti and live darshan from Rundhati.';

  @override
  String get onboard2Title => 'Seva & Donation';

  @override
  String get onboard2Body =>
      'Book puja and seva, donate securely and get instant receipts.';

  @override
  String get onboard3Title => 'Utsav & Bhakti';

  @override
  String get onboard3Body =>
      'Navratri, Guru Purnima, Payi Dindi and daily subhechha.';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get skip => 'Skip';

  @override
  String get computedData =>
      'Calculated for Rundhati (approximate); the temple may update it';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get photoUploadUnavailable =>
      'Photo upload is available once the app is connected to the temple server.';

  @override
  String get mantras => 'Mantras';

  @override
  String get mantraJapa => 'Mantra Japa';

  @override
  String get mantraJapaCta => 'Chant with a japa counter';

  @override
  String get meaning => 'Meaning';

  @override
  String get tapToCount => 'Tap to count';

  @override
  String malasDone(int n) {
    return 'Malas: $n';
  }

  @override
  String get reset => 'Reset';

  @override
  String get japaComplete => 'Mala complete 🙏';

  @override
  String get todaysWishes => 'Today\'s Birthdays & Anniversaries';

  @override
  String get sendWishes => 'Send wishes';

  @override
  String get privacyPublicHelp =>
      'Public: your name and village appear in “Today\'s Birthdays” in the app.';

  @override
  String get trustRegNo => 'Trust Reg. No.';

  @override
  String get trustPan => 'Trust PAN';

  @override
  String get eightyGNo => '80G No.';

  @override
  String get eightyGNote =>
      'Donation eligible for deduction under section 80G of the Income Tax Act.';

  @override
  String get listen => 'Listen';

  @override
  String get templeManagement => 'Temple Management';

  @override
  String get templeManagementHint => 'For temple staff – admin login';

  @override
  String get adminUnavailableDemo =>
      'The admin panel is available once the app is connected to the temple server.';

  @override
  String get devoteeGuestNote =>
      'Your seva bookings, receipts and reminders are saved on this phone. Add your name and mobile so the temple can recognise you.';

  @override
  String get bannerFormat => 'Size';

  @override
  String get formatSquare => 'Post';

  @override
  String get formatStory => 'Status';

  @override
  String get formatLandscape => 'Wide';

  @override
  String get bannerSender => 'Greeted by (your name)';

  @override
  String get senderPhoto => 'Your photo';

  @override
  String get bannerDesign => 'Style';

  @override
  String get payByUpi => 'Pay by UPI';

  @override
  String get upiPayTo => 'Pay to';

  @override
  String get upiOpenApp => 'Pay with a UPI app';

  @override
  String get upiScanQr =>
      'Or scan this QR with any UPI app (GPay, PhonePe, Paytm, BHIM)';

  @override
  String get upiShareQr => 'Share / save QR';

  @override
  String get upiCopied => 'UPI ID copied';

  @override
  String get upiNoApp =>
      'No UPI app found on this phone. Scan the QR from another phone.';

  @override
  String get upiUtrLabel => 'UTR / UPI Ref No. (12 digits)';

  @override
  String get upiUtrHelp =>
      'After paying, open the payment in your UPI app: GPay – \"UPI transaction ID\", PhonePe – \"UTR\", Paytm – \"UPI Ref No.\"';

  @override
  String get upiUtrInvalid => 'Enter the 12-digit UTR number';

  @override
  String get upiSubmit => 'Submit for verification';

  @override
  String get upiCheckAmount =>
      'Before paying, check the amount and the temple name in your UPI app.';

  @override
  String get upiLeaveTitle => 'Leave without the UTR?';

  @override
  String get upiLeaveBody =>
      'If you have already paid, enter the UTR number. Without it the temple cannot match your payment.';

  @override
  String get upiLeave => 'Leave';

  @override
  String get upiStay => 'Stay';

  @override
  String get upiSubmittedTitle => 'Payment sent for verification';

  @override
  String get upiSubmittedBody =>
      'The temple office will check your payment in the bank statement and then issue the receipt. You will get a notification and it will appear in My receipts.';

  @override
  String get upiPending => 'Being verified';

  @override
  String get upiRejected => 'Not accepted';

  @override
  String get upiPayments => 'UPI payments';

  @override
  String get upiStep1 => '1. Pay';

  @override
  String get upiStep2 => '2. Enter the UTR number';

  @override
  String get upiReference => 'Reference';

  @override
  String get upiSecureNote =>
      'Pay by UPI directly to the temple (PhonePe, GPay, Paytm, BHIM)';

  @override
  String get latestDarshan => 'Latest darshan';

  @override
  String get dailyQuoteTitle => 'Today\'s thought';

  @override
  String get dontShowDaily => 'Don\'t show daily';

  @override
  String get close => 'Close';

  @override
  String get dailyQuotePopup => 'Daily thought on opening';

  @override
  String get dailyQuotePopupHint =>
      'Show today\'s suvichar once a day when the app opens';

  @override
  String get makeBanner => 'Make banner';

  @override
  String get headlineFontLabel => 'Headline lettering';

  @override
  String get bodyFontLabel => 'Message lettering';

  @override
  String get textSize => 'Text size';

  @override
  String get festivalsAndTithis => 'Festivals & tithis';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get kindFestival => 'Festivals';

  @override
  String get kindJayanti => 'Jayanti';

  @override
  String get kindVrat => 'Vrat / tithi';

  @override
  String get kindNational => 'National days';

  @override
  String get makeFestivalBanner => 'Make greeting banner';

  @override
  String get todayIs => 'Today';

  @override
  String get upcomingFestival => 'Coming up';

  @override
  String inDays(int n) {
    return 'in $n days';
  }

  @override
  String get festivalCalendar => 'Festival calendar';

  @override
  String get festivalDateNote =>
      'Dates are computed for Rundhati by Panchang rules; the temple office can correct any date.';

  @override
  String get templeDeities => 'Deities in the temple';

  @override
  String get aboutDeity => 'About';

  @override
  String get deityHistory => 'History & legend';

  @override
  String get mantraLabel => 'Mantra';

  @override
  String get aartiLabel => 'Aarti / stotra';

  @override
  String get worshipDay => 'Day of worship';

  @override
  String get placeInTemple => 'Place in the temple';

  @override
  String get nextSpecialDays => 'Next special days';

  @override
  String get gadhipatiParampara => 'Gadhipati parampara';

  @override
  String get currentGadhipati => 'Present gadhipati';

  @override
  String get periodLabel => 'Period';

  @override
  String get birthLabel => 'Birth';

  @override
  String get samadhiLabel => 'Samadhi / punyatithi';

  @override
  String get bioLabel => 'Life';

  @override
  String get workLabel => 'Work';

  @override
  String get vachanLabel => 'Teaching';

  @override
  String get quickDeities => 'Deities';

  @override
  String get quickParampara => 'Parampara';

  @override
  String get quickTithi => 'Tithi';

  @override
  String get quickMantras => 'Mantras';

  @override
  String get copied => 'Copied';

  @override
  String get mainDeity => 'Main deity';

  @override
  String get payWithPhonePe => 'Pay with PhonePe';

  @override
  String get otherUpiApp => 'Other UPI app';

  @override
  String get appNotInstalled =>
      'This app is not on the phone. Choose another option or scan the QR.';

  @override
  String get qrWithAmount => 'QR with amount';

  @override
  String get templeQr => 'Temple\'s PhonePe QR';

  @override
  String templeQrNote(String amount) {
    return 'After scanning this QR, enter the amount $amount yourself.';
  }

  @override
  String get navGuru => 'Guru Gyan';

  @override
  String get guruGyanIntro =>
      'Deity information, kathas, stotras and puja vidhi for the temple\'s shishya parivar. Register as a shishya; once the temple management approves, all lessons open for you.';

  @override
  String get shishyaRegister => 'Shishya registration';

  @override
  String get shishyaLogin => 'Shishya login';

  @override
  String get haveAccountLogin => 'Already registered? Log in';

  @override
  String get newShishyaRegister => 'New shishya? Register';

  @override
  String get password => 'Password';

  @override
  String get passwordHint =>
      'At least 6 characters – remember it to log in on a new phone';

  @override
  String get guruNameLabel => 'Guru / introduced by (optional)';

  @override
  String get noteToTemple => 'Message to the temple (optional)';

  @override
  String get submitRequest => 'Send request';

  @override
  String get requestPendingTitle =>
      'Your request has been sent to the temple management';

  @override
  String get requestPendingBody =>
      'You will get a notification as soon as it is approved, and Guru Gyan will open. 🙏';

  @override
  String get requestRejectedTitle => 'Your request was not approved';

  @override
  String get applyAgain => 'Request again';

  @override
  String get accessBlocked =>
      'Your access is currently closed. Please contact the temple management.';

  @override
  String get mobileAlreadyRegistered =>
      'This mobile number is already registered. Use \"Log in\".';

  @override
  String get wrongLogin => 'Wrong mobile number or password';

  @override
  String get weakPassword => 'Password must be at least 6 characters';

  @override
  String get forgotPasswordNote =>
      'Forgot the password? The temple management can set a new one for you.';

  @override
  String get lessonsLocked => 'Lessons for shishyas (open after approval)';

  @override
  String get markRead => 'Mark as read';

  @override
  String get markedRead => 'Read';

  @override
  String get allLessons => 'All';

  @override
  String get otherLessons => 'General';

  @override
  String get shishyaLogout => 'Log out of shishya account';

  @override
  String get openDeityPage => 'Deity information';

  @override
  String get nextLesson => 'Next lesson';

  @override
  String get requestSent => 'Request sent 🙏';

  @override
  String lessonsProgress(int done, int total) {
    return 'Read $done of $total lessons';
  }

  @override
  String readMinutes(int n) {
    return '$n min read';
  }

  @override
  String welcomeShishya(String name) {
    return 'Welcome to Guru Gyan, $name 🙏';
  }

  @override
  String get webQuickLinks => 'Quick links';

  @override
  String get webFestivals => 'Upcoming festivals & vrats';

  @override
  String get webInstallHint =>
      'Add this page to your home screen to use it like an app.';
}
