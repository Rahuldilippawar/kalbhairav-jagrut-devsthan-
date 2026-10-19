import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/media_viewer.dart';
import '../banner/festival_picker.dart' show programmeLine;

/// Kalnirnay-style month calendar: each date with its tithi and festivals,
/// and below it the full Panchang of the selected day (tithi/nakshatra end
/// times, moonrise, rahu kaal …) and the month's festivals and vrats.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

const _firstYear = 1950;
int _pageOf(DateTime d) => (d.year - _firstYear) * 12 + d.month - 1;
DateTime _monthOf(int page) => DateTime(_firstYear + page ~/ 12, page % 12 + 1);

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late final DateTime _today = dateOnly(ref.read(clockProvider)());
  late DateTime _selected = _today;
  late final _pages = PageController(initialPage: _pageOf(_today));

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(DateTime d) {
    setState(() => _selected = d);
    final page = _pageOf(d);
    if (_pages.hasClients && _pages.page?.round() != page) {
      _pages.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.calendarTitle), actions: [
        TextButton.icon(
          onPressed: () => _goTo(_today),
          icon: const Icon(Icons.today),
          label: Text(l.today),
        ),
      ]),
      body: PageView.builder(
        controller: _pages,
        itemCount: (2100 - _firstYear) * 12,
        onPageChanged: (p) {
          final m = _monthOf(p);
          if (_selected.year != m.year || _selected.month != m.month) {
            setState(() => _selected = m.year == _today.year && m.month == _today.month ? _today : m);
          }
        },
        itemBuilder: (_, p) => _MonthPage(
          month: _monthOf(p),
          today: _today,
          selected: _selected,
          onSelect: (d) => setState(() => _selected = d),
          onMonth: (delta) => _pages.animateToPage(p + delta,
              duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
        ),
      ),
    );
  }
}

/// Devanagari digits for Marathi and Hindi.
String localDigits(BuildContext context, Object v) {
  final s = '$v';
  if (context.lang != 'mr' && context.lang != 'hi') return s;
  return s.replaceAllMapped(RegExp('[0-9]'), (m) => '०१२३४५६७८९'[int.parse(m[0]!)]);
}

String _t(BuildContext context, DateTime utc) => localDigits(context, istTime(utc));

class _MonthPage extends ConsumerWidget {
  const _MonthPage({
    required this.month,
    required this.today,
    required this.selected,
    required this.onSelect,
    required this.onMonth,
  });
  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<int> onMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final festivals = ref
        .watch(festivalYearProvider(month.year))
        .where((f) => f.date.month == month.month)
        .toList();
    final byDay = <int, List<FestivalDay>>{};
    for (final f in festivals) {
      byDay.putIfAbsent(f.date.day, () => []).add(f);
    }
    final events = ref.watch(allEventsProvider).value ?? const <TempleEvent>[];
    final programmes = (ref.watch(calendarEventsProvider).value ?? const <CalendarEvent>[])
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .toList();
    bool hasEvent(DateTime d) => events.any((e) => _eventOn(e, d)) || programmes.any((e) => e.date == d);

    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final first = dayPanchang(month), last = dayPanchang(DateTime(month.year, month.month, days));
    final lunar = first.masa == last.masa ? first.masa : '${first.masa} – ${last.masa}';
    final lead = month.weekday % 7; // Sunday first

    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      // ---- month header
      Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 12),
        decoration: BoxDecoration(gradient: KjdColors.heroGradient, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onMonth(-1),
          ),
          Expanded(
            child: Column(children: [
              Text(localDigits(context, DateFormat('MMMM yyyy', context.lang).format(month)),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(lunar, style: const TextStyle(color: KjdColors.gold, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                '${l.shakaSamvat} ${localDigits(context, first.shaka)} • ${l.nameSamvatsara(first.samvatsara)}',
                style: const TextStyle(color: KjdColors.goldLight, fontSize: 12),
              ),
            ]),
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onMonth(1),
          ),
        ]),
      ),
      // ---- grid
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            Container(
              color: KjdColors.goldLight,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Text(
                      DateFormat('E', context.lang).format(DateTime(2026, 1, 4 + i)),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: i == 0 ? KjdColors.kumkum : KjdColors.ink,
                      ),
                    ),
                  ),
              ]),
            ),
            for (var w = 0; w * 7 < lead + days; w++)
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (var c = 0; c < 7; c++)
                    Expanded(child: () {
                      final n = w * 7 + c - lead + 1;
                      if (n < 1 || n > days) return const _EmptyCell();
                      final d = DateTime(month.year, month.month, n);
                      return _DayCell(
                        date: d,
                        festivals: byDay[n] ?? const [],
                        isToday: d == today,
                        isSelected: d == selected,
                        hasEvent: hasEvent(d),
                        programme: programmes.where((e) => e.date == d).firstOrNull,
                        onTap: () => onSelect(d),
                      );
                    }()),
                ]),
              ),
          ]),
        ),
      ),
      const SizedBox(height: 6),
      const _Legend(),
      // ---- selected day
      if (selected.year == month.year && selected.month == month.month)
        _DayDetail(
          date: selected,
          festivals: byDay[selected.day] ?? const [],
          events: events.where((e) => _eventOn(e, selected)).toList(),
          programmes: programmes.where((e) => e.date == selected).toList(),
        ),
      // ---- month list
      if (programmes.isNotEmpty) ...[
        SectionHeader(l.templeEventsOnDay, icon: '🛕'),
        for (final e in programmes)
          _ProgrammeRow(e: e, selected: e.date == selected, onTap: () => onSelect(e.date)),
      ],
      if (festivals.isNotEmpty) ...[
        SectionHeader(l.monthFestivals, icon: '🪔'),
        for (final f in festivals)
          _FestivalRow(f: f, selected: f.date == selected, onTap: () => onSelect(f.date)),
      ],
    ]);
  }
}

