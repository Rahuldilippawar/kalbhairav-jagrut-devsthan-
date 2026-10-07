import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../widgets/common.dart';
import 'banner_painters.dart';

/// Output shape of a banner. Exports are 1080px on the short side.
enum BannerFormat {
  square(1),
  story(9 / 16),
  landscape(16 / 9);

  const BannerFormat(this.aspect);
  final double aspect;
}

const _goldStops = [Color(0xFFFFF6C8), Color(0xFFFFD54F), Color(0xFFC9930E), Color(0xFFFFE082)];
const _goldFrame = Color(0xFFE8C04A);
const _templeName = 'श्री काळभैरव जागृत देवस्थान';
const _village = 'रुंधाटी';

/// Temple-branded banner drawn in one of [BannerTemplate.layouts]: logo,
/// temple name, headline, optional photo, message, sender, date and footer.
/// Rendered to PNG for sharing.
class BannerCanvas extends StatelessWidget {
  const BannerCanvas({
    super.key,
    required this.template,
    required this.headline,
    required this.message,
    this.photo,
    this.date,
    this.format = BannerFormat.square,
    this.senderName,
    this.senderPhoto,
  });

  final BannerTemplate template;
  final String headline;
  final String message;
  final Uint8List? photo;
  final String? date;
  final BannerFormat format;
  final String? senderName;
  final Uint8List? senderPhoto;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: format.aspect,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return _Layout(this, w, w / format.aspect).build();
        },
      ),
    );
  }
}

/// Computes sizes and colours once per build and assembles the layers.
class _Layout {
  _Layout(this.b, this.w, this.h) : u = math.min(w, h) / 360;

  final BannerCanvas b;
  final double w;
  final double h;

  /// Scale unit: typography and decoration are designed on a 360px canvas.
  final double u;

  BannerTemplate get t => b.template;
  String get layout => t.layout;
  bool get minimal => layout == 'minimal';
  bool get hero => layout == 'photoHero';
  bool get landscape => b.format == BannerFormat.landscape;
  bool get story => b.format == BannerFormat.story;

  Color get text => minimal ? const Color(0xFF3E2723) : Color(t.textColor);
  Color get accent => minimal ? const Color(0xFF8B0000) : Color(t.accentColor);

  /// Light text on a dark background gets the gilded headline.
  bool get gold => !minimal && text.computeLuminance() > .5;

  String get headFont => bannerFontFamily(t.headlineFont);
  String get bodyFont => bannerFontFamily(t.bodyFont);

  List<Shadow>? get shadows => minimal
      ? null
      : [Shadow(color: Colors.black.withValues(alpha: .45), blurRadius: 6 * u, offset: Offset(0, 1.5 * u))];

  Widget build() {
    return ClipRect(
      child: Stack(fit: StackFit.expand, children: [_background(), ..._underlays(), _content(), ..._overlays()]),
    );
  }

  // ---------------------------------------------------------------- layers

