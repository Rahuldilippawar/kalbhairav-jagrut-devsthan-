import 'package:kjd_core/kjd_core.dart';

enum FieldType { text, multiline, integer, decimal, money, boolean, date, dateTime, time, select, tags, intList, colors, image, url }

/// One editable field of a document. [key] may be a dotted path into a
/// nested map (e.g. `dindi.startPoint`).
class FieldSpec {
  const FieldSpec(
    this.key,
    this.label, {
    this.type = FieldType.text,
    this.required = false,
    this.options = const [],
    this.help,
    this.defaultValue,
  });

  final String key;
  final String label;
  final FieldType type;
  final bool required;

  /// For [FieldType.select]: (value, label) pairs.
  final List<(String, String)> options;
  final String? help;
  final Object? defaultValue;
}

/// Describes how a collection is listed and edited in the CMS.
class CollectionSpec {
  const CollectionSpec({
    required this.collection,
    required this.title,
    required this.module,
    required this.fields,
    required this.columns,
    this.orderBy,
    this.descending = false,
    this.docIdField,
    this.singletonId,
    this.searchFields = const [],
    this.readOnly = false,
    this.beforeSave,
  });

  final String collection;
  final String title;
  final AdminModule module;
  final List<FieldSpec> fields;

  /// Keys shown as table columns.
  final List<String> columns;
  final String? orderBy;
  final bool descending;

  /// When set, new documents use this field's value as their id (e.g. tithi
  /// documents are keyed by date).
  final String? docIdField;

  /// Edit a single document (temple_info/main, …) instead of a list.
  final String? singletonId;
  final List<String> searchFields;
  final bool readOnly;

  /// Last chance to adjust data written by the admin form.
  final Map<String, dynamic> Function(Map<String, dynamic> data)? beforeSave;

  FieldSpec? field(String key) => fields.where((f) => f.key == key).firstOrNull;
}

List<(String, String)> _enum(List<Enum> values) => [for (final v in values) (v.name, v.name)];
const _contentStatus = [('draft', 'Draft'), ('published', 'Published'), ('archived', 'Archived')];

abstract final class Specs {
  static final templeInfo = CollectionSpec(
    collection: Col.templeInfo,
    singletonId: Col.mainDoc,
    title: 'Temple Information',
    module: AdminModule.temple,
    columns: const ['nameMr'],
    fields: const [
      FieldSpec('name', 'Name (English)', required: true),
      FieldSpec('nameMr', 'Name (Marathi)', required: true),
      FieldSpec('location', 'Location'),
      FieldSpec('subtitle', 'Subtitle (e.g. साती राणा मढी)'),
      FieldSpec('tagline', 'Tagline'),
      FieldSpec('address', 'Address', type: FieldType.multiline),
      FieldSpec('about', 'About', type: FieldType.multiline),
      FieldSpec('history', 'History', type: FieldType.multiline),
      FieldSpec('importance', 'Importance', type: FieldType.multiline),
      FieldSpec('tradition', 'Tradition', type: FieldType.multiline),
      FieldSpec('parampara', 'Gadi / Parampara', type: FieldType.multiline),
      FieldSpec('phone', 'Phone (+91…)'),
      FieldSpec('whatsapp', 'WhatsApp (+91…)'),
      FieldSpec('email', 'Email'),
      FieldSpec('latitude', 'Latitude', type: FieldType.decimal, help: 'Decimal degrees'),
      FieldSpec('longitude', 'Longitude', type: FieldType.decimal),
      FieldSpec('mapUrl', 'Google Maps link', type: FieldType.url),
      FieldSpec('coverImageUrl', 'Cover image', type: FieldType.image),
      FieldSpec('closureNotice', 'Temporary closure notice', type: FieldType.multiline, help: 'Leave empty when the temple is open'),
    ],
  );