bool _eventOn(TempleEvent e, DateTime d) {
  final s = dateOnly(e.startDate);
  final end = dateOnly(e.endDate ?? e.startDate);
  return !d.isBefore(s) && !d.isAfter(end);
}

bool _isHoliday(List<FestivalDay> f) => f.any((x) => x.festival.kind != FestivalKind.vrat);

class _EmptyCell extends StatelessWidget {
  const _EmptyCell();
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 74),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6EE),
          border: Border.all(color: const Color(0xFFEFE4D2), width: .5),
        ),
      );
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.festivals,
    required this.isToday,
    required this.isSelected,
    required this.hasEvent,
    required this.onTap,
    this.programme,
  });
  final CalendarEvent? programme;
  final DateTime date;
  final List<FestivalDay> festivals;
  final bool isToday;
  final bool isSelected;
  final bool hasEvent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = dayPanchang(date);
    final tithi = p.moment.tithi;
    final red = date.weekday == DateTime.sunday || _isHoliday(festivals);
    final label = festivals.where((f) => f.festival.kind != FestivalKind.vrat).firstOrNull ?? festivals.firstOrNull;
    final fg = isSelected ? Colors.white : (red ? KjdColors.kumkum : KjdColors.ink);
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${date.day} ${p.tithis.first.name}',
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
          decoration: BoxDecoration(
            gradient: isSelected ? KjdColors.heroGradient : null,
            color: isSelected ? null : (festivals.isNotEmpty ? const Color(0xFFFFF6DC) : Colors.white),
            border: isToday && !isSelected
                ? Border.all(color: KjdColors.saffron, width: 2)
                : Border.all(color: const Color(0xFFEFE4D2), width: .5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: Text(localDigits(context, date.day),
                    style: TextStyle(fontSize: 20, height: 1.1, fontWeight: FontWeight.w900, color: fg)),
              ),
              if (tithi == 15) const Text('🌕', style: TextStyle(fontSize: 11)),
              if (tithi == 30) const Text('🌑', style: TextStyle(fontSize: 11)),
              if (hasEvent)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(left: 2),
                  decoration: BoxDecoration(
                      color: isSelected ? KjdColors.gold : KjdColors.success, shape: BoxShape.circle),
                ),
            ]),
            const SizedBox(height: 2),
            Text(
              p.tithis.first.name,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? KjdColors.goldLight : KjdColors.inkMuted,
              ),
            ),
            if (label != null)
              Text(
                label.festival.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? KjdColors.gold
                      : label.festival.kind == FestivalKind.vrat
                          ? KjdColors.saffron
                          : KjdColors.kumkum,
                ),
              ),
            if (programme?.photoUrl case final url? when url.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3, bottom: 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: NetImage(url, height: 30, fallbackIcon: '🛕'),
                ),
              ),
            if (programme != null)
              Text(
                '🛕 ${programme!.title}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? KjdColors.goldLight : KjdColors.success,
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    Widget item(Widget mark, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
          mark,
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: KjdColors.inkMuted)),
        ]);
    Widget box(Color c) => Container(width: 10, height: 10, color: c);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Wrap(spacing: 14, runSpacing: 4, children: [
        item(const Text('🌕', style: TextStyle(fontSize: 11)), 'पौर्णिमा'),
        item(const Text('🌑', style: TextStyle(fontSize: 11)), 'अमावस्या'),
        item(box(const Color(0xFFFFF6DC)), 'सण / व्रत'),
        item(
            Container(
                width: 8, height: 8, decoration: const BoxDecoration(color: KjdColors.success, shape: BoxShape.circle)),
            context.l10n.templeEventsOnDay),
      ]),
    );
  }
}

