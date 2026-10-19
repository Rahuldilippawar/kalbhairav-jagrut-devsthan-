import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../features/banner/festival_picker.dart';
import '../widgets/common.dart';
import 'providers.dart';
import 'router.dart';

/// Screens at least this wide get the side menu instead of the bottom bar.
const wideLayoutBreakpoint = 900.0;

/// The today panel on the right appears from this width.
const _todayPanelBreakpoint = 1320.0;

/// Content column width on large screens (phone-like reading width).
const _contentMaxWidth = 860.0;

bool isWideLayout(BuildContext context) => MediaQuery.sizeOf(context).width >= wideLayoutBreakpoint;

/// Mouse and trackpad can drag horizontal lists (deity strip, darshan
/// slider…) on the web, as fingers do on phones.
class KjdScrollBehavior extends MaterialScrollBehavior {
  const KjdScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {...super.dragDevices, PointerDeviceKind.mouse, PointerDeviceKind.trackpad};
}

/// Tabs of the bottom navigation, in order (also the side menu on wide
/// screens).
const shellTabs = ['/home', '/darshan', '/events', '/seva', '/guru', '/profile'];

/// Wraps the whole app on wide screens (web on a laptop or tablet): a side
/// menu on the left, the app in a centred column, and today's panchang,
/// suvichar and festivals on the right. Phones get [child] unchanged.
class WebFrame extends ConsumerWidget {
  const WebFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final router = ref.watch(routerProvider);
    return _RouteListener(
      router: router,
      builder: (context) {
        final path = router.routerDelegate.currentConfiguration.uri.path;
        final large = width >= wideLayoutBreakpoint;
        final wide = large && path != '/splash' && path != '/onboarding' && path.isNotEmpty;
        // Onboarding on a large screen: a phone-sized card in the middle.
        final card = large && path == '/onboarding';
        // The widget tree around [child] (the app's Navigator) stays the same
        // in every case; only the decorations change, so switching layouts
        // never rebuilds the open pages.
        return Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: wide || card
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF8EC), Color(0xFFFFEFD6), Color(0xFFFBE3C4)],
                    )
                  : null,
            ),
            child: Row(children: [
              wide ? _SideMenu(path: path, router: router, extended: width >= 1100) : const SizedBox.shrink(),
              Expanded(
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: card ? 520 : (wide ? _contentMaxWidth : double.infinity)),
                    margin: wide || card ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14) : EdgeInsets.zero,
                    clipBehavior: wide || card ? Clip.antiAlias : Clip.none,
                    decoration: wide || card
                        ? BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33B71C1C), blurRadius: 30, offset: Offset(0, 10)),
                            ],
                          )
                        : const BoxDecoration(),
                    child: child,
                  ),
                ),
              ),
              wide && width >= _todayPanelBreakpoint ? _TodayPanel(router: router) : const SizedBox.shrink(),
            ]),
          ),
        );
      },
    );
  }
}

/// Rebuilds on navigation. The router notifies while it is building, so
/// the rebuild waits for the end of that frame.
class _RouteListener extends StatefulWidget {
  const _RouteListener({required this.router, required this.builder});
  final GoRouter router;
  final WidgetBuilder builder;

  @override
  State<_RouteListener> createState() => _RouteListenerState();
}