  static final settings = CollectionSpec(
    collection: Col.appSettings,
    singletonId: Col.mainDoc,
    title: 'App Settings',
    module: AdminModule.settings,
    columns: const [],
    fields: const [
      FieldSpec('razorpayKeyId', 'Razorpay key id (publishable)'),
      FieldSpec('donationCategories', 'Donation categories', type: FieldType.tags),
      FieldSpec('donationPresetsRupees', 'Donation presets (₹)', type: FieldType.intList),
      FieldSpec('minDonationRupees', 'Minimum donation (₹)', type: FieldType.integer),
      FieldSpec('maxDonationRupees', 'Maximum online donation (₹)', type: FieldType.integer),
      FieldSpec('bookingWindowDays', 'Seva booking window (days)', type: FieldType.integer),
      FieldSpec('maintenanceMode', 'Maintenance mode', type: FieldType.boolean),
      FieldSpec('maintenanceMessage', 'Maintenance message', type: FieldType.multiline),
    ],
  );

  static final live = CollectionSpec(
    collection: Col.liveDarshan,
    singletonId: Col.currentDoc,
    title: 'Live Darshan',
    module: AdminModule.live,
    columns: const [],
    fields: const [
      FieldSpec('isLive', 'Live now', type: FieldType.boolean),
      FieldSpec('title', 'Title'),
      FieldSpec('url', 'YouTube Live URL', type: FieldType.url),
      FieldSpec('thumbnailUrl', 'Thumbnail', type: FieldType.image),
    ],
  );

  static final darshan = CollectionSpec(
    collection: Col.darshanSchedule,
    title: 'Darshan & Aarti Timings',
    module: AdminModule.darshan,
    orderBy: 'order',
    columns: const ['title', 'type', 'startTime', 'endTime', 'active'],
    fields: [
      const FieldSpec('title', 'Title', required: true),
      FieldSpec('type', 'Type', type: FieldType.select, options: _enum(DarshanType.values), defaultValue: 'morning'),
      const FieldSpec('startTime', 'Start', type: FieldType.time, required: true),
      const FieldSpec('endTime', 'End', type: FieldType.time),
      const FieldSpec('note', 'Note'),
      const FieldSpec('order', 'Order', type: FieldType.integer, defaultValue: 0),
      const FieldSpec('active', 'Active', type: FieldType.boolean, defaultValue: true),
    ],
  );

  static final homeBanners = CollectionSpec(
    collection: Col.homeBanners,
    title: 'Home Hero Banners',
    module: AdminModule.content,
    orderBy: 'order',
    columns: const ['title', 'subtitle', 'eventId', 'active'],
    fields: const [
      FieldSpec('title', 'Title', required: true),
      FieldSpec('subtitle', 'Subtitle'),
      FieldSpec('imageUrl', 'Image', type: FieldType.image),
      FieldSpec('eventId', 'Linked event id'),
      FieldSpec('link', 'In-app link (e.g. /donate)'),
      FieldSpec('order', 'Order', type: FieldType.integer, defaultValue: 0),
      FieldSpec('active', 'Active', type: FieldType.boolean, defaultValue: true),
    ],
  );

  static final categories = CollectionSpec(
    collection: Col.eventCategories,
    title: 'Event Categories',
    module: AdminModule.events,
    orderBy: 'order',
    columns: const ['icon', 'name', 'nameEn', 'active'],
    fields: const [
      FieldSpec('name', 'Name (Marathi)', required: true),
      FieldSpec('nameEn', 'Name (English)'),
      FieldSpec('icon', 'Icon (emoji)', defaultValue: '🎉'),
      FieldSpec('order', 'Order', type: FieldType.integer, defaultValue: 0),
      FieldSpec('active', 'Active', type: FieldType.boolean, defaultValue: true),
    ],
  );

