import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../widgets/common.dart';

/// Temple-branded square banner: logo, temple name, headline, optional
/// photo, message, date and footer. Rendered to PNG for sharing.
class BannerCanvas extends StatelessWidget {
  const BannerCanvas({
    super.key,
    required this.template,
    required this.headline,
    required this.message,
    this.photo,
    this.date,
  });

  final BannerTemplate template;
  final String headline;
  final String message;
  final Uint8List? photo;
  final String? date;

  @override
  Widget build(BuildContext context) {
    final text = Color(template.textColor);
    final accent = Color(template.accentColor);
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (context, c) {
        // Scale typography with the canvas so the preview and export match.
        final u = c.maxWidth / 360;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [for (final g in template.gradient) Color(g)],
            ),
          ),
          child: Stack(fit: StackFit.expand, children: [
            if (template.backgroundUrl != null)
              Opacity(opacity: .35, child: NetImage(template.backgroundUrl)),
            // Decorative sun-ray ring echoing the logo.
            Positioned(
              right: -60 * u,
              top: -60 * u,
              child: Container(
                width: 200 * u,
                height: 200 * u,
                decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: .12)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16 * u),
              child: Column(children: [
                Row(children: [
                  TempleLogo(size: 56 * u),
                  SizedBox(width: 8 * u),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('श्री काळभैरव जागृत देवस्थान',
                          style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 15 * u)),
                      Text('रुंधाटी', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 12 * u)),
                    ]),
                  ),
                ]),
                const Spacer(),
                if (headline.isNotEmpty)
                  Text(headline,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 22 * u, height: 1.25)),
                SizedBox(height: 10 * u),
                if (photo != null) ...[
                  Container(
                    width: 110 * u,
                    height: 110 * u,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 3 * u),
                      image: DecorationImage(image: MemoryImage(photo!), fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(height: 10 * u),
                ],
                Text(message,
                    textAlign: TextAlign.center,
                    maxLines: photo != null ? 4 : 7,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: text, fontSize: (photo != null ? 14 : 16) * u, height: 1.45, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (date != null)
                  Text(date!, style: TextStyle(color: text.withValues(alpha: .85), fontSize: 11 * u)),
                SizedBox(height: 6 * u),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 6 * u),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20 * u)),
                  child: Text(template.footer,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: text, fontSize: 11.5 * u, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ]),
        );
      }),
    );
  }
}

/// Used when the admin has not created a template for a category yet.
BannerTemplate fallbackTemplate(BannerCategory c) => BannerTemplate(
      id: 'builtin-${c.name}',
      name: c.labelMr,
      category: c,
      headline: switch (c) {
        BannerCategory.birthday => '🎂 वाढदिवसाच्या हार्दिक शुभेच्छा',
        BannerCategory.anniversary => '💍 विवाह वर्धापन दिनाच्या हार्दिक शुभेच्छा',
        BannerCategory.dailySubhechha => '🌅 शुभ प्रभात 🙏',
        BannerCategory.tithi => '📅 आजची तिथी',
        BannerCategory.festival => '🚩 उत्सवाच्या हार्दिक शुभेच्छा',
        BannerCategory.event => '🙏 सस्नेह निमंत्रण',
        BannerCategory.jayanti => '🌺 जयंतीनिमित्त विनम्र अभिवादन',
        BannerCategory.announcement => '📢 मंदिर सूचना',
        BannerCategory.special => '🔱 जय काळभैरव',
      },
      defaultMessage: switch (c) {
        BannerCategory.birthday => '{name} यांना वाढदिवसाच्या हार्दिक शुभेच्छा. श्री काळभैरव महाराजांची कृपा सदैव राहो.',
        BannerCategory.anniversary => '{name} यांना विवाह वर्धापन दिनाच्या हार्दिक शुभेच्छा.',
        _ => null,
      },
    );
