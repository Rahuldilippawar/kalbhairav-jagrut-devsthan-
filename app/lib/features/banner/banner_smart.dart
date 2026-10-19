import 'package:kjd_core/kjd_core.dart';

import 'festival_picker.dart';

/// Ready-made messages per category for "✨ नवीन संदेश". `{name}` is filled
/// with the name typed in the studio.
const _birthday = [
  '{name} यांना वाढदिवसाच्या हार्दिक शुभेच्छा! श्री काळभैरव महाराज आपणास उत्तम आरोग्य, दीर्घायुष्य आणि यश देवोत.',
  '{name}, आपले आयुष्य आनंद, सुख आणि समाधानाने भरलेले राहो. वाढदिवसाच्या मनःपूर्वक शुभेच्छा!',
  'जन्मदिनाच्या शुभ प्रसंगी {name} यांना भैरवनाथांचा आशीर्वाद लाभो. आपल्या सर्व इच्छा पूर्ण होवोत.',
  '{name} यांना वाढदिवसाच्या कोटी कोटी शुभेच्छा! नवे वर्ष नवी उमेद आणि नवे यश घेऊन येवो.',
  'आपल्या प्रेमळ स्वभावाला आणि सेवाभावाला सलाम! {name} यांना वाढदिवसाच्या खूप खूप शुभेच्छा.',
  'श्री काळभैरवाच्या कृपेने {name} यांचे जीवन सदैव मंगलमय राहो. वाढदिवसाच्या हार्दिक शुभेच्छा!',
];
const _anniversary = [
  '{name} यांना लग्नाच्या वाढदिवसाच्या हार्दिक शुभेच्छा! आपले सहजीवन असेच प्रेमाने फुलत राहो.',
  'सात जन्मांचे हे नाते सदैव अतूट राहो. {name} यांना विवाह वर्धापन दिनाच्या मनःपूर्वक शुभेच्छा!',
  'श्री काळभैरव महाराज {name} यांच्या संसारात सुख, शांती आणि समृद्धी नांदवोत.',
  '{name}, एकमेकांच्या साथीने आयुष्याचा प्रवास असाच आनंदी राहो. वर्धापन दिनाच्या शुभेच्छा!',
  'प्रेम, विश्वास आणि समर्पणाचे हे नाते सदैव बहरत राहो. {name} यांना हार्दिक शुभेच्छा!',
];
const _festival = [
  'हा सण आपल्या जीवनात सुख, समृद्धी आणि आरोग्य घेऊन येवो. जय काळभैरव!',
  'सणाच्या मंगल प्रसंगी आपणा सर्वांना श्री काळभैरव जागृत देवस्थान, रुंधाटी तर्फे हार्दिक शुभेच्छा.',
  'उत्सवाचा आनंद, भक्तीचा उत्साह आणि कुटुंबाचा सहवास — सर्वांना मंगलमय शुभेच्छा!',
  'भैरवनाथांच्या कृपेने हा सण आपल्या घरात आनंदाची बरसात करो.',
  'परंपरा जपू या, आनंद वाटू या. सणाच्या मनःपूर्वक शुभेच्छा!',
];
const _event = [
  'मंदिरातील कार्यक्रमास आपण सहकुटुंब, सहपरिवार उपस्थित राहावे ही नम्र विनंती.',
  'या पवित्र कार्यक्रमात सहभागी होऊन भैरवनाथांचा आशीर्वाद घ्यावा, ही आग्रहाची विनंती.',
  'सर्व भाविकांनी कार्यक्रमास वेळेवर उपस्थित राहून सहकार्य करावे.',
  'आपल्या उपस्थितीने कार्यक्रमाची शोभा वाढवावी, ही विनंती. जय काळभैरव!',
];
const _jayanti = [
  'महापुरुषांच्या विचारांना विनम्र अभिवादन. त्यांचे कार्य आम्हांस सदैव प्रेरणा देवो.',
  'जयंतीनिमित्त कोटी कोटी प्रणाम. त्यांच्या शिकवणीचा मार्ग आपण सर्वांनी अनुसरू या.',
  'त्यांच्या त्याग, सेवा आणि विचारांना शतशः नमन.',
];
const _announcement = [
  'सर्व भाविकांना कळविण्यात येते की…',
  'मंदिर व्यवस्थापनातर्फे सर्व भाविकांना नम्र सूचना…',
  'भाविकांनी दर्शनासाठी रांगेत उभे राहून सहकार्य करावे.',
  'मंदिर परिसर स्वच्छ ठेवण्यास सहकार्य करावे, ही विनंती.',
];

/// Message ideas for [category]; the daily list rotates through the 200
/// built-in greetings.
List<String> messageIdeas(BannerCategory category) => switch (category) {
      BannerCategory.birthday => _birthday,
      BannerCategory.anniversary => _anniversary,
      BannerCategory.festival => _festival,
      BannerCategory.event => _event,
      BannerCategory.jayanti => _jayanti,
      BannerCategory.announcement => _announcement,
      BannerCategory.dailySubhechha || BannerCategory.special || BannerCategory.tithi => dailySubhechha,
    };

