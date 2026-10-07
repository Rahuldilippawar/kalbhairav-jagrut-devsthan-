import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kjd_app/features/banner/banner_canvas.dart';
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
}
