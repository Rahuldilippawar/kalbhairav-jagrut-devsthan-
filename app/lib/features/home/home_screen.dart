import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/app_update.dart';
import '../../app/providers.dart';
import '../../widgets/common.dart';
import '../darshan/darshan_screen.dart';
import '../darshan/darshan_slider.dart';
import '../devotion/tithi_screen.dart';
import '../events/events_screen.dart';
import 'daily_quote_popup.dart';
import 'festival_today_card.dart';

/// Home: everything on it is driven by admin-managed content.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider)();
    final settings = ref.watch(settingsProvider).value;
    if (settings?.maintenanceMode ?? false) {
      return Scaffold(body: EmptyState(message: settings!.maintenanceMessage ?? l.maintenance));
    }
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          for (final p in [homeBannersProvider, greetingsTodayProvider, upcomingEventsProvider, announcementsProvider]) {
            ref.invalidate(p);
          }
        },
        child: CustomScrollView(slivers: [
          const _Header(),
          const SliverToBoxAdapter(child: UpdateBanner()),
          const SliverToBoxAdapter(child: DailyQuoteGate()),
          const SliverToBoxAdapter(child: _HeroCarousel()),
          const SliverToBoxAdapter(child: DarshanSlider(height: 240, padding: EdgeInsets.symmetric(horizontal: 16), maxAgeDays: 1)),
          const SliverToBoxAdapter(child: FestivalTodayCard()),
          const SliverToBoxAdapter(child: _CelebrationCard()),
          const SliverToBoxAdapter(child: _QuickActions()),
          const SliverToBoxAdapter(child: _LiveStrip()),
          SliverToBoxAdapter(child: SectionHeader(l.todaysGreeting, icon: '🌅')),
          const SliverToBoxAdapter(child: _GreetingCard()),
          SliverToBoxAdapter(
            child: SectionHeader(l.todaysTithi, icon: '📅', action: l.viewAll, onAction: () => context.push('/tithi')),
          ),
          Consumer(builder: (context, ref, _) {
            final tithi = ref.watch(tithiProvider(dateOnly(now)));
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AsyncView(tithi, data: (t) => TithiCard(tithi: t, compact: true)),
              ),
            );
          }),
          const SliverToBoxAdapter(child: _Notices()),
          const SliverToBoxAdapter(child: _PublicWishes()),
          SliverToBoxAdapter(
            child: SectionHeader(l.upcomingEvents, icon: '🎉', action: l.viewAll, onAction: () => context.go('/events')),
          ),
          const SliverToBoxAdapter(child: _UpcomingEvents()),
          SliverToBoxAdapter(
            child: SectionHeader(l.todaysDarshan, icon: '🙏', action: l.viewAll, onAction: () => context.go('/darshan')),
          ),
          const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: DarshanSummaryCard()),
          ),
          const SliverToBoxAdapter(child: _DonateCta()),
          SliverToBoxAdapter(child: SectionHeader(l.todaysQuote, icon: '💬')),
          const SliverToBoxAdapter(child: _QuoteCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ]),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final info = ref.watch(templeInfoProvider).value ?? const TempleInfo();
    final now = ref.watch(clockProvider)();
    final greeting = switch (now.hour) {
      < 12 => l.greetMorning,
      < 16 => l.greetAfternoon,
      < 20 => l.greetEvening,
      _ => l.greetNight,
    };
    final slots = ref.watch(darshanProvider).value ?? const [];
    final open = slots
        .where((s) => s.type == DarshanType.morning || s.type == DarshanType.evening)
        .any((s) => s.isOpenAt(now));
    const radius = BorderRadius.vertical(bottom: Radius.circular(28));
    return SliverAppBar(
      pinned: true,
      expandedHeight: 196,
      backgroundColor: KjdColors.kumkum,
      shape: const RoundedRectangleBorder(borderRadius: radius),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () => context.push('/search')),
        IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.push('/notifications')),
      ],
      flexibleSpace: ClipRRect(
        borderRadius: radius,
        child: FlexibleSpaceBar(
          background: Container(
            decoration: const BoxDecoration(gradient: KjdColors.heroGradient),
            child: Stack(children: [
              const Positioned(
                right: -10,
                top: 20,
                child: Text('ॐ', style: TextStyle(fontSize: 170, color: Color(0x14FFFFFF), fontWeight: FontWeight.w900)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(greeting, style: const TextStyle(color: KjdColors.gold, fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 10)],
                      ),
                      child: const TempleLogo(size: 64),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(info.nameMr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2)),
                        Text('${info.location} • ${info.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: KjdColors.goldLight, fontSize: 12)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _HeaderPill(icon: Icons.calendar_today, text: formatDate(now, locale: context.lang)),
                    if (slots.isNotEmpty)
                      _HeaderPill(
                        dot: open ? const Color(0xFF69F0AE) : Colors.white54,
                        text: open ? l.darshanOpenNow : l.darshanClosedNow,
                        onTap: () => context.go('/darshan'),
                      ),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.text, this.icon, this.dot, this.onTap});
  final String text;
  final IconData? icon;
  final Color? dot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0x26FFFFFF),
        shape: const StadiumBorder(side: BorderSide(color: Color(0x33FFFFFF))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) Icon(icon, size: 13, color: Colors.white),
              if (dot != null) Icon(Icons.circle, size: 10, color: dot),
              const SizedBox(width: 6),
              Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}

class _HeroCarousel extends ConsumerStatefulWidget {
  const _HeroCarousel();
  @override
  ConsumerState<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends ConsumerState<_HeroCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(homeBannersProvider).value ?? const [];
    if (banners.isEmpty) return const SizedBox(height: 8);
    return Column(children: [
      const SizedBox(height: 12),
      SizedBox(
        height: 170,
        child: PageView.builder(
          controller: PageController(viewportFraction: .92),
          onPageChanged: (i) => setState(() => _index = i),
          itemCount: banners.length,
          itemBuilder: (context, i) {
            final b = banners[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    if (b.eventId != null) context.push('/event/${b.eventId}');
                    if (b.link != null && b.link!.startsWith('/')) context.push(b.link!);
                  },
                  child: Stack(fit: StackFit.expand, children: [
                    NetImage(b.imageUrl, fallbackIcon: '🌺'),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.title,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        if (b.subtitle != null)
                          Text(b.subtitle!, style: const TextStyle(color: KjdColors.goldLight)),
                        if (b.eventId != null) ...[
                          const SizedBox(height: 6),
                          Pill(context.l10n.viewEvent, color: KjdColors.gold, filled: true),
                        ],
                      ]),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
      if (banners.length > 1)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < banners.length; i++)
            Container(
              margin: const EdgeInsets.fromLTRB(3, 8, 3, 0),
              width: i == _index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _index ? KjdColors.kumkum : KjdColors.saffronLight,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ]),
    ]);
  }
}

/// Birthday / anniversary greeting for the signed-in devotee.
class _CelebrationCard extends ConsumerWidget {
  const _CelebrationCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider).value;
    final now = ref.watch(clockProvider)();
    if (p == null || p.birthdayPrivacy == GreetingPrivacy.private) return const SizedBox.shrink();
    final l = context.l10n;
    final String headline, message;
    final BannerCategory cat;
    final String name;
    if (p.isBirthday(now)) {
      (headline, message, cat, name) = ('🎂 ${l.happyBirthday}', l.birthdayWish(p.name), BannerCategory.birthday, p.name);
    } else if (p.isAnniversary(now)) {
      final names = p.spouseName == null ? p.name : '${p.name} व ${p.spouseName}';
      (headline, message, cat, name) = ('💍 ${l.anniversary}', l.anniversaryWish(names), BannerCategory.anniversary, names);
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(gradient: KjdColors.goldGradient, borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const TempleLogo(size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(headline, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: KjdColors.kumkumDark)),
              const SizedBox(height: 4),
              Text(message, style: const TextStyle(color: KjdColors.ink)),
            ]),
          ),
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: KjdColors.kumkum),
            icon: const Icon(Icons.share),
            onPressed: () => context.push(Uri(path: '/banner', queryParameters: {'category': cat.name, 'name': name}).toString()),
          ),
        ]),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = [
      ('🙏', l.quickDarshan, () => context.go('/darshan')),
      ('🪔', l.quickSeva, () => context.go('/seva')),
      ('💰', l.quickDonate, () => context.push('/donate')),
      ('📅', l.quickEvents, () => context.go('/events')),
      ('📺', l.quickLive, () => context.push('/live')),
      ('🛕', l.quickTemple, () => context.push('/temple')),
      ('🖼️', l.quickGallery, () => context.push('/gallery')),
      ('🎨', l.quickBanner, () => context.push('/banner')),
      ('🔱', l.quickDeities, () => context.push('/deities')),
      ('🚩', l.quickParampara, () => context.push('/parampara')),
      ('📅', l.quickTithi, () => context.push('/tithi')),
    ];
    Widget tile(int i, String emoji, String label, VoidCallback onTap) => Material(
          color: Colors.white,
          elevation: 1.5,
          shadowColor: const Color(0x33B26A00),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _tileTints[i % _tileTints.length], shape: BoxShape.circle),
                child: Text(emoji, style: const TextStyle(fontSize: 23)),
              ),
              const SizedBox(height: 6),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: LayoutBuilder(builder: (context, box) {
        // 4 on phones (7 tiles + "More"), up to 6 with every tile on tablets and the web.
        final columns = (box.maxWidth / 130).floor().clamp(4, 6);
        final shown = columns == 4 ? items.take(7).toList() : items;
        final rest = columns == 4 ? items.skip(7).toList() : const <(String, String, VoidCallback)>[];
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: .9,
          children: [
            for (final (i, (emoji, label, onTap)) in shown.indexed) tile(i, emoji, label, onTap),
            if (rest.isNotEmpty)
              tile(7, '➕', l.quickMore, () {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (sheet) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: .9,
                        children: [
                          for (final (i, (emoji, label, onTap)) in rest.indexed)
                            tile(i + 8, emoji, label, () {
                              Navigator.pop(sheet);
                              onTap();
                            }),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      }),
    );
  }
}

/// Soft circle colours for the quick-action tiles.
const _tileTints = [
  Color(0xFFFFF3C4), Color(0xFFFFE0CC), Color(0xFFFCE4EC), Color(0xFFE8F5E9),
  Color(0xFFE3F2FD), Color(0xFFF3E5F5), Color(0xFFFFF8E1), Color(0xFFE0F7FA),
];

class _LiveStrip extends ConsumerWidget {
  const _LiveStrip();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveProvider).value;
    if (live == null || !live.isLive) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        color: const Color(0xFFFFEBEE),
        child: ListTile(
          leading: const LivePill(),
          title: Text(live.title.isEmpty ? context.l10n.liveDarshan : live.title,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: const Icon(Icons.play_circle_fill, color: KjdColors.live, size: 32),
          onTap: () => context.push('/live'),
        ),
      ),
    );
  }
}

