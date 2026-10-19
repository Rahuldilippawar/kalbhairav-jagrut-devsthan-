import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../schema.dart';
import '../widgets/crud.dart';
import '../widgets/library_loader.dart';
import 'audit_page.dart';
import 'bookings_page.dart';
import 'dashboard_page.dart';
import 'deities_page.dart';
import 'devotees_page.dart';
import 'events_page.dart';
import 'festival_page.dart';
import 'finance_pages.dart';
import 'guru_gyan_page.dart';
import 'media_pages.dart';
import 'notifications_page.dart';
import 'reports_page.dart';
import 'tithi_page.dart';
import 'upi_page.dart';
import 'users_page.dart';
import 'vanshavali_page.dart';

class NavItem {
  const NavItem(this.id, this.label, this.icon, this.module, this.builder, {this.group = ''});
  final String id;
  final String label;
  final IconData icon;
  final AdminModule module;
  final Widget Function() builder;
  final String group;
}

final List<NavItem> navItems = [
  NavItem('dashboard', 'Dashboard', Icons.dashboard_outlined, AdminModule.dashboard, () => const DashboardPage()),
  NavItem('checkin', 'QR Check-in', Icons.qr_code_scanner, AdminModule.checkIn, () => const CheckInPage(), group: 'Seva'),
  NavItem('bookings', 'Seva Bookings', Icons.event_seat_outlined, AdminModule.bookings, () => const BookingsPage(), group: 'Seva'),
  NavItem('sevas', 'Seva Catalogue', Icons.local_fire_department_outlined, AdminModule.seva, () => CollectionListPage(spec: Specs.sevas), group: 'Seva'),
  NavItem('events', 'Events & Archive', Icons.event_outlined, AdminModule.events, () => const EventsPage(), group: 'Utsav'),
  NavItem('calendar', 'Calendar Programmes', Icons.edit_calendar, AdminModule.events,
      () => CollectionListPage(
          spec: Specs.calendarEvents,
          subtitle: 'फक्त कार्यक्रमाचे नाव, तारीख आणि ठिकाण टाका – त्या दिवसाचे पंचांग ॲप आपोआप दाखवते.'),
      group: 'Utsav'),
  NavItem('categories', 'Event Categories', Icons.category_outlined, AdminModule.events, () => CollectionListPage(spec: Specs.categories), group: 'Utsav'),
  NavItem('donations', 'Donations', Icons.volunteer_activism_outlined, AdminModule.donations, () => const DonationsPage(), group: 'Finance'),
  NavItem('upi', 'UPI Verification', Icons.qr_code_2, AdminModule.payments, () => const UpiVerificationPage(), group: 'Finance'),
  NavItem('payments', 'Payments', Icons.payments_outlined, AdminModule.payments, () => const PaymentsPage(), group: 'Finance'),
  NavItem('reports', 'Reports', Icons.bar_chart, AdminModule.reports, () => const ReportsPage(), group: 'Finance'),
  NavItem('greetings', 'Daily Subhechha', Icons.wb_sunny_outlined, AdminModule.content, () => CollectionListPage(spec: Specs.greetings), group: 'Content'),
  NavItem('quotes', 'Quotes', Icons.format_quote, AdminModule.content, () => CollectionListPage(spec: Specs.quotes, header: LibraryLoader(collection: Col.dailyQuotes, items: suvicharLibraryDocs, label: 'Suvichar library')), group: 'Content'),
  NavItem('mantras', 'Mantras', Icons.self_improvement, AdminModule.content, () => CollectionListPage(spec: Specs.mantras, header: LibraryLoader(collection: Col.mantras, items: mantraLibraryDocs, label: 'Mantra library')), group: 'Content'),
  NavItem('festivals', 'Festival Calendar', Icons.celebration_outlined, AdminModule.content, () => const FestivalCalendarPage(), group: 'Content'),
  NavItem('tithi', 'Tithi / Panchang', Icons.calendar_month, AdminModule.content, () => const TithiPage(), group: 'Content'),
  NavItem('announcements', 'Announcements', Icons.campaign_outlined, AdminModule.content, () => CollectionListPage(spec: Specs.announcements), group: 'Content'),
  NavItem('home_banners', 'Home Banners', Icons.view_carousel_outlined, AdminModule.content, () => CollectionListPage(spec: Specs.homeBanners), group: 'Content'),
  NavItem('banner_templates', 'Banner Studio Templates', Icons.palette_outlined, AdminModule.banners, () => CollectionListPage(spec: Specs.bannerTemplates), group: 'Content'),
  NavItem('notifications', 'Notifications', Icons.notifications_outlined, AdminModule.notifications, () => const NotificationsPage(), group: 'Content'),
  NavItem('temple', 'Temple Info', Icons.temple_hindu_outlined, AdminModule.temple, () => SingletonPage(spec: Specs.templeInfo), group: 'Temple'),
  NavItem('deities', 'Deities (देवता)', Icons.self_improvement_outlined, AdminModule.temple, () => const DeitiesPage(), group: 'Temple'),
  NavItem('parampara', 'Gadhipati Parampara', Icons.account_tree_outlined, AdminModule.temple,
      () => CollectionListPage(spec: Specs.parampara, subtitle: 'One row per gadhipati, in order. Mark the present one as current.'), group: 'Temple'),
  NavItem('vanshavali', 'Gadhipati Vanshavali', Icons.family_restroom, AdminModule.temple, () => const VanshavaliPage(), group: 'Temple'),
  NavItem('darshan', 'Darshan Timings', Icons.access_time, AdminModule.darshan, () => CollectionListPage(spec: Specs.darshan), group: 'Temple'),
  NavItem('live', 'Live Darshan', Icons.live_tv, AdminModule.live, () => SingletonPage(spec: Specs.live), group: 'Temple'),
  NavItem('darshan_photos', "Today's Darshan", Icons.add_photo_alternate_outlined, AdminModule.live, () => const DarshanPhotosPage(), group: 'Temple'),
  NavItem('gallery', 'Gallery', Icons.photo_library_outlined, AdminModule.gallery, () => CollectionListPage(spec: Specs.gallery, header: const GalleryUpload()), group: 'Temple'),
  NavItem('videos', 'Videos', Icons.video_library_outlined, AdminModule.gallery, () => CollectionListPage(spec: Specs.videos), group: 'Temple'),
  NavItem('shishyas', 'Shishya Requests', Icons.how_to_reg_outlined, AdminModule.devotees, () => const ShishyasPage(), group: 'Guru Gyan'),
  NavItem('shishya_activity', 'Shishya Reading', Icons.insights_outlined, AdminModule.devotees, () => const ShishyaActivityPage(), group: 'Guru Gyan'),
  NavItem('shishya_chat', 'Shishya Chat', Icons.forum_outlined, AdminModule.devotees, () => const ShishyaChatModerationPage(), group: 'Guru Gyan'),
  NavItem('capture_alerts', 'Screenshot Alerts', Icons.screenshot_monitor_outlined, AdminModule.devotees, () => const CaptureAlertsPage(), group: 'Guru Gyan'),
  NavItem('guru_lessons', 'Lessons (पाठ)', Icons.menu_book_outlined, AdminModule.content, () => const GuruLessonsPage(), group: 'Guru Gyan'),
  NavItem('devotees', 'Devotees', Icons.people_outline, AdminModule.devotees, () => const DevoteesPage(), group: 'Admin'),
  NavItem('users', 'Admin Users & Roles', Icons.admin_panel_settings_outlined, AdminModule.users, () => const UsersPage(), group: 'Admin'),
  NavItem('audit', 'Audit Logs', Icons.history, AdminModule.auditLogs, () => const AuditPage(), group: 'Admin'),
  NavItem('settings', 'App Settings', Icons.settings_outlined, AdminModule.settings, () => SingletonPage(spec: Specs.settings), group: 'Admin'),
];