class _DayDetail extends ConsumerWidget {
  const _DayDetail({required this.date, required this.festivals, required this.events, required this.programmes});
  final DateTime date;
  final List<FestivalDay> festivals;
  final List<TempleEvent> events;
  final List<CalendarEvent> programmes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = dayPanchang(date);
    // The temple can publish a correction or note for any day.
    final manual = ref.watch(tithiProvider(date)).value;
    final note = manual != null && manual.source != 'computed' && manual.source != 'demo' ? manual.specialDay : null;

    String spans(List<PanchangSpan> s) => s
        .map((x) => x.end == null ? x.name : '${x.name} (${l.untilTime(_t(context, x.end!))})')
        .join(' → ');
    String range(TimeRange r) => '${_t(context, r.start)} – ${_t(context, r.end)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(gradient: KjdColors.heroGradient, borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Text(localDigits(context, date.day),
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1)),
                  Text(DateFormat('MMM', context.lang).format(date),
                      style: const TextStyle(color: KjdColors.goldLight, fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.vaar, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  Text('${p.masa} ${p.paksha} ${p.tithis.first.name}',
                      style: const TextStyle(color: KjdColors.kumkumDark, fontWeight: FontWeight.w700)),
                  Text('${l.shakaSamvat} ${localDigits(context, p.shaka)} • ${l.nameSamvatsara(p.samvatsara)}',
                      style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12)),
                ]),
              ),
              IconButton(
                tooltip: l.createBanner,
                icon: const Icon(Icons.share, color: KjdColors.kumkum),
                onPressed: () => context.push(Uri(path: '/banner', queryParameters: {
                  'category': BannerCategory.tithi.name,
                  'message': [
                    '${p.vaar}, ${formatDate(date)}',
                    '${p.masa} ${p.paksha}',
                    '${l.tithi}: ${p.tithis.first.name}',
                    '${l.nakshatra}: ${p.nakshatras.first.name}',
                    for (final f in festivals) '✨ ${f.festival.name}',
                    for (final e in programmes) programmeLine(e),
                  ].join('\n'),
                }).toString()),
              ),
            ]),
            if (festivals.isNotEmpty || note != null) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final f in festivals)
                  Pill('✨ ${f.festival.name}',
                      color: f.festival.kind == FestivalKind.vrat ? KjdColors.saffron : KjdColors.kumkum),
                if (note != null && note.isNotEmpty) Pill('🛕 $note', color: KjdColors.success),
              ]),
            ],
            if (events.isNotEmpty || programmes.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final e in programmes)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Text('🛕', style: TextStyle(fontSize: 22)),
                  title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  subtitle: e.location.isEmpty ? null : Text('📍 ${e.location}'),
                ),
              for (final e in programmes)
                if (e.photoUrl case final url? when url.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => MediaViewer.open(context, [MediaEntry(url: url, caption: e.title)]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: NetImage(url, height: 180, width: double.infinity),
                      ),
                    ),
                  ),
              for (final e in events)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, color: KjdColors.success),
                  title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(l.templeEventsOnDay),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/event/${e.id}'),
                ),
            ],
            const Divider(height: 24),
            _Row('🌙', l.tithi, spans(p.tithis)),
            _Row('⭐', l.nakshatra, spans(p.nakshatras)),
            _Row('🔱', l.yoga, spans(p.yogas)),
            _Row('☸️', l.karana, spans(p.karanas)),
            _Row('♈', l.moonRashi,
                p.moonRashiEnd == null ? p.moonRashi : '${p.moonRashi} (${l.untilTime(_t(context, p.moonRashiEnd!))})'),
            _Row('☀️', l.sunRashi, p.sunRashi),
            _Row('🍃', '${l.ritu} / ${l.ayana}', '${p.ritu} ऋतू • ${p.uttarayan ? 'उत्तरायण' : 'दक्षिणायन'}'),
            const SizedBox(height: 8),
            _Heading(l.sunAndMoon),
            Row(children: [
              Expanded(child: _TimeChip('🌅', l.sunrise, _t(context, p.sunrise))),
              const SizedBox(width: 8),
              Expanded(child: _TimeChip('🌇', l.sunset, _t(context, p.sunset))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _TimeChip('🌝', l.moonrise, p.moonrise == null ? '—' : _t(context, p.moonrise!))),
              const SizedBox(width: 8),
              Expanded(child: _TimeChip('🌘', l.moonset, p.moonset == null ? '—' : _t(context, p.moonset!))),
            ]),
            const SizedBox(height: 12),
            _Heading(l.inauspiciousTimes),
            _Row('⛔', l.rahuKaal, range(p.rahuKaal), color: KjdColors.kumkum),
            _Row('⚠️', l.yamaganda, range(p.yamaganda)),
            _Row('⚠️', l.gulikaKaal, range(p.gulika)),
            const SizedBox(height: 6),
            _Heading(l.auspiciousTime),
            _Row('✅', l.abhijitMuhurta, range(p.abhijit), color: KjdColors.success),
            const SizedBox(height: 8),
            Text(l.computedData, style: const TextStyle(fontSize: 11, color: KjdColors.saffron)),
          ]),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: KjdColors.kumkumDark)),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.label, this.value, {this.color});
  final String icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 24, child: Text(icon, style: const TextStyle(fontSize: 14))),
          SizedBox(
            width: 104,
            child: Text(label, style: const TextStyle(color: KjdColors.inkMuted, fontSize: 13.5)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.35, color: color)),
          ),
        ]),
      );
}