  static CollectionSpec events(List<EventCategory> cats) => CollectionSpec(
        collection: Col.events,
        title: 'Events',
        module: AdminModule.events,
        orderBy: 'startDate',
        descending: true,
        searchFields: const ['title', 'location'],
        columns: const ['title', 'categoryId', 'year', 'startDate', 'status', 'featured'],
        fields: [
          const FieldSpec('title', 'Title (e.g. नवरात्र उत्सव 2026)', required: true),
          FieldSpec('categoryId', 'Category', type: FieldType.select, required: true, options: [
            for (final c in cats) (c.id, '${c.icon} ${c.name}'),
          ]),
          const FieldSpec('year', 'Year', type: FieldType.integer, required: true),
          const FieldSpec('startDate', 'Start date', type: FieldType.date, required: true),
          const FieldSpec('endDate', 'End date', type: FieldType.date),
          FieldSpec('status', 'Status', type: FieldType.select, options: _enum(EventStatus.values), defaultValue: 'draft'),
          const FieldSpec('featured', 'Featured', type: FieldType.boolean),
          const FieldSpec('bannerUrl', 'Banner', type: FieldType.image),
          const FieldSpec('description', 'Description', type: FieldType.multiline),
          const FieldSpec('religiousInfo', 'Religious information', type: FieldType.multiline),
          const FieldSpec('highlights', 'Highlights (गुरु पूजन, आरती …)', type: FieldType.tags),
          const FieldSpec('location', 'Location'),
          const FieldSpec('mapUrl', 'Map link', type: FieldType.url),
          const FieldSpec('latitude', 'Latitude', type: FieldType.decimal),
          const FieldSpec('longitude', 'Longitude', type: FieldType.decimal),
          const FieldSpec('liveUrl', 'Live link (YouTube)', type: FieldType.url),
          const FieldSpec('dindi.startPoint', 'Dindi: starting point'),
          const FieldSpec('dindi.destination', 'Dindi: destination'),
          const FieldSpec('dindi.instructions', 'Dindi: important instructions', type: FieldType.multiline),
          const FieldSpec('dindi.contactName', 'Dindi: contact name'),
          const FieldSpec('dindi.contactPhone', 'Dindi: contact phone'),
          const FieldSpec('dindi.routeMapUrl', 'Dindi: route map link', type: FieldType.url),
          const FieldSpec('dindi.destinationLat', 'Dindi: destination latitude', type: FieldType.decimal),
          const FieldSpec('dindi.destinationLng', 'Dindi: destination longitude', type: FieldType.decimal),
        ],
      );

  static final schedule = CollectionSpec(
    collection: Col.eventSchedules,
    title: 'Schedule / Route',
    module: AdminModule.events,
    orderBy: 'order',
    columns: const ['dayNumber', 'date', 'time', 'title', 'location', 'mukkaam'],
    fields: const [
      FieldSpec('dayNumber', 'Day number', type: FieldType.integer),
      FieldSpec('date', 'Date', type: FieldType.date),
      FieldSpec('time', 'Time', type: FieldType.time),
      FieldSpec('title', 'Title', required: true),
      FieldSpec('description', 'Description', type: FieldType.multiline),
      FieldSpec('location', 'Location'),
      FieldSpec('guest', 'Guest / Speaker'),
      FieldSpec('departureTime', 'Dindi: departure time', type: FieldType.time),
      FieldSpec('mukkaam', 'Dindi: mukkaam (night halt)'),
      FieldSpec('latitude', 'Route map: latitude of location', type: FieldType.decimal, help: 'Long-press the place in Google Maps to copy its coordinates'),
      FieldSpec('longitude', 'Route map: longitude of location', type: FieldType.decimal),
      FieldSpec('imageUrl', 'Image', type: FieldType.image),
      FieldSpec('order', 'Order within day', type: FieldType.integer, defaultValue: 0),
    ],
  );

  static final media = CollectionSpec(
    collection: Col.eventMedia,
    title: 'Photos & Videos',
    module: AdminModule.events,
    orderBy: 'order',
    columns: const ['type', 'album', 'caption', 'url'],
    fields: [
      FieldSpec('type', 'Type', type: FieldType.select, options: _enum(MediaType.values), defaultValue: 'photo'),
      const FieldSpec('url', 'Photo / video URL', type: FieldType.image, required: true, help: 'Upload a photo or paste a YouTube link'),
      const FieldSpec('album', 'Album (e.g. Day 1)'),
      const FieldSpec('caption', 'Caption'),
      const FieldSpec('order', 'Order', type: FieldType.integer, defaultValue: 0),
    ],
  );