const _fallbackMessages = [
  'श्री काळभैरवनाथांच्या कृपेने आपला आजचा दिवस आनंदी, आरोग्यदायी व मंगलमय होवो.',
  'भक्तीत शक्ती आहे; श्रद्धेने केलेले प्रत्येक कार्य सफल होते. जय काळभैरव!',
  'मनात श्रद्धा, ओठी नाम आणि हाती सत्कर्म — हाच खरा धर्म.',
  'काळावर ज्यांची सत्ता, ते काळभैरव आपल्या कुटुंबाचे सदैव रक्षण करोत.',
  'संकटे कितीही आली तरी नामस्मरणाची साथ सोडू नका; देव पाठीशी उभा आहे.',
  'सेवा, संयम आणि सद्भावना — यातूनच जीवन पवित्र होते. शुभ दिवस!',
  'श्री काळभैरवनाथ आपल्या सर्व इच्छा पूर्ण करोत. ॐ कालभैरवाय नमः',
];

DailyGreeting _fallbackGreeting(DateTime now) {
  final day = now.difference(DateTime(now.year)).inDays;
  final evening = now.hour >= 16;
  return DailyGreeting(
    id: 'builtin',
    title: evening ? 'शुभ संध्या 🪔' : 'शुभ प्रभात 🌅',
    message: _fallbackMessages[day % _fallbackMessages.length],
    date: dateKey(now),
    category: evening ? 'शुभ संध्या' : 'शुभ प्रभात',
  );
}

