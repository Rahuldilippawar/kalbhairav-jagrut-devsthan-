/// Firestore collection names – single source of truth for both apps.
abstract final class Col {
  static const users = 'users';
  static const familyMembers = 'family_members';

  static const events = 'events';
  static const eventCategories = 'event_categories';
  static const eventSchedules = 'event_schedules';
  static const eventMedia = 'event_media';
  static const eventReminders = 'event_reminders';

  static const sevas = 'sevas';
  static const sevaBookings = 'seva_bookings';
  static const sevaSlotCounts = 'seva_slot_counts';

  static const donations = 'donations';
  static const payments = 'payments';
  static const receipts = 'receipts';

  /// UPI transaction references already used (Cloud Functions only).
  static const upiUtrs = 'upi_utrs';

  static const dailyQuotes = 'daily_quotes';
  static const dailyGreetings = 'daily_greetings';
  static const tithiContent = 'tithi_content';

  /// Admin corrections to computed festival dates (`<festivalId>_<year>`).
  static const festivalDates = 'festival_dates';
  static const mantras = 'mantras';
  static const publicGreetings = 'public_greetings';

  static const bannerTemplates = 'banner_templates';
  static const generatedBanners = 'generated_banners';
  static const homeBanners = 'home_banners';

  static const announcements = 'announcements';
  static const notifications = 'notifications';

  static const gallery = 'gallery';
  static const deities = 'deities';
  static const parampara = 'gadhipati_parampara';
  static const darshanPhotos = 'darshan_photos';

  /// Shishya parivar access requests, keyed by uid.
  static const shishyas = 'shishyas';

  /// Guru Gyan lessons (approved shishyas only).
  static const guruGyan = 'guru_gyan';
  static const videos = 'videos';

  static const templeInfo = 'temple_info';
  static const darshanSchedule = 'darshan_schedule';
  static const liveDarshan = 'live_darshan';

  static const adminUsers = 'admin_users';
  static const auditLogs = 'audit_logs';
  static const appSettings = 'app_settings';
  static const counters = 'counters';

  /// Singleton document id used by temple_info, live_darshan, app_settings.
  static const mainDoc = 'main';
  static const currentDoc = 'current';
}
