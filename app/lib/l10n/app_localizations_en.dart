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
  String get securePayment => 'Secure payment via Razorpay';

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
}