class _GreetingCard extends ConsumerWidget {
  const _GreetingCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greetings = ref.watch(greetingsTodayProvider);
    final now = ref.watch(clockProvider)();
    return AsyncView(greetings, data: (list) {
      // Morning greeting before 4pm, evening one afterwards when available.
      // When the temple hasn't published one for today, a built-in message
      // (rotating by day) keeps the section from appearing empty.
      final evening = list.where((g) => g.category == 'शुभ संध्या').firstOrNull;
      final g = list.isEmpty
          ? _fallbackGreeting(now)
          : now.hour >= 16 && evening != null ? evening : list.first;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(gradient: KjdColors.heroGradient, borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(g.title, style: const TextStyle(color: KjdColors.gold, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('“${g.message}”', style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
            const SizedBox(height: 12),
            Row(children: [
              const TempleLogo(size: 28),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('श्री काळभैरव जागृत देवस्थान, रुंधाटी',
                    style: TextStyle(color: KjdColors.goldLight, fontSize: 12)),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                icon: const Icon(Icons.share, size: 18),
                label: Text(context.l10n.share),
                onPressed: () => context.push(Uri(path: '/banner', queryParameters: {
                  'category': BannerCategory.dailySubhechha.name,
                  'message': g.message,
                }).toString()),
              ),
            ]),
          ]),
        ),
      );
    });
  }
}