final selectedNavProvider = NotifierProvider<_Selected, String>(_Selected.new);

class _Selected extends Notifier<String> {
  @override
  String build() => 'dashboard';
  void select(String id) => state = id;
}

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(currentAdminProvider)!;
    final role = admin.role!;
    final items = navItems.where((n) => role.can(n.module)).toList();
    final selectedId = ref.watch(selectedNavProvider);
    final selected = items.where((n) => n.id == selectedId).firstOrNull ?? items.first;
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    final menu = ListView(children: [
      const DrawerHeader(
        decoration: BoxDecoration(gradient: KjdColors.heroGradient),
        child: Row(children: [
          TempleLogo(size: 64),
          SizedBox(width: 8),
          Expanded(
            child: Text('श्री काळभैरव जागृत देवस्थान\nAdmin',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
      for (final (i, n) in items.indexed) ...[
        if (n.group.isNotEmpty && (i == 0 || items[i - 1].group != n.group))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(n.group.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: KjdColors.inkMuted)),
          ),
        ListTile(
          dense: true,
          selected: n.id == selected.id,
          selectedTileColor: KjdColors.goldLight,
          leading: Icon(n.icon),
          title: Text(n.label),
          onTap: () {
            ref.read(selectedNavProvider.notifier).select(n.id);
            if (!wide) Navigator.of(context).maybePop();
          },
        ),
      ],
    ]);

    return Scaffold(
      appBar: AppBar(
        title: Text(selected.label),
        actions: [
          if (ref.watch(demoModeProvider))
            const Padding(padding: EdgeInsets.only(right: 8), child: Chip(label: Text('DEMO'), backgroundColor: KjdColors.gold)),
          Center(child: Text('${admin.email ?? admin.uid} • ${role.label}', style: const TextStyle(color: Colors.white))),
          IconButton(tooltip: 'Sign out', icon: const Icon(Icons.logout), onPressed: () => ref.read(authServiceProvider).signOut()),
        ],
      ),
      drawer: wide ? null : Drawer(child: menu),
      body: Row(children: [
        if (wide) SizedBox(width: 260, child: Material(color: Colors.white, child: menu)),
        Expanded(child: KeyedSubtree(key: ValueKey(selected.id), child: selected.builder())),
      ]),
    );
  }
}
