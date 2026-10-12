import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Kalbhairav Jagrut Devsthan'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Darshan • Seva • Utsav • Bhakti • Sanskriti'**
  String get tagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDarshan.
  ///
  /// In en, this message translates to:
  /// **'Darshan'**
  String get navDarshan;

  /// No description provided for @navEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// No description provided for @navSeva.
  ///
  /// In en, this message translates to:
  /// **'Seva'**
  String get navSeva;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @quickDarshan.
  ///
  /// In en, this message translates to:
  /// **'Darshan'**
  String get quickDarshan;

  /// No description provided for @quickSeva.
  ///
  /// In en, this message translates to:
  /// **'Seva'**
  String get quickSeva;

  /// No description provided for @quickDonate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get quickDonate;

  /// No description provided for @quickEvents.
  ///
  /// In en, this message translates to:
  /// **'Utsav'**
  String get quickEvents;

  /// No description provided for @quickLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get quickLive;

  /// No description provided for @quickTemple.
  ///
  /// In en, this message translates to:
  /// **'Temple'**
  String get quickTemple;

  /// No description provided for @quickGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get quickGallery;

  /// No description provided for @quickBanner.
  ///
  /// In en, this message translates to:
  /// **'Banners'**
  String get quickBanner;

  /// No description provided for @todaysGreeting.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Subhechha'**
  String get todaysGreeting;

  /// No description provided for @todaysTithi.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tithi'**
  String get todaysTithi;

  /// No description provided for @todaysNotice.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Notice'**
  String get todaysNotice;

  /// No description provided for @todaysDarshan.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Darshan'**
  String get todaysDarshan;

  /// No description provided for @todaysQuote.
  ///
  /// In en, this message translates to:
  /// **'Thought of the Day'**
  String get todaysQuote;

  /// No description provided for @upcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Utsav'**
  String get upcomingEvents;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @viewEvent.
  ///
  /// In en, this message translates to:
  /// **'View Event'**
  String get viewEvent;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get download;

  /// No description provided for @donateNow.
  ///
  /// In en, this message translates to:
  /// **'Donate Now'**
  String get donateNow;

  /// No description provided for @donateCta.
  ///
  /// In en, this message translates to:
  /// **'Support the temple with your offering'**
  String get donateCta;

  /// No description provided for @liveDarshan.
  ///
  /// In en, this message translates to:
  /// **'Live Darshan'**
  String get liveDarshan;

  /// No description provided for @liveNow.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveNow;

  /// No description provided for @notLive.
  ///
  /// In en, this message translates to:
  /// **'Live darshan is not running right now.'**
  String get notLive;

  /// No description provided for @openInYoutube.
  ///
  /// In en, this message translates to:
  /// **'Open in YouTube'**
  String get openInYoutube;

  /// No description provided for @darshanOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Darshan open now'**
  String get darshanOpenNow;

  /// No description provided for @darshanClosedNow.
  ///
  /// In en, this message translates to:
  /// **'Darshan closed now'**
  String get darshanClosedNow;

  /// No description provided for @darshanTimings.
  ///
  /// In en, this message translates to:
  /// **'Darshan Timings'**
  String get darshanTimings;

  /// No description provided for @aartiTimings.
  ///
  /// In en, this message translates to:
  /// **'Aarti Timings'**
  String get aartiTimings;

  /// No description provided for @specialDarshan.
  ///
  /// In en, this message translates to:
  /// **'Special Darshan'**
  String get specialDarshan;

  /// No description provided for @tithi.
  ///
  /// In en, this message translates to:
  /// **'Tithi'**
  String get tithi;

  /// No description provided for @vaar.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get vaar;

  /// No description provided for @paksha.
  ///
  /// In en, this message translates to:
  /// **'Paksha'**
  String get paksha;

  /// No description provided for @nakshatra.
  ///
  /// In en, this message translates to:
  /// **'Nakshatra'**
  String get nakshatra;

  /// No description provided for @yoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get yoga;

  /// No description provided for @karana.
  ///
  /// In en, this message translates to:
  /// **'Karana'**
  String get karana;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunset;

  /// No description provided for @masa.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get masa;

  /// No description provided for @specialDay.
  ///
  /// In en, this message translates to:
  /// **'Special Day'**
  String get specialDay;

  /// No description provided for @sampleData.
  ///
  /// In en, this message translates to:
  /// **'Sample data – will be updated by the temple'**
  String get sampleData;

  /// No description provided for @tithiNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Today\'s tithi has not been published yet.'**
  String get tithiNotAvailable;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Utsav & Events'**
  String get events;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @remindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind Me'**
  String get remindMe;

  /// No description provided for @reminderOn.
  ///
  /// In en, this message translates to:
  /// **'Reminder set'**
  String get reminderOn;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @watchLive.
  ///
  /// In en, this message translates to:
  /// **'Watch Live'**
  String get watchLive;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String day(int n);

  /// No description provided for @departure.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get departure;

  /// No description provided for @mukkaam.
  ///
  /// In en, this message translates to:
  /// **'Night halt'**
  String get mukkaam;

  /// No description provided for @startPoint.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startPoint;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Important instructions'**
  String get instructions;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @religiousInfo.
  ///
  /// In en, this message translates to:
  /// **'Religious significance'**
  String get religiousInfo;

  /// No description provided for @highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// No description provided for @noEvents.
  ///
  /// In en, this message translates to:
  /// **'No events found.'**
  String get noEvents;

  /// No description provided for @nothingHereYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get nothingHereYet;

  /// No description provided for @seva.
  ///
  /// In en, this message translates to:
  /// **'Seva'**
  String get seva;

  /// No description provided for @bookSeva.
  ///
  /// In en, this message translates to:
  /// **'Book Seva'**
  String get bookSeva;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @slotsLeft.
  ///
  /// In en, this message translates to:
  /// **'{n} left'**
  String slotsLeft(int n);

  /// No description provided for @full.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get full;

  /// No description provided for @devoteeDetails.
  ///
  /// In en, this message translates to:
  /// **'Devotee details'**
  String get devoteeDetails;

  /// No description provided for @devoteeName.
  ///
  /// In en, this message translates to:
  /// **'Devotee name'**
  String get devoteeName;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobile;

  /// No description provided for @gotra.
  ///
  /// In en, this message translates to:
  /// **'Gotra (optional)'**
  String get gotra;

  /// No description provided for @sankalp.
  ///
  /// In en, this message translates to:
  /// **'Sankalp / Prayer (optional)'**
  String get sankalp;

  /// No description provided for @confirmAndPay.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Pay {amount}'**
  String confirmAndPay(String amount);

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get bookingConfirmed;

  /// No description provided for @sevaPass.
  ///
  /// In en, this message translates to:
  /// **'QR Seva Pass'**
  String get sevaPass;

  /// No description provided for @showPassAtTemple.
  ///
  /// In en, this message translates to:
  /// **'Show this pass at the temple counter.'**
  String get showPassAtTemple;

  /// No description provided for @bookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get bookingId;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @donation.
  ///
  /// In en, this message translates to:
  /// **'Donation'**
  String get donation;

  /// No description provided for @donationPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get donationPurpose;

  /// No description provided for @donationAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get donationAmount;

  /// No description provided for @customAmount.
  ///
  /// In en, this message translates to:
  /// **'Other amount (₹)'**
  String get customAmount;

  /// No description provided for @yourDetails.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get yourDetails;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get email;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get address;

  /// No description provided for @pan.
  ///
  /// In en, this message translates to:
  /// **'PAN (optional, for 80G)'**
  String get pan;

  /// No description provided for @proceedToPay.
  ///
  /// In en, this message translates to:
  /// **'Proceed to pay {amount}'**
  String proceedToPay(String amount);

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your offering is received.'**
  String get paymentSuccess;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailed;

  /// No description provided for @paymentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get paymentCancelled;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get processing;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @receiptNo.
  ///
  /// In en, this message translates to:
  /// **'Receipt No'**
  String get receiptNo;

  /// No description provided for @paymentId.
  ///
  /// In en, this message translates to:
  /// **'Payment ID'**
  String get paymentId;

  /// No description provided for @purpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get purpose;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @securePayment.
  ///
  /// In en, this message translates to:
  /// **'Secure payment via Razorpay'**
  String get securePayment;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login with mobile number'**
  String get loginTitle;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6 digit OTP'**
  String get enterOtp;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue without login'**
  String get continueAsGuest;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please login to continue'**
  String get loginRequired;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode – data is not saved to the server'**
  String get demoMode;

  /// No description provided for @demoOtpHint.
  ///
  /// In en, this message translates to:
  /// **'Demo OTP: 123456'**
  String get demoOtpHint;

  /// No description provided for @invalidMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10 digit mobile number'**
  String get invalidMobile;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get village;

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dob;

  /// No description provided for @anniversary.
  ///
  /// In en, this message translates to:
  /// **'Wedding anniversary'**
  String get anniversary;

  /// No description provided for @spouseName.
  ///
  /// In en, this message translates to:
  /// **'Spouse name'**
  String get spouseName;

  /// No description provided for @birthdayPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Birthday greeting'**
  String get birthdayPrivacy;

  /// No description provided for @privacyPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get privacyPrivate;

  /// No description provided for @privacyTemple.
  ///
  /// In en, this message translates to:
  /// **'Greeting from temple'**
  String get privacyTemple;

  /// No description provided for @privacyPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get privacyPublic;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @addFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Add family member'**
  String get addFamilyMember;

  /// No description provided for @relation.
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get relation;

  /// No description provided for @mySeva.
  ///
  /// In en, this message translates to:
  /// **'My Seva'**
  String get mySeva;

  /// No description provided for @myDonations.
  ///
  /// In en, this message translates to:
  /// **'My Donations'**
  String get myDonations;

  /// No description provided for @myReceipts.
  ///
  /// In en, this message translates to:
  /// **'My Receipts'**
  String get myReceipts;

  /// No description provided for @myPasses.
  ///
  /// In en, this message translates to:
  /// **'My Passes'**
  String get myPasses;

  /// No description provided for @myEvents.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get myEvents;

  /// No description provided for @myBanners.
  ///
  /// In en, this message translates to:
  /// **'My Banners'**
  String get myBanners;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @templeInfo.
  ///
  /// In en, this message translates to:
  /// **'About Temple'**
  String get templeInfo;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @importance.
  ///
  /// In en, this message translates to:
  /// **'Importance'**
  String get importance;

  /// No description provided for @tradition.
  ///
  /// In en, this message translates to:
  /// **'Tradition'**
  String get tradition;

  /// No description provided for @parampara.
  ///
  /// In en, this message translates to:
  /// **'Gadi / Parampara'**
  String get parampara;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search events, seva, gallery…'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @bannerStudio.
  ///
  /// In en, this message translates to:
  /// **'Digital Banner Studio'**
  String get bannerStudio;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get selectCategory;

  /// No description provided for @selectTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get selectTemplate;

  /// No description provided for @headline.
  ///
  /// In en, this message translates to:
  /// **'Headline'**
  String get headline;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @happyBirthday.
  ///
  /// In en, this message translates to:
  /// **'Happy Birthday'**
  String get happyBirthday;

  /// No description provided for @birthdayWish.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday, {name}! May Shri Kalbhairav bless you always.'**
  String birthdayWish(String name);

  /// No description provided for @anniversaryWish.
  ///
  /// In en, this message translates to:
  /// **'Happy wedding anniversary, {name}!'**
  String anniversaryWish(String name);

  /// No description provided for @createBanner.
  ///
  /// In en, this message translates to:
  /// **'Create banner'**
  String get createBanner;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @closureNotice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get closureNotice;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'The app is under maintenance. Please check back soon.'**
  String get maintenance;

  /// No description provided for @onboard1Title.
  ///
  /// In en, this message translates to:
  /// **'Darshan & Live'**
  String get onboard1Title;

  /// No description provided for @onboard1Body.
  ///
  /// In en, this message translates to:
  /// **'Darshan timings, aarti and live darshan from Rundhati.'**
  String get onboard1Body;

  /// No description provided for @onboard2Title.
  ///
  /// In en, this message translates to:
  /// **'Seva & Donation'**
  String get onboard2Title;

  /// No description provided for @onboard2Body.
  ///
  /// In en, this message translates to:
  /// **'Book puja and seva, donate securely and get instant receipts.'**
  String get onboard2Body;

  /// No description provided for @onboard3Title.
  ///
  /// In en, this message translates to:
  /// **'Utsav & Bhakti'**
  String get onboard3Title;

  /// No description provided for @onboard3Body.
  ///
  /// In en, this message translates to:
  /// **'Navratri, Guru Purnima, Payi Dindi and daily subhechha.'**
  String get onboard3Body;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @computedData.
  ///
  /// In en, this message translates to:
  /// **'Calculated for Rundhati (approximate); the temple may update it'**
  String get computedData;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @photoUploadUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo upload is available once the app is connected to the temple server.'**
  String get photoUploadUnavailable;

  /// No description provided for @mantras.
  ///
  /// In en, this message translates to:
  /// **'Mantras'**
  String get mantras;

  /// No description provided for @mantraJapa.
  ///
  /// In en, this message translates to:
  /// **'Mantra Japa'**
  String get mantraJapa;

  /// No description provided for @mantraJapaCta.
  ///
  /// In en, this message translates to:
  /// **'Chant with a japa counter'**
  String get mantraJapaCta;

  /// No description provided for @meaning.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get meaning;

  /// No description provided for @tapToCount.
  ///
  /// In en, this message translates to:
  /// **'Tap to count'**
  String get tapToCount;

  /// No description provided for @malasDone.
  ///
  /// In en, this message translates to:
  /// **'Malas: {n}'**
  String malasDone(int n);

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @japaComplete.
  ///
  /// In en, this message translates to:
  /// **'Mala complete 🙏'**
  String get japaComplete;

  /// No description provided for @todaysWishes.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Birthdays & Anniversaries'**
  String get todaysWishes;

  /// No description provided for @sendWishes.
  ///
  /// In en, this message translates to:
  /// **'Send wishes'**
  String get sendWishes;

  /// No description provided for @privacyPublicHelp.
  ///
  /// In en, this message translates to:
  /// **'Public: your name and village appear in “Today\'s Birthdays” in the app.'**
  String get privacyPublicHelp;

  /// No description provided for @trustRegNo.
  ///
  /// In en, this message translates to:
  /// **'Trust Reg. No.'**
  String get trustRegNo;

  /// No description provided for @trustPan.
  ///
  /// In en, this message translates to:
  /// **'Trust PAN'**
  String get trustPan;

  /// No description provided for @eightyGNo.
  ///
  /// In en, this message translates to:
  /// **'80G No.'**
  String get eightyGNo;

  /// No description provided for @eightyGNote.
  ///
  /// In en, this message translates to:
  /// **'Donation eligible for deduction under section 80G of the Income Tax Act.'**
  String get eightyGNote;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @templeManagement.
  ///
  /// In en, this message translates to:
  /// **'Temple Management'**
  String get templeManagement;

  /// No description provided for @templeManagementHint.
  ///
  /// In en, this message translates to:
  /// **'For temple staff – admin login'**
  String get templeManagementHint;

  /// No description provided for @adminUnavailableDemo.
  ///
  /// In en, this message translates to:
  /// **'The admin panel is available once the app is connected to the temple server.'**
  String get adminUnavailableDemo;

  /// No description provided for @devoteeGuestNote.
  ///
  /// In en, this message translates to:
  /// **'Your seva bookings, receipts and reminders are saved on this phone. Add your name and mobile so the temple can recognise you.'**
  String get devoteeGuestNote;

  /// No description provided for @bannerFormat.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get bannerFormat;

  /// No description provided for @formatSquare.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get formatSquare;

  /// No description provided for @formatStory.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get formatStory;

  /// No description provided for @formatLandscape.
  ///
  /// In en, this message translates to:
  /// **'Wide'**
  String get formatLandscape;

  /// No description provided for @bannerSender.
  ///
  /// In en, this message translates to:
  /// **'Greeted by (your name)'**
  String get bannerSender;

  /// No description provided for @senderPhoto.
  ///
  /// In en, this message translates to:
  /// **'Your photo'**
  String get senderPhoto;

  /// No description provided for @bannerDesign.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get bannerDesign;

  /// No description provided for @payByUpi.
  ///
  /// In en, this message translates to:
  /// **'Pay by UPI'**
  String get payByUpi;

  /// No description provided for @upiPayTo.
  ///
  /// In en, this message translates to:
  /// **'Pay to'**
  String get upiPayTo;

  /// No description provided for @upiOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Pay with a UPI app'**
  String get upiOpenApp;

  /// No description provided for @upiScanQr.
  ///
  /// In en, this message translates to:
  /// **'Or scan this QR with any UPI app (GPay, PhonePe, Paytm, BHIM)'**
  String get upiScanQr;

  /// No description provided for @upiShareQr.
  ///
  /// In en, this message translates to:
  /// **'Share / save QR'**
  String get upiShareQr;

  /// No description provided for @upiCopied.
  ///
  /// In en, this message translates to:
  /// **'UPI ID copied'**
  String get upiCopied;

  /// No description provided for @upiNoApp.
  ///
  /// In en, this message translates to:
  /// **'No UPI app found on this phone. Scan the QR from another phone.'**
  String get upiNoApp;

  /// No description provided for @upiUtrLabel.
  ///
  /// In en, this message translates to:
  /// **'UTR / UPI Ref No. (12 digits)'**
  String get upiUtrLabel;

  /// No description provided for @upiUtrHelp.
  ///
  /// In en, this message translates to:
  /// **'After paying, open the payment in your UPI app: GPay – \"UPI transaction ID\", PhonePe – \"UTR\", Paytm – \"UPI Ref No.\"'**
  String get upiUtrHelp;

  /// No description provided for @upiUtrInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the 12-digit UTR number'**
  String get upiUtrInvalid;

  /// No description provided for @upiSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for verification'**
  String get upiSubmit;

  /// No description provided for @upiCheckAmount.
  ///
  /// In en, this message translates to:
  /// **'Before paying, check the amount and the temple name in your UPI app.'**
  String get upiCheckAmount;

  /// No description provided for @upiLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without the UTR?'**
  String get upiLeaveTitle;

  /// No description provided for @upiLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'If you have already paid, enter the UTR number. Without it the temple cannot match your payment.'**
  String get upiLeaveBody;

  /// No description provided for @upiLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get upiLeave;

  /// No description provided for @upiStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get upiStay;

  /// No description provided for @upiSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment sent for verification'**
  String get upiSubmittedTitle;

  /// No description provided for @upiSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'The temple office will check your payment in the bank statement and then issue the receipt. You will get a notification and it will appear in My receipts.'**
  String get upiSubmittedBody;

  /// No description provided for @upiPending.
  ///
  /// In en, this message translates to:
  /// **'Being verified'**
  String get upiPending;

  /// No description provided for @upiRejected.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get upiRejected;

  /// No description provided for @upiPayments.
  ///
  /// In en, this message translates to:
  /// **'UPI payments'**
  String get upiPayments;

  /// No description provided for @upiStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Pay'**
  String get upiStep1;

  /// No description provided for @upiStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Enter the UTR number'**
  String get upiStep2;

  /// No description provided for @upiReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get upiReference;

  /// No description provided for @upiSecureNote.
  ///
  /// In en, this message translates to:
  /// **'Pay directly to the temple by UPI (GPay, PhonePe, Paytm, BHIM)'**
  String get upiSecureNote;

  /// No description provided for @latestDarshan.
  ///
  /// In en, this message translates to:
  /// **'Latest darshan'**
  String get latestDarshan;

  /// No description provided for @dailyQuoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s thought'**
  String get dailyQuoteTitle;

  /// No description provided for @dontShowDaily.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show daily'**
  String get dontShowDaily;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @dailyQuotePopup.
  ///
  /// In en, this message translates to:
  /// **'Daily thought on opening'**
  String get dailyQuotePopup;

  /// No description provided for @dailyQuotePopupHint.
  ///
  /// In en, this message translates to:
  /// **'Show today\'s suvichar once a day when the app opens'**
  String get dailyQuotePopupHint;

  /// No description provided for @makeBanner.
  ///
  /// In en, this message translates to:
  /// **'Make banner'**
  String get makeBanner;

  /// No description provided for @headlineFontLabel.
  ///
  /// In en, this message translates to:
  /// **'Headline lettering'**
  String get headlineFontLabel;

  /// No description provided for @bodyFontLabel.
  ///
  /// In en, this message translates to:
  /// **'Message lettering'**
  String get bodyFontLabel;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @festivalsAndTithis.
  ///
  /// In en, this message translates to:
  /// **'Festivals & tithis'**
  String get festivalsAndTithis;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @kindFestival.
  ///
  /// In en, this message translates to:
  /// **'Festivals'**
  String get kindFestival;

  /// No description provided for @kindJayanti.
  ///
  /// In en, this message translates to:
  /// **'Jayanti'**
  String get kindJayanti;

  /// No description provided for @kindVrat.
  ///
  /// In en, this message translates to:
  /// **'Vrat / tithi'**
  String get kindVrat;

  /// No description provided for @kindNational.
  ///
  /// In en, this message translates to:
  /// **'National days'**
  String get kindNational;

  /// No description provided for @makeFestivalBanner.
  ///
  /// In en, this message translates to:
  /// **'Make greeting banner'**
  String get makeFestivalBanner;

  /// No description provided for @todayIs.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayIs;

  /// No description provided for @upcomingFestival.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get upcomingFestival;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'in {n} days'**
  String inDays(int n);

  /// No description provided for @festivalCalendar.
  ///
  /// In en, this message translates to:
  /// **'Festival calendar'**
  String get festivalCalendar;

  /// No description provided for @festivalDateNote.
  ///
  /// In en, this message translates to:
  /// **'Dates are computed for Rundhati by Panchang rules; the temple office can correct any date.'**
  String get festivalDateNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
