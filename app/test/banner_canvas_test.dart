import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kjd_app/features/banner/banner_canvas.dart';
import 'package:kjd_app/features/banner/festival_art.dart';
import 'package:kjd_core/kjd_core.dart';

// 1×1 transparent PNG.
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

void main() {
  const long = 'श्री काळभैरव महाराजांच्या कृपेने आपला आजचा दिवस सुख, शांती आणि समाधानाने भरलेला जावो. '
      'श्री काळभैरव महाराजांच्या कृपेने आपला आजचा दिवस सुख, शांती आणि समाधानाने भरलेला जावो.';

  for (final layout in BannerTemplate.layouts.keys) {
    for (final format in BannerFormat.values) {
      testWidgets('renders $layout × ${format.name} without overflow', (tester) async {
        for (final withPhoto in [false, true]) {
          await tester.pumpWidget(MaterialApp(
            home: Center(
              child: SizedBox(
                width: 360,
                child: BannerCanvas(
                  template: BannerTemplate(
                    id: 't',
                    name: 't',
                    category: BannerCategory.birthday,
                    layout: layout,
                    headline: '🎂 वाढदिवसाच्या हार्दिक शुभेच्छा',
                  ),
                  headline: '🎂 वाढदिवसाच्या हार्दिक शुभेच्छा',
                  message: long,
                  photo: withPhoto ? _png : null,
                  date: '07 Oct 2026',
                  format: format,
                  senderName: 'राहुल पवार',
                  senderPhoto: withPhoto ? _png : null,
                ),
              ),
            ),
          ));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.text('शुभेच्छुक'), findsOneWidget);
        }
      });
    }
  }

  test('layout survives a Firestore round trip and defaults to classic', () {
    const t = BannerTemplate(id: 'a', name: 'a', category: BannerCategory.festival, layout: 'festive');
    expect(BannerTemplate.fromMap('a', t.toMap()).layout, 'festive');
    expect(BannerTemplate.fromMap('a', {...t.toMap(), 'layout': 'unknown'}).layout, 'classic');
  });

  testWidgets('calendar emoji never appear on a banner', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(
        child: SizedBox(
          width: 360,
          child: BannerCanvas(
            template: BannerTemplate(id: 't', name: 't', category: BannerCategory.tithi),
            headline: '📅 आजची तिथी',
            message: '🗓️ सोमवार\n📆 अष्टमी',
          ),
        ),
      ),
    ));
    expect(find.text('आजची तिथी'), findsOneWidget);
    expect(find.text('सोमवार\nअष्टमी'), findsOneWidget);
  });

  for (final layout in BannerTemplate.layouts.keys) {
    testWidgets('festival artwork fits the $layout layout in every format', (tester) async {
      for (final format in BannerFormat.values) {
        await tester.pumpWidget(MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              child: BannerCanvas(
                template: BannerTemplate(id: 't', name: 't', category: BannerCategory.festival, layout: layout),
                headline: '🪔 दिवाळीच्या हार्दिक शुभेच्छा',
                message: long,
                date: '08 Nov 2026',
                format: format,
                senderName: 'राहुल पवार',
                art: festivalArt('lakshmipujan'),
              ),
            ),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(FestivalArt), findsOneWidget);
      }
    });
  }

  test('every festival and monthly vrat has artwork', () {
    for (final f in festivalCatalog) {
      expect(festivalArt(f.id), isNotNull, reason: f.id);
    }
    for (final v in ['ekadashi-2026-10-06', 'sankashti-2026-10-29', 'fest-dasara']) {
      expect(festivalArt(v), isNotNull, reason: v);
    }
  });

  test('deity festivals use a bundled painting', () {
    for (final id in ['lakshmipujan', 'ganeshchaturthi', 'mahashivratri', 'gokulashtami', 'dattajayanti', 'vasantpanchami', 'dasara', 'sankashti-2026-10-29']) {
      final asset = festivalDeity(id);
      expect(asset, isNotNull, reason: id);
      expect(File(asset!).existsSync(), isTrue, reason: asset);
    }
    expect(festivalDeity('makarsankranti'), isNull);
  });

  testWidgets('a deity painting fits every layout and format', (tester) async {
    for (final layout in BannerTemplate.layouts.keys) {
      for (final format in BannerFormat.values) {
        await tester.pumpWidget(MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              child: BannerCanvas(
                template: BannerTemplate(id: 't', name: 't', category: BannerCategory.festival, layout: layout),
                headline: '🪔 शुभ दीपावली – लक्ष्मीपूजन',
                message: long,
                format: format,
                art: festivalArt('lakshmipujan'),
                deity: festivalDeity('lakshmipujan'),
              ),
            ),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$layout $format');
      }
    }
  });
}