  static final sevas = CollectionSpec(
    collection: Col.sevas,
    title: 'Seva',
    module: AdminModule.seva,
    orderBy: 'order',
    columns: const ['name', 'pricePaise', 'timeSlots', 'capacityPerSlot', 'active'],
    fields: const [
      FieldSpec('name', 'Name', required: true),
      FieldSpec('description', 'Description', type: FieldType.multiline),
      FieldSpec('pricePaise', 'Price (₹)', type: FieldType.money, required: true),
      FieldSpec('timeSlots', 'Time slots (HH:mm)', type: FieldType.tags, help: 'e.g. 06:30, 08:00'),
      FieldSpec('capacityPerSlot', 'Capacity per slot', type: FieldType.integer, defaultValue: 10),
      FieldSpec('availableWeekdays', 'Weekdays (1=Mon … 7=Sun)', type: FieldType.intList, defaultValue: [1, 2, 3, 4, 5, 6, 7]),
      FieldSpec('imageUrl', 'Image', type: FieldType.image),
      FieldSpec('order', 'Order', type: FieldType.integer, defaultValue: 0),
      FieldSpec('active', 'Active', type: FieldType.boolean, defaultValue: true),
    ],
  );

  static final greetings = CollectionSpec(
    collection: Col.dailyGreetings,
    title: 'Daily Subhechha',
    module: AdminModule.content,
    orderBy: 'date',
    descending: true,
    columns: const ['date', 'category', 'title', 'status'],
    searchFields: const ['title', 'message'],
    fields: [
      const FieldSpec('date', 'Date (yyyy-MM-dd)', required: true),
      FieldSpec('category', 'Category', type: FieldType.select, options: [for (final c in DailyGreeting.categories) (c, c)], defaultValue: 'शुभ प्रभात'),
      const FieldSpec('title', 'Title', required: true, defaultValue: '🌅 शुभ प्रभात 🙏'),
      const FieldSpec('message', 'Message', type: FieldType.multiline, required: true),
      const FieldSpec('imageUrl', 'Image', type: FieldType.image),
      const FieldSpec('status', 'Status', type: FieldType.select, options: _contentStatus, defaultValue: 'published'),
    ],
  );

  static final quotes = CollectionSpec(
    collection: Col.dailyQuotes,
    title: 'Quote Library',
    module: AdminModule.content,
    columns: const ['text', 'category', 'author', 'scheduledDate', 'status'],
    searchFields: const ['text', 'author'],
    fields: [
      const FieldSpec('text', 'Quote', type: FieldType.multiline, required: true),
      FieldSpec('category', 'Category', type: FieldType.select, options: [for (final c in DailyQuote.categories) (c, c)], defaultValue: 'भक्ती'),
      const FieldSpec('author', 'Author'),
      const FieldSpec('language', 'Language', type: FieldType.select, options: [('mr', 'मराठी'), ('en', 'English'), ('hi', 'हिंदी')], defaultValue: 'mr'),
      const FieldSpec('imageUrl', 'Image', type: FieldType.image),
      const FieldSpec('scheduledDate', 'Show on date (yyyy-MM-dd, optional)'),
      const FieldSpec('status', 'Status', type: FieldType.select, options: _contentStatus, defaultValue: 'published'),
    ],
  );

  static final tithi = CollectionSpec(
    collection: Col.tithiContent,
    title: "Today's Tithi (Panchang)",
    module: AdminModule.content,
    docIdField: 'date',
    columns: const ['date', 'vaar', 'tithi', 'paksha', 'masa', 'nakshatra', 'specialDay', 'source'],
    orderBy: 'date',
    descending: true,
    // Anything an admin saves by hand is protected from the auto-generator.
    beforeSave: (d) => {...d, 'source': 'manual', 'manualOverride': true},
    fields: const [
      FieldSpec('date', 'Date (yyyy-MM-dd)', required: true, help: 'Used as the document id'),
      FieldSpec('vaar', 'वार'),
      FieldSpec('tithi', 'तिथी', required: true),
      FieldSpec('paksha', 'पक्ष'),
      FieldSpec('masa', 'मास'),
      FieldSpec('nakshatra', 'नक्षत्र'),
      FieldSpec('yoga', 'योग'),
      FieldSpec('karana', 'करण'),
      FieldSpec('sunrise', 'सूर्योदय', type: FieldType.time),
      FieldSpec('sunset', 'सूर्यास्त', type: FieldType.time),
      FieldSpec('specialDay', 'Special day'),
      FieldSpec('source', 'Source', type: FieldType.select, options: [('manual', 'Manual'), ('api', 'Panchang API'), ('demo', 'Demo')], defaultValue: 'manual'),
      FieldSpec('manualOverride', 'Protect from API import', type: FieldType.boolean, defaultValue: true),
    ],
  );