class _TimeChip extends StatelessWidget {
  const _TimeChip(this.icon, this.label, this.time);
  final String icon;
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: KjdColors.goldLight, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 11, color: KjdColors.inkMuted)),
              Text(time, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ]),
          ),
        ]),
      );
}

class _FestivalRow extends StatelessWidget {
  const _FestivalRow({required this.f, required this.selected, required this.onTap});
  final FestivalDay f;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vrat = f.festival.kind == FestivalKind.vrat;
    final p = dayPanchang(f.date);
    final sankashti = f.festival.id.startsWith('sankashti');
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Material(
        color: selected ? KjdColors.goldLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(children: [
              Container(
                width: 46,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: vrat ? KjdColors.saffron.withValues(alpha: .12) : KjdColors.kumkum.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  Text(localDigits(context, f.date.day),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: vrat ? KjdColors.saffron : KjdColors.kumkum)),
                  Text(DateFormat('E', context.lang).format(f.date), style: const TextStyle(fontSize: 10)),
                ]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.festival.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    [
                      '${p.masa} ${p.paksha} ${p.tithis.first.name}',
                      if (sankashti && p.moonrise != null) '${context.l10n.moonrise} ${_t(context, p.moonrise!)}',
                    ].join(' • '),
                    style: const TextStyle(fontSize: 12, color: KjdColors.inkMuted),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ProgrammeRow extends StatelessWidget {
  const _ProgrammeRow({required this.e, required this.selected, required this.onTap});
  final CalendarEvent e;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = dayPanchang(e.date);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Material(
        color: selected ? KjdColors.goldLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(children: [
              Container(
                width: 46,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: KjdColors.success.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  Text(localDigits(context, e.date.day),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: KjdColors.success)),
                  Text(DateFormat('E', context.lang).format(e.date), style: const TextStyle(fontSize: 10)),
                ]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    [if (e.location.isNotEmpty) '📍 ${e.location}', '${p.masa} ${p.paksha} ${p.tithis.first.name}']
                        .join(' • '),
                    style: const TextStyle(fontSize: 12, color: KjdColors.inkMuted),
                  ),
                ]),
              ),
              if (e.photoUrl case final url? when url.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: NetImage(url, width: 52, height: 52),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