class _Notices extends ConsumerWidget {
  const _Notices();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(announcementsProvider).value ?? const [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(context.l10n.todaysNotice, icon: '📢'),
      for (final a in list.take(3))
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Card(
            color: a.urgent ? const Color(0xFFFFEBEE) : null,
            child: ListTile(
              leading: Icon(a.urgent ? Icons.warning_amber_rounded : Icons.campaign_outlined,
                  color: a.urgent ? KjdColors.live : KjdColors.saffron),
              title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(a.body, maxLines: 3, overflow: TextOverflow.ellipsis),
              onTap: () => context.push('/notifications'),
            ),
          ),
        ),
    ]);
  }
}

class _UpcomingEvents extends ConsumerWidget {
  const _UpcomingEvents();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(upcomingEventsProvider);
    return AsyncView(events, data: (list) {
      if (list.isEmpty) return EmptyState(message: context.l10n.noEvents);
      return SizedBox(
        height: 210,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(width: 260, child: EventCard(event: list[i])),
        ),
      );
    });
  }
}

class _DonateCta extends StatelessWidget {
  const _DonateCta();
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        decoration: BoxDecoration(gradient: KjdColors.goldGradient, borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          const Text('🪙', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l.donateCta,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: KjdColors.kumkumDark)),
          ),
          FilledButton(onPressed: () => context.push('/donate'), child: Text(l.donateNow)),
        ]),
      ),
    );
  }
}

class _QuoteCard extends ConsumerWidget {
  const _QuoteCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(quoteTodayProvider).value;
    if (q == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/greetings'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Pill(q.category),
              const SizedBox(height: 10),
              Text('“${q.text}”', style: const TextStyle(fontSize: 17, height: 1.5, fontWeight: FontWeight.w600)),
              if (q.author != null)
                Align(alignment: Alignment.centerRight, child: Text('— ${q.author}', style: const TextStyle(color: KjdColors.inkMuted))),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Birthdays/anniversaries of devotees who chose "Public" (published daily
/// by the server – no private profile data is read here).
class _PublicWishes extends ConsumerWidget {
  const _PublicWishes();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(publicGreetingsProvider).value?.entries ?? const [];
    if (entries.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(l.todaysWishes, icon: '🎉'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Column(children: [
            for (final e in entries.take(10))
              ListTile(
                leading: Text(e.kind == GreetingKind.birthday ? '🎂' : '💍', style: const TextStyle(fontSize: 24)),
                title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: e.village == null ? null : Text(e.village!),
                trailing: IconButton(
                  tooltip: l.sendWishes,
                  icon: const Icon(Icons.share, color: KjdColors.kumkum),
                  onPressed: () => context.push(Uri(path: '/banner', queryParameters: {
                    'category': e.kind == GreetingKind.birthday ? BannerCategory.birthday.name : BannerCategory.anniversary.name,
                    'name': e.name,
                  }).toString()),
                ),
              ),
          ]),
        ),
      ),
    ]);
  }
}

