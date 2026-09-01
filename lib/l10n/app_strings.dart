import 'package:flutter/material.dart';

/// Supported application languages
enum AppLanguage { english, amharic }

/// Global state notifier for app language
class LanguageController extends ChangeNotifier {
  static final LanguageController instance = LanguageController._();
  LanguageController._();

  AppLanguage _currentLanguage = AppLanguage.english;

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isAmharic => _currentLanguage == AppLanguage.amharic;
  Locale get locale => _currentLanguage == AppLanguage.amharic
      ? const Locale('am', 'ET')
      : const Locale('en', 'US');

  void setLanguage(AppLanguage language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      notifyListeners();
    }
  }

  void toggleLanguage() {
    setLanguage(isAmharic ? AppLanguage.english : AppLanguage.amharic);
  }
}

/// Centralized localization dictionary (English & Amharic አማርኛ)
class AppStrings {
  static bool get _isAm => LanguageController.instance.isAmharic;

  // App Title & Taglines
  static String get appName => _isAm ? 'ፓርክኢዝ' : 'ParkEase';
  static String get tagline => _isAm ? 'ፈልግ • ያዝ • አቁም' : 'Find • Book • Park';

  // Navigation
  static String get exploreMap => _isAm ? 'ካርታ ፈልግ' : 'Explore Map';
  static String get bookings => _isAm ? 'የተያዙ ቦታዎች' : 'Bookings';
  static String get profile => _isAm ? 'መገለጫ' : 'Profile';

  // Onboarding
  static String get onboardingTitle1 => _isAm ? 'በአዲስ አበባ እና በዓለም ዙሪያ ፓርኪንግ ያግኙ' : 'Find Parking in Addis & Worldwide';
  static String get onboardingDesc1 => _isAm ? 'የቀጥታ ካርታ በአቅራቢያዎ ያሉ ክፍት የመኪና ማቆሚያ ቦታዎችን ያሳይዎታል።' : 'Real-time availability maps guide you to the closest open spots.';
  static String get onboardingTitle2 => _isAm ? 'በቴሌብር እና በሲቢኢ ብር ይክፈሉ' : 'Book with Telebirr & CBE Birr';
  static String get onboardingDesc2 => _isAm ? 'በቀላሉ እና በፍጥነት በሞባይል ክፍያ ቦታዎን ያስይዙ።' : 'Secure your spot instantly using Telebirr or CBE Birr digital payments.';
  static String get onboardingTitle3 => _isAm ? 'በዲጂታል QR ፓስ ይግቡ' : 'Scan & Park Seamlessly';
  static String get onboardingDesc3 => _isAm ? 'ያለ ወረቀት ቲኬት በስልክዎ የQR ኮድ በቀላሉ ወደ ማቆሚያው ይግቡ።' : 'Breeze through gate barriers using your secure digital QR pass.';
  static String get skip => _isAm ? 'ዝለል' : 'Skip';
  static String get next => _isAm ? 'ቀጣይ' : 'Next';
  static String get getStarted => _isAm ? 'ጀምር' : 'Get Started';

  // Auth / Login
  static String get loginTitle => _isAm ? 'ስልክ ቁጥርዎን ያስገቡ' : 'Enter your phone number';
  static String get loginSubtitle => _isAm ? 'ለመቀጠል ስልክ ቁጥርዎን ያስገቡ' : 'Enter your phone number to continue';
  static String get continueBtn => _isAm ? 'ቀጥል' : 'Continue';
  static String get orLoginWith => _isAm ? 'ወይም በዚህ ይግቡ' : 'OR LOGIN WITH';
  static String get continueWithTelebirr => _isAm ? 'በቴሌብር ቀጥል' : 'Continue with Telebirr';
  static String get continueWithGoogle => _isAm ? 'በጉግል ቀጥል' : 'Continue with Google';
  static String get continueWithApple => _isAm ? 'በአፕል ቀጥል' : 'Continue with Apple';

  // Map & Discovery
  static String get searchParking => _isAm ? 'በአቅራቢያዎ የመኪና ማቆሚያ ይፈልጉ...' : 'Search parking near you...';
  static String get nearbyParking => _isAm ? 'በአቅራቢያ ያሉ ማቆሚያዎች' : 'Nearby Parking';
  static String get all => _isAm ? 'ሁሉም' : 'All';
  static String get government => _isAm ? 'የመንግስት' : 'Government';
  static String get commercial => _isAm ? 'የንግድ' : 'Commercial';
  static String get privateHost => _isAm ? 'የግል አከራይ' : 'Private Host';
  static String get covered => _isAm ? 'የተሸፈነ' : 'Covered';
  static String get ev => _isAm ? 'ኤሌክትሪክ (EV)' : 'EV Charging';