  static final announcements = CollectionSpec(
    collection: Col.announcements,
    title: 'Announcements',
    module: AdminModule.content,
    orderBy: 'publishAt',
    descending: true,
    columns: const ['title', 'urgent', 'status', 'publishAt', 'expireAt'],
    searchFields: const ['title', 'body'],
    fields: const [
      FieldSpec('title', 'Title', required: true),
      FieldSpec('body', 'Message', type: FieldType.multiline, required: true),
      FieldSpec('urgent', 'Urgent', type: FieldType.boolean),
      FieldSpec('status', 'Status', type: FieldType.select, options: _contentStatus, defaultValue: 'draft'),
      FieldSpec('publishAt', 'Publish at', type: FieldType.dateTime),
      FieldSpec('expireAt', 'Expire at', type: FieldType.dateTime),
      FieldSpec('imageUrl', 'Image', type: FieldType.image),
    ],
  );

  static final bannerTemplates = CollectionSpec(
    collection: Col.bannerTemplates,
    title: 'Banner Templates',
    module: AdminModule.banners,
    orderBy: 'order',
    columns: const ['name', 'category', 'headline', 'active'],
    fields: [
      const FieldSpec('name', 'Name', required: true),
      FieldSpec('category', 'Category', type: FieldType.select, options: [for (final c in BannerCategory.values) (c.name, c.labelMr)], defaultValue: 'festival'),
      const FieldSpec('headline', 'Headline'),
      const FieldSpec('defaultMessage', 'Default message ({name}, {date})', type: FieldType.multiline),
      const FieldSpec('gradient', 'Background gradient (hex colours)', type: FieldType.colors, defaultValue: [0xFF8E0E00, 0xFFE65100]),
      const FieldSpec('textColor', 'Text colour (hex)', type: FieldType.colors, defaultValue: 0xFFFFFFFF),
      const FieldSpec('accentColor', 'Accent colour (hex)', type: FieldType.colors, defaultValue: 0xFFFFD54F),
      const FieldSpec('backgroundUrl', 'Background image', type: FieldType.image),
      const FieldSpec('footer', 'Footer', defaultValue: 'श्री काळभैरव जागृत देवस्थान, रुंधाटी'),
      const FieldSpec('order', 'Order', type: FieldType.integer, defaultValue: 0),
      const FieldSpec('active', 'Active', type: FieldType.boolean, defaultValue: true),
    ],
  );

  static final gallery = CollectionSpec(
    collection: Col.gallery,
    title: 'Temple Gallery',
    module: AdminModule.gallery,
    orderBy: 'createdAt',
    descending: true,
    columns: const ['url', 'category', 'caption', 'year'],
    searchFields: const ['caption'],
    fields: [
      const FieldSpec('url', 'Photo', type: FieldType.image, required: true),
      FieldSpec('category', 'Category', type: FieldType.select, options: [for (final c in GalleryItem.categories) (c, c)], defaultValue: 'Temple'),
      const FieldSpec('caption', 'Caption'),
      const FieldSpec('year', 'Year', type: FieldType.integer),
    ],
  );

  static final videos = CollectionSpec(
    collection: Col.videos,
    title: 'Videos',
    module: AdminModule.gallery,
    orderBy: 'createdAt',
    descending: true,
    columns: const ['title', 'category', 'eventId', 'isLive'],
    searchFields: const ['title'],
    fields: const [
      FieldSpec('title', 'Title', required: true),
      FieldSpec('url', 'YouTube URL', type: FieldType.url, required: true),
      FieldSpec('category', 'Category', defaultValue: 'Temple'),
      FieldSpec('eventId', 'Event id (optional)'),
      FieldSpec('isLive', 'Live stream', type: FieldType.boolean),
    ],
  );
}
