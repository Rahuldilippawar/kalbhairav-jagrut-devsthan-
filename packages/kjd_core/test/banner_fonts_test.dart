import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kjd_core/kjd_core.dart';

Future<void> _load(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = File('assets/fonts/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
  }
  await loader.load();
}

double _width(String family, String text, Locale locale) {
  final p = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontFamily: family, fontSize: 40, locale: locale)),
    textDirection: TextDirection.ltr,
  )..layout();
  return p.width;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const sample = 'हार्दिक शुभेच्छा • क्षमा • लक्ष्मी';

  test('every banner font key maps to a bundled family with Devanagari glyphs', () async {
    final files = Directory('assets/fonts').listSync().map((f) => f.uri.pathSegments.last).toSet();
    for (final key in BannerTemplate.fonts.keys) {
      final family = bannerFontFamily(key).split('/').last;
      expect(files.any((f) => f.startsWith('$family-')), isTrue, reason: '$key → $family has no font file');
    }
  });

  test("Yatra One's Marathi rules split conjuncts; banners shape with standard forms", () async {
    await _load('YatraOne', ['YatraOne-Regular.ttf']);
    await _load('Mukta', ['Mukta-Regular.ttf']);
    final mr = _width('YatraOne', sample, const Locale('mr'));
    final std = _width('YatraOne', sample, bannerTextLocale);
    // Visible halants ("हार्‌दिक", "क्‌षमा") make the Marathi-shaped run wider.
    expect(mr, greaterThan(std + 5));
    // Mukta only swaps a letter variant or two.
    expect(_width('Mukta', sample, const Locale('mr')), closeTo(_width('Mukta', sample, bannerTextLocale), 2));
  });
}