  // Availability Status
  static String get available => _isAm ? 'ክፍት ቦታ አለ' : 'AVAILABLE';
  static String get fillingFast => _isAm ? 'እየሞላ ነው' : 'FILLING FAST';
  static String get full => _isAm ? 'ሙሉ ነው' : 'FULL';

  // Spot Details & Booking
  static String get price => _isAm ? 'ዋጋ' : 'Price';
  static String get distance => _isAm ? 'ርቀት' : 'Distance';
  static String get availability => _isAm ? 'ተገኝነት' : 'Availability';
  static String get rating => _isAm ? 'ደረጃ' : 'Rating';
  static String get amenities => _isAm ? 'አገልግሎቶች' : 'Amenities';
  static String get reserveNow => _isAm ? 'አሁን ይያዙ' : 'Reserve Now';
  static String get spotFull => _isAm ? 'ቦታው ሙሉ ነው — ክፍት ቦታ የለም' : 'Spot Full — No Availability';
  static String get hostedBy => _isAm ? 'አከራይ፦' : 'Hosted by';

  // Booking Review
  static String get reviewBooking => _isAm ? 'የቦታ ማስያዣ ዝርዝር' : 'Review Booking';
  static String get reservationDetails => _isAm ? 'የማስያዣ ዝርዝር' : 'Reservation Details';
  static String get startTime => _isAm ? 'መጀመሪያ ሰዓት' : 'Start Time';
  static String get duration => _isAm ? 'የቆይታ ጊዜ' : 'Duration';
  static String get endTime => _isAm ? 'የማብቂያ ሰዓት' : 'End Time';
  static String get selectVehicle => _isAm ? 'ተሽከርካሪ ይምረጡ' : 'Select Vehicle';
  static String get paymentMethod => _isAm ? 'የክፍያ ዘዴ' : 'Payment Method';
  static String get paymentBreakdown => _isAm ? 'የክፍያ ዝርዝር' : 'Payment Breakdown';
  static String get parkingFee => _isAm ? 'የማቆሚያ ክፍያ' : 'Parking Fee';
  static String get serviceFee => _isAm ? 'የአገልግሎት ክፍያ' : 'Service Fee';
  static String get cityTax => _isAm ? 'የከተማ ታክስ' : 'City Tax';
  static String get totalAmount => _isAm ? 'ጠቅላላ ክፍያ' : 'Total Amount';
  static String get payAndReserve => _isAm ? 'ክፈል እና አስይዝ' : 'Pay & Reserve';

  // Profile & Host
  static String get myProfile => _isAm ? 'የእኔ መገለጫ' : 'My Profile';
  static String get myVehicles => _isAm ? 'የእኔ ተሽከርካሪዎች' : 'MY VEHICLES';
  static String get addVehicle => _isAm ? 'ተሽከርካሪ ጨምር' : 'Add Vehicle';
  static String get becomeHost => _isAm ? 'ቦታዎን አከራይተው ገቢ ያግኙ' : 'Become a Host & Earn';
  static String get becomeHostDesc => _isAm ? 'ነፃ የመኪና ማቆሚያ ቦታዎን በመመዝገብ ከእያንዳንዱ ማስያዣ ገቢ ያግኙ።' : 'List your free parking space and earn money from every booking.';
  static String get settings => _isAm ? 'ቅንብሮች' : 'SETTINGS';
  static String get languageSetting => _isAm ? 'ቋንቋ (Language)' : 'Language (ቋንቋ)';
  static String get notifications => _isAm ? 'ማሳወቂያዎች' : 'Notifications & Alerts';
  static String get helpSupport => _isAm ? 'እርዳታ እና ድጋፍ' : 'Help & Support';
  static String get aboutApp => _isAm ? 'ስለ ፓርክኢዝ' : 'About ParkEase';
  static String get signOut => _isAm ? 'ውጣ' : 'Sign Out';

  // Host Registration
  static String get listParkingSpace => _isAm ? 'የመኪና ማቆሚያ ቦታዎን ያስመዝግቡ' : 'List Your Parking Space';
  static String get yourLocation => _isAm ? 'አድራሻ' : 'Your Location';
  static String get spaceDetails => _isAm ? 'የቦታው ዝርዝር' : 'Space Details';
  static String get pricingAndHours => _isAm ? 'ዋጋ እና ሰዓት' : 'Pricing & Hours';
  static String get payoutDetails => _isAm ? 'የገቢ መቀበያ ዝርዝር' : 'Payout Details';
  static String get publishListing => _isAm ? '🚀 ቦታውን አስመዝግብ' : '🚀 Publish Listing';
}