/// Colour themes the devotee can apply over any template (dark → light).
const bannerPalettes = <String, List<int>>{
  'केशरी': [0xFF7F0000, 0xFFD84315, 0xFFFF8F00],
  'कुंकू': [0xFF5D0000, 0xFFB71C1C, 0xFFF57C00],
  'सोनेरी': [0xFF3E1500, 0xFF8D3B00, 0xFFE6A100],
  'भगवा': [0xFF4E1600, 0xFFBF360C, 0xFFFF9800],
  'रात्र': [0xFF070B26, 0xFF1A237E, 0xFF3949AB],
  'विठ्ठल': [0xFF0A1236, 0xFF1C2E7A, 0xFF4A6CD4],
  'शिव': [0xFF0B1A2E, 0xFF263E5E, 0xFF4F7CA8],
  'हिरवा': [0xFF0B3D12, 0xFF2E7D32, 0xFF8BC34A],
  'गुलाबी': [0xFF6A0036, 0xFFC2185B, 0xFFFF7043],
  'जांभळा': [0xFF1A0033, 0xFF4A148C, 0xFFE65100],
  'काळा': [0xFF0D0D0D, 0xFF3E0000, 0xFF7F0000],
};

/// One tap-ready banner suggested for today.
class BannerSuggestion {
  const BannerSuggestion({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.category,
    this.festival,
    this.name,
    this.headline,
    this.message,
  });
  final String icon;
  final String title;
  final String subtitle;
  final BannerCategory category;
  final FestivalDay? festival;
  final String? name;
  final String? headline;
  final String? message;
}

bool _sameDay(DateTime? d, DateTime today) => d != null && d.month == today.month && d.day == today.day;

/// What a devotee most likely wants to share right now: today's festivals
/// and programmes, family birthdays and anniversaries, tomorrow's festival
/// and a greeting for the time of day.
List<BannerSuggestion> smartSuggestions({
  required DateTime now,
  required List<FestivalDay> festivals,
  required List<CalendarEvent> programmes,
  required TithiInfo tithi,
  DevoteeProfile? profile,
  List<FamilyMember> family = const [],
}) {
  final today = dateOnly(now);
  final tomorrow = today.add(const Duration(days: 1));
  final out = <BannerSuggestion>[];

  for (final f in festivals.where((f) => f.date == today)) {
    out.add(BannerSuggestion(icon: '🪔', title: f.festival.name, subtitle: 'आजचा सण', category: f.festival.category, festival: f));
  }
  for (final e in programmes.where((e) => e.date == today || e.date == tomorrow)) {
    final when = e.date == today ? 'आज' : 'उद्या';
    out.add(BannerSuggestion(
      icon: '🛕',
      title: e.title,
      subtitle: '$when देवस्थानात',
      category: BannerCategory.event,
      headline: '🙏 सस्नेह निमंत्रण',
      message: [
        '${e.title} — $when, ${formatDate(e.date)}',
        if (e.location.isNotEmpty) '📍 ${e.location}',
        'या कार्यक्रमास आपण सहकुटुंब, सहपरिवार उपस्थित राहावे ही नम्र विनंती.',
      ].join('\n'),
    ));
  }
  if (profile != null) {
    if (_sameDay(profile.dob, today) && profile.name.isNotEmpty) {
      out.add(BannerSuggestion(icon: '🎂', title: profile.name, subtitle: 'आपला वाढदिवस', category: BannerCategory.birthday, name: profile.name));
    }
    if (_sameDay(profile.anniversary, today)) {
      final names = [profile.name, profile.spouseName].whereType<String>().where((s) => s.isNotEmpty).join(' व ');
      out.add(BannerSuggestion(icon: '💞', title: names, subtitle: 'लग्नाचा वाढदिवस', category: BannerCategory.anniversary, name: names));
    }
  }
  for (final m in family.where((m) => _sameDay(m.dob, today))) {
    out.add(BannerSuggestion(icon: '🎂', title: m.name, subtitle: '${m.relation.labelMr} – वाढदिवस', category: BannerCategory.birthday, name: m.name));
  }
  for (final f in festivals.where((f) => f.date == tomorrow && f.festival.kind != FestivalKind.vrat)) {
    out.add(BannerSuggestion(icon: '📆', title: f.festival.name, subtitle: 'उद्याचा सण', category: f.festival.category, festival: f));
  }
  final greeting = now.hour < 12
      ? ('🌅', 'शुभ प्रभात', '🌅 शुभ प्रभात 🙏')
      : now.hour < 17
          ? ('☀️', 'शुभ दुपार', '☀️ शुभ दुपार 🙏')
          : now.hour < 21
              ? ('🪔', 'शुभ संध्या', '🪔 शुभ संध्या 🙏')
              : ('🌙', 'शुभ रात्री', '🌙 शुभ रात्री 🙏');
  out.add(BannerSuggestion(
    icon: greeting.$1,
    title: greeting.$2,
    subtitle: 'आजचा संदेश',
    category: BannerCategory.dailySubhechha,
    headline: greeting.$3,
    message: builtInGreeting(now).message,
  ));
  out.add(BannerSuggestion(
    icon: '📅',
    title: tithi.tithi,
    subtitle: 'आजची तिथी',
    category: BannerCategory.tithi,
    message: tithiBannerMessage(tithi, programmes.where((e) => e.date == today).toList()),
  ));
  return out;
}