  Widget _background() {
    final colors = [for (final g in t.gradient) Color(g)];
    final Decoration deco = switch (layout) {
      'minimal' => const BoxDecoration(
        gradient: RadialGradient(radius: 1.1, colors: [Color(0xFFFFFDF5), Color(0xFFFFEFD0)]),
      ),
      'royal' => BoxDecoration(
        gradient: RadialGradient(center: const Alignment(0, -.45), radius: 1.2, colors: colors.reversed.toList()),
      ),
      'photoHero' => BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
      ),
      _ => BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      ),
    };
    return DecoratedBox(
      decoration: deco,
      child: t.backgroundUrl == null
          ? const SizedBox.expand()
          : Opacity(opacity: minimal ? .15 : .35, child: NetImage(t.backgroundUrl)),
    );
  }

  List<Widget> _underlays() => switch (layout) {
    'classic' => [
      Center(
        child: Text(
          'ॐ',
          style: TextStyle(fontFamily: headFont, fontSize: 280 * u, height: 1, color: text.withValues(alpha: .06)),
        ),
      ),
      Positioned(
        right: -90 * u,
        top: -90 * u,
        width: 260 * u,
        height: 260 * u,
        child: CustomPaint(painter: SunRaysPainter(color: accent.withValues(alpha: .28))),
      ),
    ],
    'festive' => [
      Positioned.fill(
        child: CustomPaint(painter: SunRaysPainter(color: accent.withValues(alpha: .12), rays: 36)),
      ),
    ],
    'photoHero' => [_heroImage()],
    _ => const [],
  };

  List<Widget> _overlays() => switch (layout) {
    'royal' => [
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: OrnateBorderPainter(color: _goldFrame, unit: u),
          ),
        ),
      ),
    ],
    'festive' => [
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 56 * u,
        child: CustomPaint(painter: ToranPainter(unit: u)),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: 44 * u,
        child: CustomPaint(
          painter: DiyaRowPainter(unit: u, count: landscape ? 9 : (story ? 5 : 6)),
        ),
      ),
    ],
    'minimal' => [
      Positioned.fill(
        child: Padding(
          padding: EdgeInsets.all(10 * u),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: accent, width: 1.6 * u),
              borderRadius: BorderRadius.circular(4 * u),
            ),
            child: Padding(
              padding: EdgeInsets.all(4 * u),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: accent.withValues(alpha: .35), width: .7 * u),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
    _ => const [],
  };

  /// Large photo (or sun-ray logo) at the top, fading into the background.
  Widget _heroImage() {
    final Widget art = b.photo != null
        ? Image.memory(b.photo!, fit: BoxFit.cover, gaplessPlayback: true)
        : Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: SunRaysPainter(color: accent.withValues(alpha: .55), rays: 32)),
              Center(child: TempleLogo(size: 130 * u)),
            ],
          );
    final faded = ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => LinearGradient(
        begin: landscape ? Alignment.centerLeft : Alignment.topCenter,
        end: landscape ? Alignment.centerRight : Alignment.bottomCenter,
        colors: const [Colors.white, Colors.white, Colors.transparent],
        stops: const [0, .62, 1],
      ).createShader(r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          art,
          // Top scrim keeps the header readable on bright photos.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: .55), Colors.transparent],
                stops: const [0, .35],
              ),
            ),
          ),
        ],
      ),
    );
    return landscape
        ? Positioned(left: 0, top: 0, bottom: 0, width: w * .5, child: faded)
        : Positioned(left: 0, right: 0, top: 0, height: h * (story ? .52 : .58), child: faded);
  }

  // --------------------------------------------------------------- content

  EdgeInsets get _padding => switch (layout) {
    'royal' => EdgeInsets.fromLTRB(28 * u, 26 * u, 28 * u, 24 * u),
    'festive' => EdgeInsets.fromLTRB(18 * u, 50 * u, 18 * u, 46 * u),
    'minimal' => EdgeInsets.all(26 * u),
    'photoHero' when landscape => EdgeInsets.fromLTRB(w * .46, 16 * u, 16 * u, 16 * u),
    _ => EdgeInsets.all(16 * u),
  };

  Widget _content() {
    final heroGap = hero && !landscape;
    return Padding(
      padding: _padding,
      child: LayoutBuilder(
        builder: (context, c) {
          return Column(
            children: [
              _header(),
              if (heroGap) Spacer(flex: story ? 4 : 5) else SizedBox(height: 6 * u),
              Expanded(
                flex: heroGap ? 6 : 1,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(width: c.maxWidth, child: _middle()),
                  ),
                ),
              ),
              SizedBox(height: 6 * u),
              ?_sender(),
              if (b.date != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 4 * u),
                  child: Text(
                    b.date!,
                    style: TextStyle(
                      fontFamily: bodyFont,
                      color: text.withValues(alpha: .85),
                      fontSize: 11 * u,
                      shadows: shadows,
                    ),
                  ),
                ),
              _footer(),
            ],
          );
        },
      ),
    );
  }

  Widget _logo(double size) => t.logoUrl != null
      ? ClipOval(
          child: NetImage(t.logoUrl, width: size, height: size),
        )
      : TempleLogo(size: size);

  Widget _header() {
    final headerText = hero ? Colors.white : text;
    final nameStyle = TextStyle(
      fontFamily: layout == 'royal' ? headFont : bodyFont,
      color: headerText,
      fontWeight: FontWeight.w700,
      fontSize: (layout == 'royal' ? 17 : 15) * u,
      shadows: shadows,
    );
    final villageStyle = TextStyle(
      fontFamily: bodyFont,
      color: hero ? _goldFrame : accent,
      fontWeight: FontWeight.w700,
      fontSize: 12 * u,
      letterSpacing: 1.5 * u,
      shadows: shadows,
    );
    final centred = !hero && layout != 'classic';
    if (!centred || landscape) {
      return Row(
        mainAxisAlignment: centred ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          // The no-photo hero already shows a large logo.
          if (t.showLogo && !(hero && b.photo == null)) ...[_logo(52 * u), SizedBox(width: 8 * u)],
          Flexible(
            child: Column(
              crossAxisAlignment: centred ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_templeName, style: nameStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(_village, style: villageStyle),
              ],
            ),
          ),
        ],
      );
    }
    final logoSize = (story ? 70 : 58) * u;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (t.showLogo)
          SizedBox(
            width: logoSize,
            height: logoSize,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (layout == 'royal')
                  Positioned(
                    left: -logoSize * .5,
                    top: -logoSize * .5,
                    width: logoSize * 2,
                    height: logoSize * 2,
                    child: CustomPaint(painter: SunRaysPainter(color: _goldFrame.withValues(alpha: .55))),
                  ),
                _logo(logoSize),
              ],
            ),
          ),
        SizedBox(height: 4 * u),
        Text(_templeName, style: nameStyle, textAlign: TextAlign.center),
        Text(_village, style: villageStyle),
      ],
    );
  }

  TextStyle _headlineStyle(double size) {
    final base = TextStyle(fontFamily: headFont, fontSize: size, height: 1.3, shadows: shadows);
    if (!gold) return base.copyWith(color: accent);
    // Shader repeats per line (mirror) so every line of a wrapped
    // headline gets the same metallic sweep.
    return base.copyWith(
      foreground: Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _goldStops,
          tileMode: TileMode.mirror,
        ).createShader(Rect.fromLTWH(0, 0, 10, size * 1.3)),
    );
  }

  Widget _ornament() {
    final c = minimal ? accent : (gold ? _goldFrame : accent);
    Widget line() => Container(
      width: 46 * u,
      height: 1.4 * u,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [c.withValues(alpha: 0), c])),
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * u),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          line(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6 * u),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(width: 7 * u, height: 7 * u, color: c),
            ),
          ),
          Transform.flip(flipX: true, child: line()),
        ],
      ),
    );
  }

  Widget _ringPhoto(Uint8List bytes, double size) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .04),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const SweepGradient(colors: [..._goldStops, Color(0xFFFFF6C8)]),
      boxShadow: [BoxShadow(color: accent.withValues(alpha: .55), blurRadius: size * .2, spreadRadius: size * .02)],
    ),
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size * .015),
        image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
      ),
    ),
  );

  Widget _middle() {
    final photo = hero ? null : b.photo;
    final message = Text(
      b.message,
      textAlign: landscape && photo != null ? TextAlign.start : TextAlign.center,
      maxLines: 12,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: bodyFont,
        color: text,
        fontSize: (photo != null ? 15.5 : 18) * u,
        height: 1.45,
        fontWeight: FontWeight.w700,
        shadows: shadows,
      ),
    );
    final headSize = (story ? 30 : 26) * u;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (b.headline.isNotEmpty) Text(b.headline, textAlign: TextAlign.center, style: _headlineStyle(headSize)),
        if (layout != 'classic' && layout != 'photoHero') _ornament() else SizedBox(height: 10 * u),
        if (photo != null && landscape)
          Row(
            children: [
              _ringPhoto(photo, 120 * u),
              SizedBox(width: 14 * u),
              Expanded(child: message),
            ],
          )
        else ...[
          if (photo != null) ...[_ringPhoto(photo, (story ? 170 : 116) * u), SizedBox(height: 12 * u)],
          message,
        ],
      ],
    );
  }

  Widget? _sender() {
    final name = b.senderName?.trim() ?? '';
    if (name.isEmpty && b.senderPhoto == null) return null;
    return Padding(
      padding: EdgeInsets.only(bottom: 6 * u),
      child: Container(
        padding: EdgeInsets.fromLTRB(b.senderPhoto != null ? 4 * u : 14 * u, 4 * u, 14 * u, 4 * u),
        decoration: BoxDecoration(
          color: minimal ? accent.withValues(alpha: .06) : Colors.black.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(30 * u),
          border: Border.all(color: (minimal ? accent : _goldFrame).withValues(alpha: .6), width: .8 * u),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (b.senderPhoto != null) ...[_ringPhoto(b.senderPhoto!, 40 * u), SizedBox(width: 8 * u)],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'शुभेच्छुक',
                  style: TextStyle(
                    fontFamily: bodyFont,
                    fontSize: 10 * u,
                    color: text.withValues(alpha: .8),
                    height: 1.1,
                  ),
                ),
                if (name.isNotEmpty)
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: bodyFont,
                      fontSize: 15 * u,
                      fontWeight: FontWeight.w800,
                      color: gold ? _goldStops[1] : accent,
                      height: 1.2,
                      shadows: shadows,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    final filled = minimal || layout == 'festive';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 6 * u, horizontal: 10 * u),
      decoration: BoxDecoration(
        color: filled ? (minimal ? accent : Colors.black.withValues(alpha: .35)) : Colors.black26,
        borderRadius: BorderRadius.circular(20 * u),
        border: layout == 'royal' ? Border.all(color: _goldFrame.withValues(alpha: .7), width: .8 * u) : null,
      ),
      child: Text(
        t.footer,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: bodyFont,
          color: minimal ? Colors.white : text,
          fontSize: 11.5 * u,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Designer templates bundled with the app (same as the admin starter set).
final List<BannerTemplate> builtinBannerTemplates = [
  for (final e in buildDemoSeed(DateTime(2026))[Col.bannerTemplates]!.entries) BannerTemplate.fromMap(e.key, e.value),
]..sort((a, b) => a.order.compareTo(b.order));

/// Used when no template exists for a category.
BannerTemplate fallbackTemplate(BannerCategory c) => BannerTemplate(
  id: 'builtin-${c.name}',
  name: c.labelMr,
  category: c,
  layout: switch (c) {
    BannerCategory.birthday || BannerCategory.anniversary || BannerCategory.special => 'royal',
    BannerCategory.festival || BannerCategory.event => 'festive',
    BannerCategory.announcement || BannerCategory.tithi => 'minimal',
    _ => 'classic',
  },
  headlineFont: 'yatraOne',
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