class _RouteListenerState extends State<_RouteListener> {
  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_changed);
  }

  @override
  void didUpdateWidget(_RouteListener old) {
    super.didUpdateWidget(old);
    if (old.router != widget.router) {
      old.router.routerDelegate.removeListener(_changed);
      widget.router.routerDelegate.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

class _SideMenu extends StatelessWidget {
  const _SideMenu({required this.path, required this.router, required this.extended});
  final String path;
  final GoRouter router;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tabs = [
      ('🏠', l.navHome),
      ('🙏', l.navDarshan),
      ('🎉', l.navEvents),
      ('🪔', l.navSeva),
      ('📿', l.navGuru),
      ('👤', l.navProfile),
    ];
    final links = [
      ('📺', l.liveDarshan, '/live'),
      ('🛕', l.templeDeities, '/deities'),
      ('🚩', l.gadhipatiParampara, '/parampara'),
      ('📅', l.calendarTitle, '/calendar'),
      ('🖼️', l.gallery, '/gallery'),
      ('🎨', l.makeBanner, '/banner'),
      ('🙏', l.donateNow, '/donate'),
    ];
    final current = shellTabs.indexWhere((t) => path == t);
    return Container(
      width: extended ? 250 : 88,
      decoration: const BoxDecoration(gradient: KjdColors.heroGradient),
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10), children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => router.go('/home'),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: KjdColors.gold, shape: BoxShape.circle),
                  child: TempleLogo(size: extended ? 76 : 52),
                ),
                if (extended) ...[
                  const SizedBox(height: 10),
                  Text(l.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          fontFamily: bannerFontFamily('tiroMarathi'),
                          locale: bannerTextLocale)),
                  const Text('रुंधाटी', style: TextStyle(color: KjdColors.goldLight)),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 14),
          for (final (i, (icon, label)) in tabs.indexed)
            _MenuItem(
              icon: icon,
              label: label,
              selected: i == current,
              extended: extended,
              onTap: () => router.go(shellTabs[i]),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white.withValues(alpha: .25)),
          ),
          if (extended)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(l.webQuickLinks.toUpperCase(),
                  style: const TextStyle(color: KjdColors.goldLight, fontSize: 11.5, fontWeight: FontWeight.w800)),
            ),
          for (final (icon, label, to) in links)
            _MenuItem(
              icon: icon,
              label: label,
              selected: path == to,
              extended: extended,
              dense: true,
              onTap: () => router.push(to),
            ),
        ]),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.extended,
    required this.onTap,
    this.dense = false,
  });
  final String icon;
  final String label;
  final bool selected;
  final bool extended;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? KjdColors.kumkumDark : Colors.white;
    final iconText = Text(icon, style: TextStyle(fontSize: dense ? 18 : 21));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? KjdColors.goldLight : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: Colors.white.withValues(alpha: .12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 8 : 11),
            child: extended
                ? Row(children: [
                    iconText,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: fg,
                              fontSize: dense ? 13.5 : 15,
                              fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
                    ),
                  ])
                : Column(children: [
                    iconText,
                    if (!dense)
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ]),
          ),
        ),
      ),
    );
  }
}

/// Right column on very wide screens: today's date and tithi, the suvichar
/// and the next festivals.
class _TodayPanel extends ConsumerWidget {
  const _TodayPanel({required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider)();
    final today = dateOnly(now);
    final tithi = ref.watch(tithiProvider(today)).value ?? computeTithi(today);
    final quote = ref.watch(quoteTodayProvider).value;
    final festivals = ref.watch(upcomingFestivalsProvider).take(6).toList();
    return SizedBox(
      width: 320,
      child: ListView(padding: const EdgeInsets.fromLTRB(0, 14, 20, 14), children: [
        _PanelCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('📅 ${l.today}', style: const TextStyle(color: KjdColors.saffron, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(formatWeekday(today, locale: context.lang),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: KjdColors.kumkumDark)),
            Text(formatDate(today, locale: context.lang), style: const TextStyle(color: KjdColors.inkMuted)),
            const Divider(height: 20),
            InfoRow('🌙 ${l.tithi}', '${tithi.paksha} ${tithi.tithi}', bold: true),
            InfoRow('✨ ${l.nakshatra}', tithi.nakshatra),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => router.push('/tithi'), child: Text('${l.tithi} →')),
            ),
          ]),
        ),
        if (quote != null)
          _PanelCard(
            gradient: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('🪷 ${l.todaysQuote}', style: const TextStyle(color: KjdColors.goldLight, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(quote.text,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      height: 1.5,
                      fontFamily: bannerFontFamily('tiroMarathi'),
                      locale: bannerTextLocale)),
              if (quote.author != null && quote.author!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('— ${quote.author}', style: const TextStyle(color: KjdColors.goldLight)),
                ),
            ]),
          ),
        if (festivals.isNotEmpty)
          _PanelCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('🪔 ${l.webFestivals}', style: const TextStyle(color: KjdColors.saffron, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              for (final f in festivals)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text(festivalEmoji(f.festival), style: const TextStyle(fontSize: 22)),
                  title: Text(f.festival.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(festivalDayLabel(context, f.date, now)),
                  trailing: const Icon(Icons.palette_outlined, color: KjdColors.kumkum, size: 20),
                  onTap: () => router.push(Uri(
                    path: '/banner',
                    queryParameters: {'festival': f.festival.id, 'date': dateKey(f.date)},
                  ).toString()),
                ),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('📲 ${l.webInstallHint}',
              textAlign: TextAlign.center, style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12.5)),
        ),
      ]),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child, this.gradient = false});
  final Widget child;
  final bool gradient;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: gradient ? null : Colors.white,
          gradient: gradient ? KjdColors.heroGradient : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Material(type: MaterialType.transparency, child: child),
      );
}
