import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'banner_painters.dart';

/// Hand-drawn festival artwork for banners: every festival and vrat gets a
/// fitting picture (diya, gudhi, kalash, modak …) without any photo.

/// Artwork for a festival / vrat id (dated vrat ids are `<type>-<date>`).
String? festivalArt(String? festivalId) {
  if (festivalId == null) return null;
  final id = festivalId.startsWith('fest-') ? festivalId.substring(5) : festivalId;
  return _artById[id] ?? _artById[id.split('-').first];
}

const _artById = {
  'gudhipadwa': 'gudhi',
  'newyear': 'sun',
  'swamisamarth': 'paduka',
  'ramnavami': 'bow',
  'hanumanjayanti': 'gada',
  'akshayatritiya': 'kalash',
  'narasimhajayanti': 'gada',
  'buddhapurnima': 'moon',
  'vatpurnima': 'banyan',
  'ashadhi': 'tulsi',
  'gurupurnima': 'paduka',
  'nagpanchami': 'snake',
  'raksha': 'rakhi',
  'gokulashtami': 'flute',
  'dahihandi': 'matki',
  'pola': 'flowers',
  'hartalika': 'flowers',
  'ganeshchaturthi': 'modak',
  'rishipanchami': 'flowers',
  'anantchaturdashi': 'modak',
  'ghatasthapana': 'kalash',
  'navratri2': 'kalash',
  'navratri3': 'kalash',
  'navratri4': 'kalash',
  'lalitapanchami': 'kalash',
  'navratri6': 'kalash',
  'navratri7': 'kalash',
  'durgashtami': 'trishul',
  'mahanavami': 'kalash',
  'dasara': 'bow',
  'kojagiri': 'moon',
  'vasubaras': 'diya',
  'dhanteras': 'diya',
  'narakchaturdashi': 'diya',
  'lakshmipujan': 'diya',
  'padwa': 'diya',
  'bhaubeej': 'diya',
  'kartiki': 'tulsi',
  'tulsivivah': 'tulsi',
  'tripurari': 'diya',
  'kalbhairavjayanti': 'trishul',
  'champashashthi': 'trishul',
  'gitajayanti': 'book',
  'dattajayanti': 'paduka',
  'bhogi': 'kite',
  'makarsankranti': 'kite',
  'ganeshjayanti': 'modak',
  'vasantpanchami': 'book',
  'rathasaptami': 'sun',
  'gajananprakat': 'paduka',
  'mahashivratri': 'shivling',
  'holi': 'holi',
  'dhulivandan': 'holi',
  'tukarambeej': 'paduka',
  'rangpanchami': 'holi',
  'savitribai': 'book',
  'republicday': 'tricolor',
  'shivjayanti': 'bhagwa',
  'marathibhashadin': 'book',
  'phulejayanti': 'book',
  'ambedkarjayanti': 'book',
  'maharashtradin': 'bhagwa',
  'shivrajyabhishek': 'bhagwa',
  'shahujayanti': 'book',
  'tilakjayanti': 'book',
  'independenceday': 'tricolor',
  'gandhijayanti': 'book',
  // Monthly vrats.
  'ekadashi': 'tulsi',
  'sankashti': 'modak',
  'vinayaki': 'modak',
  'kalashtami': 'trishul',
  'pradosh': 'shivling',
  'shivratri': 'shivling',
  'purnima': 'moon',
  'amavasya': 'diya',
};

/// Square festival illustration.
class FestivalArt extends StatelessWidget {
  const FestivalArt(this.art, {super.key, required this.size});
  final String art;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: art == 'flowers'
            ? CustomPaint(painter: LotusPainter(unit: size / 150))
            : CustomPaint(painter: FestivalArtPainter(art)),
      );
}

const _gold = [Color(0xFFFFF3B0), Color(0xFFFFC107), Color(0xFFB8860B)];
const _copper = [Color(0xFFFFCC80), Color(0xFFE65100), Color(0xFF8D3B00)];
const _leaf = Color(0xFF2E7D32);
const _leafLight = Color(0xFF66BB6A);
const _marigold = Color(0xFFFFA000);

class FestivalArtPainter extends CustomPainter {
  const FestivalArtPainter(this.art);
  final String art;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    // Soft halo behind every picture.
    final c = Offset(s / 2, s / 2);
    canvas.drawCircle(
      c,
      s * .5,
      Paint()
        ..shader = RadialGradient(colors: [const Color(0xFFFFF8E1).withValues(alpha: .55), const Color(0x00FFF8E1)])
            .createShader(Rect.fromCircle(center: c, radius: s * .5)),
    );
    switch (art) {
      case 'diya':
        _diya(canvas, s);
      case 'gudhi':
        _gudhi(canvas, s);
      case 'kalash':
        _kalash(canvas, s);
      case 'bow':
        _bow(canvas, s);
      case 'moon':
        _moon(canvas, s);
      case 'shivling':
        _shivling(canvas, s);
      case 'trishul':
        _trishul(canvas, s);
      case 'modak':
        _modak(canvas, s);
      case 'flute':
        _flute(canvas, s);
      case 'matki':
        _matki(canvas, s);
      case 'rakhi':
        _rakhi(canvas, s);
      case 'kite':
        _kite(canvas, s);
      case 'holi':
        _holi(canvas, s);
      case 'tulsi':
        _tulsi(canvas, s);
      case 'snake':
        _snake(canvas, s);
      case 'banyan':
        _banyan(canvas, s);
      case 'tricolor':
        _flag(canvas, s, tricolor: true);
      case 'bhagwa':
        _flag(canvas, s, tricolor: false);
      case 'book':
        _book(canvas, s);
      case 'sun':
        _sun(canvas, s);
      case 'paduka':
        _paduka(canvas, s);
      case 'gada':
        _gada(canvas, s);
    }
    canvas.restore();
  }

  // ---------------------------------------------------------------- helpers

  Paint _grad(List<Color> colors, Rect r, {bool vertical = true}) => Paint()
    ..shader = LinearGradient(
      begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
      end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
      colors: colors,
    ).createShader(r);

  void _glow(Canvas canvas, Offset c, double r, Color color) => canvas.drawCircle(
        c,
        r,
        Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)),
      );

  void _flame(Canvas canvas, Offset base, double h) {
    _glow(canvas, base.translate(0, -h * .5), h * 1.1, const Color(0xAAFFD54F));
    final p = Path()
      ..moveTo(base.dx, base.dy - h)
      ..quadraticBezierTo(base.dx + h * .38, base.dy - h * .35, base.dx, base.dy)
      ..quadraticBezierTo(base.dx - h * .38, base.dy - h * .35, base.dx, base.dy - h)
      ..close();
    canvas.drawPath(
      p,
      _grad(const [Color(0xFFFFFDE7), Color(0xFFFFC107), Color(0xFFE65100)], Rect.fromLTWH(base.dx - h * .4, base.dy - h, h * .8, h)),
    );
  }

  void _leafShape(Canvas canvas, Offset from, double angle, double len, Color color) {
    canvas.save();
    canvas.translate(from.dx, from.dy);
    canvas.rotate(angle);
    final p = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * .5, -len * .28, len, 0)
      ..quadraticBezierTo(len * .5, len * .28, 0, 0)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
    canvas.drawLine(Offset.zero, Offset(len * .9, 0), Paint()
      ..color = Colors.white.withValues(alpha: .35)
      ..strokeWidth = len * .03);
    canvas.restore();
  }

  void _flower(Canvas canvas, Offset c, double r, Color petal, Color centre) {
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r * .55, r * .48, Paint()..color = petal);
    }
    canvas.drawCircle(c, r * .45, Paint()..color = centre);
  }

  // --------------------------------------------------------------- motifs

  void _diya(Canvas canvas, double s) {
    // Rangoli dots ring.
    final c = Offset(s / 2, s * .62);
    for (var k = 0; k < 24; k++) {
      final a = k * 2 * math.pi / 24;
      canvas.drawCircle(c + Offset(math.cos(a) * s * .42, math.sin(a) * s * .16), s * .012,
          Paint()..color = [const Color(0xFFE91E63), const Color(0xFFFFC107), Colors.white][k % 3]);
    }
    // Clay diya: deep bowl with a spout and a gilded rim.
    final bowl = Path()
      ..moveTo(s * .16, s * .56)
      ..quadraticBezierTo(s * .5, s * .98, s * .84, s * .56)
      ..quadraticBezierTo(s * .88, s * .53, s * .9, s * .5)
      ..quadraticBezierTo(s * .85, s * .6, s * .82, s * .6)
      ..quadraticBezierTo(s * .5, s * .62, s * .16, s * .56)
      ..close();
    canvas.drawPath(bowl, _grad(_copper, Rect.fromLTWH(s * .16, s * .5, s * .8, s * .32)));
    canvas.drawOval(Rect.fromLTWH(s * .16, s * .52, s * .68, s * .09), _grad(_gold, Rect.fromLTWH(s * .16, s * .52, s * .68, s * .09)));
    canvas.drawOval(Rect.fromLTWH(s * .2, s * .535, s * .6, s * .06), Paint()..color = const Color(0xFF8D3B00));
    for (var k = 0; k < 7; k++) {
      canvas.drawCircle(Offset(s * (.3 + k * .067), s * (.7 + (k - 3).abs() * -.012 + .02)), s * .016,
          Paint()..color = const Color(0xFFFFE082));
    }
    _flame(canvas, Offset(s * .86, s * .5), s * .3);
  }

  void _gudhi(Canvas canvas, double s) {
    // Bamboo.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s * .48, s * .28, s * .04, s * .66), Radius.circular(s * .02)),
      _grad(const [Color(0xFFD7B56D), Color(0xFF8D6E2F)], Rect.fromLTWH(s * .48, 0, s * .04, s), vertical: false),
    );
    // Silk cloth.
    final cloth = Path()
      ..moveTo(s * .5, s * .22)
      ..quadraticBezierTo(s * .28, s * .4, s * .3, s * .62)
      ..quadraticBezierTo(s * .5, s * .56, s * .7, s * .62)
      ..quadraticBezierTo(s * .72, s * .4, s * .5, s * .22)
      ..close();
    canvas.drawPath(cloth, _grad(const [Color(0xFFFFEB3B), Color(0xFFFF6F00), Color(0xFFC2185B)], Rect.fromLTWH(s * .28, s * .22, s * .44, s * .4)));
    canvas.drawPath(
      Path()
        ..moveTo(s * .3, s * .62)
        ..quadraticBezierTo(s * .5, s * .56, s * .7, s * .62),
      Paint()
        ..color = const Color(0xFF2E7D32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .03,
    );
    // Neem leaves.
    for (final a in [-2.4, -2.0, -1.1, -.7]) {
      _leafShape(canvas, Offset(s * .5, s * .2), a, s * .16, _leaf);
    }
    // Inverted copper pot.
    final pot = Path()
      ..moveTo(s * .4, s * .22)
      ..quadraticBezierTo(s * .36, s * .08, s * .5, s * .06)
      ..quadraticBezierTo(s * .64, s * .08, s * .6, s * .22)
      ..close();
    canvas.drawPath(pot, _grad(_copper, Rect.fromLTWH(s * .36, s * .06, s * .28, s * .16), vertical: false));
    canvas.drawRect(Rect.fromLTWH(s * .43, s * .22, s * .14, s * .03), Paint()..color = const Color(0xFF8D3B00));
    // Marigold garland and sugar beads.
    for (var k = 0; k < 7; k++) {
      final t = k / 6;
      final p = Offset(s * (.36 + t * .28), s * (.3 + math.sin(t * math.pi) * .08));
      canvas.drawCircle(p, s * .028, Paint()..color = k.isEven ? _marigold : const Color(0xFFFF6F00));
    }
    for (var k = 0; k < 6; k++) {
      canvas.drawCircle(Offset(s * (.55 + k * .012), s * (.3 + k * .05)), s * .014, Paint()..color = Colors.white);
    }
    // Base pot.
    canvas.drawOval(Rect.fromLTWH(s * .36, s * .88, s * .28, s * .08), Paint()..color = const Color(0xFF6D4C41));
  }

  void _kalash(Canvas canvas, double s) {
    final body = Path()
      ..moveTo(s * .38, s * .46)
      ..cubicTo(s * .16, s * .56, s * .2, s * .9, s * .5, s * .9)
      ..cubicTo(s * .8, s * .9, s * .84, s * .56, s * .62, s * .46)
      ..close();
    canvas.drawPath(body, _grad(_copper, Rect.fromLTWH(s * .2, s * .46, s * .64, s * .44), vertical: false));
    canvas.drawRect(Rect.fromLTWH(s * .37, s * .4, s * .26, s * .07), _grad(_gold, Rect.fromLTWH(s * .37, s * .4, s * .26, s * .07)));
    // Swastik.
    final sw = Paint()
      ..color = const Color(0xFFB71C1C)
      ..strokeWidth = s * .018
      ..strokeCap = StrokeCap.round;
    final o = Offset(s * .5, s * .7), d = s * .06;
    canvas.drawLine(o.translate(-d, 0), o.translate(d, 0), sw);
    canvas.drawLine(o.translate(0, -d), o.translate(0, d), sw);
    canvas.drawLine(o.translate(d, 0), o.translate(d, d), sw);
    canvas.drawLine(o.translate(-d, 0), o.translate(-d, -d), sw);
    canvas.drawLine(o.translate(0, -d), o.translate(d, -d), sw);
    canvas.drawLine(o.translate(0, d), o.translate(-d, d), sw);
    // Mango leaves.
    for (var k = 0; k < 7; k++) {
      final a = -math.pi + .35 + k * (math.pi - .7) / 6;
      _leafShape(canvas, Offset(s * .5, s * .4), a, s * .22, k.isEven ? _leaf : _leafLight);
    }
    // Coconut with red cloth.
    canvas.drawOval(Rect.fromLTWH(s * .39, s * .16, s * .22, s * .26), _grad(const [Color(0xFFD7A86E), Color(0xFF6D4C41)], Rect.fromLTWH(s * .39, s * .16, s * .22, s * .26)));
    canvas.drawPath(
      Path()
        ..moveTo(s * .39, s * .33)
        ..quadraticBezierTo(s * .5, s * .26, s * .61, s * .33)
        ..lineTo(s * .61, s * .4)
        ..lineTo(s * .39, s * .4)
        ..close(),
      Paint()..color = const Color(0xFFC62828),
    );
  }

  void _bow(Canvas canvas, double s) {
    final gold = _grad(_gold, Rect.fromLTWH(0, 0, s, s));
    final bow = Path()
      ..moveTo(s * .3, s * .1)
      ..quadraticBezierTo(s * .82, s * .5, s * .3, s * .9);
    canvas.drawPath(bow, Paint()
      ..shader = gold.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .045
      ..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(s * .3, s * .1), Offset(s * .3, s * .9), Paint()
      ..color = Colors.white70
      ..strokeWidth = s * .008);
    // Arrow.
    final arrow = Paint()
      ..shader = gold.shader
      ..strokeWidth = s * .022;
    canvas.drawLine(Offset(s * .14, s * .5), Offset(s * .82, s * .5), arrow);
    canvas.drawPath(
      Path()
        ..moveTo(s * .9, s * .5)
        ..lineTo(s * .8, s * .45)
        ..lineTo(s * .8, s * .55)
        ..close(),
      gold,
    );
    for (final dy in [-1.0, 1.0]) {
      canvas.drawLine(Offset(s * .14, s * .5), Offset(s * .1, s * .5 + dy * s * .05), Paint()
        ..color = const Color(0xFFE53935)
        ..strokeWidth = s * .02);
    }
    // Apta leaves.
    for (final a in [2.2, 2.6]) {
      _leafShape(canvas, Offset(s * .62, s * .78), a, s * .16, _leaf);
    }
  }

  void _moon(Canvas canvas, double s) {
    final c = Offset(s * .52, s * .44);
    _glow(canvas, c, s * .46, const Color(0x88FFF9C4));
    canvas.drawCircle(c, s * .3, Paint()
      ..shader = const RadialGradient(center: Alignment(-.3, -.3), colors: [Color(0xFFFFFDE7), Color(0xFFFFF59D), Color(0xFFE6C84F)])
          .createShader(Rect.fromCircle(center: c, radius: s * .3)));
    for (final (dx, dy, r) in [(-.1, -.05, .05), (.08, .07, .07), (.1, -.12, .03), (-.06, .14, .035)]) {
      canvas.drawCircle(c.translate(s * dx, s * dy), s * r, Paint()..color = const Color(0x33B8860B));
    }
    // Clouds.
    final cloud = Paint()..color = Colors.white.withValues(alpha: .85);
    for (final (x, y, r) in [(.2, .78, .08), (.3, .74, .1), (.42, .78, .08), (.66, .82, .07), (.76, .78, .09), (.86, .82, .06)]) {
      canvas.drawCircle(Offset(s * x, s * y), s * r, cloud);
    }
    final star = Paint()..color = const Color(0xFFFFF59D);
    for (final (x, y) in [(.12, .16), (.86, .14), (.9, .5), (.1, .52)]) {
      canvas.drawCircle(Offset(s * x, s * y), s * .015, star);
    }
  }

  void _shivling(Canvas canvas, double s) {
    // Yoni base.
    final base = Path()
      ..moveTo(s * .12, s * .78)
      ..lineTo(s * .74, s * .78)
      ..quadraticBezierTo(s * .92, s * .74, s * .94, s * .68)
      ..lineTo(s * .74, s * .66)
      ..lineTo(s * .12, s * .66)
      ..close();
    canvas.drawPath(base, _grad(const [Color(0xFF616161), Color(0xFF212121)], Rect.fromLTWH(s * .12, s * .66, s * .82, s * .12)));
    canvas.drawRect(Rect.fromLTWH(s * .16, s * .78, s * .5, s * .1), _grad(const [Color(0xFF424242), Color(0xFF111111)], Rect.fromLTWH(0, s * .78, s, s * .1)));
    // Lingam.
    final lingam = Path()
      ..moveTo(s * .3, s * .68)
      ..lineTo(s * .3, s * .38)
      ..quadraticBezierTo(s * .3, s * .16, s * .43, s * .16)
      ..quadraticBezierTo(s * .56, s * .16, s * .56, s * .38)
      ..lineTo(s * .56, s * .68)
      ..close();
    canvas.drawPath(lingam, _grad(const [Color(0xFF9E9E9E), Color(0xFF424242), Color(0xFF212121)], Rect.fromLTWH(s * .3, 0, s * .26, s), vertical: false));
    // Tripundra and tilak.
    for (var k = 0; k < 3; k++) {
      canvas.drawLine(Offset(s * .32, s * (.36 + k * .045)), Offset(s * .54, s * (.36 + k * .045)), Paint()
        ..color = Colors.white
        ..strokeWidth = s * .016
        ..strokeCap = StrokeCap.round);
    }
    canvas.drawCircle(Offset(s * .43, s * .48), s * .02, Paint()..color = const Color(0xFFD50000));
    // Bilva leaves.
    for (final a in [-2.2, -1.57, -.9]) {
      _leafShape(canvas, Offset(s * .43, s * .2), a, s * .12, _leaf);
    }
    _flower(canvas, Offset(s * .7, s * .62), s * .05, Colors.white, const Color(0xFFFFC107));
  }

  void _trishul(Canvas canvas, double s) {
    final gold = _grad(_gold, Rect.fromLTWH(s * .2, 0, s * .6, s), vertical: false);
    canvas.drawRect(Rect.fromLTWH(s * .485, s * .24, s * .03, s * .7), gold);
    final prongs = Path()
      ..moveTo(s * .5, s * .04)
      ..lineTo(s * .54, s * .18)
      ..lineTo(s * .52, s * .32)
      ..lineTo(s * .48, s * .32)
      ..lineTo(s * .46, s * .18)
      ..close()
      ..moveTo(s * .26, s * .1)
      ..quadraticBezierTo(s * .26, s * .3, s * .48, s * .32)
      ..lineTo(s * .48, s * .28)
      ..quadraticBezierTo(s * .32, s * .26, s * .3, s * .16)
      ..close()
      ..moveTo(s * .74, s * .1)
      ..quadraticBezierTo(s * .74, s * .3, s * .52, s * .32)
      ..lineTo(s * .52, s * .28)
      ..quadraticBezierTo(s * .68, s * .26, s * .7, s * .16)
      ..close();
    canvas.drawPath(prongs, gold);
    // Damaru.
    final dc = Offset(s * .5, s * .5);
    final dam = Path()
      ..moveTo(dc.dx - s * .14, dc.dy - s * .09)
      ..lineTo(dc.dx + s * .14, dc.dy - s * .09)
      ..lineTo(dc.dx + s * .02, dc.dy)
      ..lineTo(dc.dx + s * .14, dc.dy + s * .09)
      ..lineTo(dc.dx - s * .14, dc.dy + s * .09)
      ..lineTo(dc.dx - s * .02, dc.dy)
      ..close();
    canvas.drawPath(dam, _grad(const [Color(0xFFFFCC80), Color(0xFF8D6E63)], Rect.fromCenter(center: dc, width: s * .3, height: s * .2)));
    canvas.drawLine(dc.translate(-s * .02, 0), dc.translate(s * .02, 0), Paint()
      ..color = const Color(0xFFD50000)
      ..strokeWidth = s * .02);
    // Ribbon.
    canvas.drawPath(
      Path()
        ..moveTo(s * .5, s * .58)
        ..quadraticBezierTo(s * .64, s * .66, s * .58, s * .78)
        ..moveTo(s * .5, s * .58)
        ..quadraticBezierTo(s * .38, s * .68, s * .44, s * .8),
      Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .02,
    );
  }

  void _modak(Canvas canvas, double s) {
    // Plate.
    canvas.drawOval(Rect.fromLTWH(s * .1, s * .7, s * .8, s * .18), _grad(_gold, Rect.fromLTWH(s * .1, s * .7, s * .8, s * .18)));
    canvas.drawOval(Rect.fromLTWH(s * .16, s * .72, s * .68, s * .12), Paint()..color = const Color(0xFFFFE082));
    void modak(Offset b, double w) {
      final h = w * 1.15;
      final p = Path()
        ..moveTo(b.dx - w / 2, b.dy)
        ..quadraticBezierTo(b.dx - w * .55, b.dy - h * .55, b.dx, b.dy - h)
        ..quadraticBezierTo(b.dx + w * .55, b.dy - h * .55, b.dx + w / 2, b.dy)
        ..close();
      canvas.drawPath(p, _grad(const [Color(0xFFFFFDE7), Color(0xFFFFE0B2), Color(0xFFE6B07A)], Rect.fromLTWH(b.dx - w / 2, b.dy - h, w, h), vertical: false));
      final pleat = Paint()
        ..color = const Color(0xFFD7A86E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .03;
      for (final k in [-.3, 0.0, .3]) {
        canvas.drawPath(
          Path()
            ..moveTo(b.dx + k * w, b.dy)
            ..quadraticBezierTo(b.dx + k * w * .6, b.dy - h * .5, b.dx, b.dy - h * .95),
          pleat,
        );
      }
    }

    for (final (x, y, w) in [(.32, .8, .2), (.68, .8, .2), (.5, .82, .24), (.41, .66, .2), (.59, .66, .2)]) {
      modak(Offset(s * x, s * y), s * w);
    }
    // Durva grass.
    for (final a in [-2.0, -1.7, -1.4, -1.1]) {
      _leafShape(canvas, Offset(s * .5, s * .48), a, s * .2, _leafLight);
    }
    _flower(canvas, Offset(s * .5, s * .32), s * .06, const Color(0xFFE53935), const Color(0xFFFFC107));
  }

  void _flute(Canvas canvas, double s) {
    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.rotate(-.6);
    final r = Rect.fromCenter(center: Offset.zero, width: s * .9, height: s * .07);
    canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(s * .035)), _grad(const [Color(0xFFFFE082), Color(0xFFB8860B)], r));
    for (var k = 0; k < 6; k++) {
      canvas.drawCircle(Offset(-s * .1 + k * s * .06, 0), s * .012, Paint()..color = const Color(0xFF5D4037));
    }
    for (final x in [-.3, .38]) {
      canvas.drawRect(Rect.fromCenter(center: Offset(s * x, 0), width: s * .03, height: s * .075), Paint()..color = const Color(0xFFC62828));
    }
    canvas.restore();
    // Peacock feather.
    canvas.save();
    canvas.translate(s * .66, s * .3);
    canvas.rotate(.5);
    canvas.drawLine(const Offset(0, 0), Offset(0, s * .42), Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = s * .01);
    final barbs = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: .8)
      ..strokeWidth = s * .006;
    for (var k = 0; k < 14; k++) {
      final y = k * s * .025;
      canvas.drawLine(Offset(0, y), Offset(-s * .09, y + s * .03), barbs);
      canvas.drawLine(Offset(0, y), Offset(s * .09, y + s * .03), barbs);
    }
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * .2, height: s * .26), Paint()..color = const Color(0xFF1B5E20));
    canvas.drawOval(Rect.fromCenter(center: Offset(0, s * .01), width: s * .14, height: s * .18), Paint()..color = const Color(0xFFFFB300));
    canvas.drawOval(Rect.fromCenter(center: Offset(0, s * .02), width: s * .09, height: s * .11), Paint()..color = const Color(0xFF00838F));
    canvas.drawOval(Rect.fromCenter(center: Offset(0, s * .03), width: s * .045, height: s * .055), Paint()..color = const Color(0xFF0D1B5E));
    canvas.restore();
  }

  void _matki(Canvas canvas, double s) {
    // Ropes.
    final rope = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = s * .012;
    for (final x in [.32, .5, .68]) {
      canvas.drawLine(Offset(s * .5, s * .02), Offset(s * x, s * .34), rope);
    }
    final pot = Path()
      ..moveTo(s * .36, s * .34)
      ..cubicTo(s * .1, s * .44, s * .14, s * .86, s * .5, s * .86)
      ..cubicTo(s * .86, s * .86, s * .9, s * .44, s * .64, s * .34)
      ..close();
    canvas.drawPath(pot, _grad(const [Color(0xFFE57373), Color(0xFFB23C17), Color(0xFF6D2A0C)], Rect.fromLTWH(s * .14, s * .34, s * .72, s * .52), vertical: false));
    // Painted band and butter.
    for (var k = 0; k < 9; k++) {
      canvas.drawCircle(Offset(s * (.26 + k * .06), s * .58), s * .016, Paint()..color = const Color(0xFFFFEB3B));
    }
    canvas.drawPath(
      Path()
        ..moveTo(s * .34, s * .34)
        ..quadraticBezierTo(s * .4, s * .24, s * .5, s * .26)
        ..quadraticBezierTo(s * .62, s * .22, s * .66, s * .34)
        ..lineTo(s * .62, s * .42)
        ..quadraticBezierTo(s * .58, s * .36, s * .54, s * .44)
        ..quadraticBezierTo(s * .48, s * .36, s * .42, s * .42)
        ..close(),
      Paint()..color = const Color(0xFFFFFDE7),
    );
    // Marigold garland.
    for (var k = 0; k < 8; k++) {
      final t = k / 7;
      canvas.drawCircle(Offset(s * (.22 + t * .56), s * (.68 + math.sin(t * math.pi) * .08)), s * .026, Paint()..color = k.isEven ? _marigold : const Color(0xFFFF6F00));
    }
  }

  void _rakhi(Canvas canvas, double s) {
    final thread = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .03;
    canvas.drawPath(
      Path()
        ..moveTo(s * .02, s * .62)
        ..quadraticBezierTo(s * .5, s * .38, s * .98, s * .62),
      thread,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s * .02, s * .66)
        ..quadraticBezierTo(s * .5, s * .42, s * .98, s * .66),
      thread..color = const Color(0xFFFFC107),
    );
    final c = Offset(s * .5, s * .5);
    for (var k = 0; k < 12; k++) {
      final a = k * math.pi / 6;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * s * .2, s * .09,
          Paint()..color = k.isEven ? const Color(0xFFE91E63) : const Color(0xFFFF9800));
    }
    _flower(canvas, c, s * .16, const Color(0xFFFFD54F), const Color(0xFFFFF59D));
    canvas.drawCircle(c, s * .07, _grad(const [Color(0xFF80DEEA), Color(0xFF00838F)], Rect.fromCircle(center: c, radius: s * .07)));
    canvas.drawCircle(c.translate(-s * .02, -s * .02), s * .02, Paint()..color = Colors.white70);
    for (final dx in [-.08, .08]) {
      canvas.drawLine(Offset(s * (.5 + dx), s * .72), Offset(s * (.5 + dx * 1.6), s * .9), Paint()
        ..color = const Color(0xFFE53935)
        ..strokeWidth = s * .015);
    }
  }

  void _kite(Canvas canvas, double s) {
    void kite(Offset c, double w, List<Color> colors) {
      final p = Path()
        ..moveTo(c.dx, c.dy - w)
        ..lineTo(c.dx + w * .8, c.dy)
        ..lineTo(c.dx, c.dy + w)
        ..lineTo(c.dx - w * .8, c.dy)
        ..close();
      canvas.drawPath(p, Paint()..color = colors[0]);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - w)
          ..lineTo(c.dx + w * .8, c.dy)
          ..lineTo(c.dx, c.dy)
          ..close(),
        Paint()..color = colors[1],
      );
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy + w)
          ..lineTo(c.dx - w * .8, c.dy)
          ..lineTo(c.dx, c.dy)
          ..close(),
        Paint()..color = colors[1],
      );
      final stick = Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = w * .03;
      canvas.drawLine(c.translate(0, -w), c.translate(0, w), stick);
      canvas.drawLine(c.translate(-w * .8, 0), c.translate(w * .8, 0), stick);
      // Tail.
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy + w)
          ..lineTo(c.dx - w * .25, c.dy + w * 1.35)
          ..lineTo(c.dx + w * .25, c.dy + w * 1.35)
          ..close(),
        Paint()..color = colors[1],
      );
    }

    canvas.drawPath(
      Path()
        ..moveTo(s * .42, s * .5)
        ..quadraticBezierTo(s * .2, s * .8, s * .02, s * .98),
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .006,
    );
    kite(Offset(s * .44, s * .34), s * .24, const [Color(0xFFE91E63), Color(0xFFFFC107)]);
    kite(Offset(s * .78, s * .62), s * .13, const [Color(0xFF1E88E5), Color(0xFF76FF03)]);
    // Til-gul.
    for (var k = 0; k < 6; k++) {
      canvas.drawCircle(Offset(s * (.6 + (k % 3) * .06), s * (.86 + (k ~/ 3) * .05)), s * .026, Paint()..color = const Color(0xFFF5E6C8));
    }
  }

  void _holi(Canvas canvas, double s) {
    final rnd = math.Random(4);
    const colors = [Color(0xFFE91E63), Color(0xFFFFEB3B), Color(0xFF00E676), Color(0xFF2979FF), Color(0xFFFF6D00), Color(0xFFAA00FF)];
    for (var k = 0; k < 6; k++) {
      final c = Offset(s * (.25 + rnd.nextDouble() * .5), s * (.25 + rnd.nextDouble() * .5));
      final color = colors[k];
      _glow(canvas, c, s * .26, color.withValues(alpha: .7));
      for (var j = 0; j < 9; j++) {
        final a = rnd.nextDouble() * 2 * math.pi, d = s * (.08 + rnd.nextDouble() * .16);
        canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * d, s * (.012 + rnd.nextDouble() * .03), Paint()..color = color);
      }
    }
    // Bowls of colour.
    for (final (x, color) in [(.24, colors[0]), (.5, colors[1]), (.76, colors[2])]) {
      canvas.drawArc(Rect.fromCenter(center: Offset(s * x, s * .82), width: s * .22, height: s * .16), 0, math.pi, true, Paint()..color = const Color(0xFF8D6E63));
      canvas.drawOval(Rect.fromCenter(center: Offset(s * x, s * .81), width: s * .2, height: s * .07), Paint()..color = color);
    }
  }

  void _tulsi(Canvas canvas, double s) {
    // Vrindavan planter.
    final r = Rect.fromLTWH(s * .26, s * .58, s * .48, s * .34);
    canvas.drawRect(r, _grad(const [Color(0xFFFFCC80), Color(0xFFE65100)], r, vertical: false));
    canvas.drawRect(Rect.fromLTWH(s * .22, s * .54, s * .56, s * .06), Paint()..color = const Color(0xFFB23C17));
    canvas.drawRect(Rect.fromLTWH(s * .22, s * .9, s * .56, s * .05), Paint()..color = const Color(0xFFB23C17));
    // Om on the planter.
    final tp = TextPainter(
      text: TextSpan(text: 'ॐ', style: TextStyle(fontSize: s * .15, color: const Color(0xFFB71C1C), fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(s * .5 - tp.width / 2, s * .66));
    // Plant.
    canvas.drawLine(Offset(s * .5, s * .56), Offset(s * .5, s * .14), Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = s * .015);
    for (var k = 0; k < 6; k++) {
      final y = s * (.18 + k * .065);
      final len = s * (.1 + k * .022);
      _leafShape(canvas, Offset(s * .5, y), -2.6 + k * .05, len, k.isEven ? _leaf : _leafLight);
      _leafShape(canvas, Offset(s * .5, y + s * .02), -.55 - k * .05, len, k.isOdd ? _leaf : _leafLight);
    }
    for (var k = 0; k < 4; k++) {
      canvas.drawCircle(Offset(s * .5, s * (.1 + k * .02)), s * .015, Paint()..color = const Color(0xFF6A1B9A));
    }
  }

  void _snake(Canvas canvas, double s) {
    final body = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF33691E), Color(0xFF9CCC65)]).createShader(Rect.fromLTWH(0, 0, s, s))
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .07
      ..strokeCap = StrokeCap.round;
    for (final (rx, ry, y) in [(.34, .09, .84), (.28, .08, .72), (.22, .07, .61)]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(s * .5, s * y), width: s * rx * 2, height: s * ry * 2), body);
    }
    canvas.drawPath(
      Path()
        ..moveTo(s * .6, s * .6)
        ..quadraticBezierTo(s * .62, s * .44, s * .52, s * .36),
      body,
    );
    // Hood.
    final hood = Path()
      ..moveTo(s * .52, s * .06)
      ..cubicTo(s * .4, s * .06, s * .2, s * .2, s * .3, s * .34)
      ..cubicTo(s * .38, s * .42, s * .46, s * .4, s * .52, s * .44)
      ..cubicTo(s * .58, s * .4, s * .66, s * .42, s * .74, s * .34)
      ..cubicTo(s * .84, s * .2, s * .64, s * .06, s * .52, s * .06)
      ..close();
    canvas.drawPath(hood, _grad(const [Color(0xFF9CCC65), Color(0xFF33691E)], Rect.fromLTWH(s * .22, s * .06, s * .6, s * .38)));
    // Spectacle mark on the hood.
    for (final dx in [-.07, .07]) {
      canvas.drawCircle(Offset(s * (.52 + dx), s * .27), s * .035, Paint()
        ..color = const Color(0xFF1B5E20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .012);
    }
    for (final dx in [-.035, .035]) {
      canvas.drawCircle(Offset(s * (.52 + dx), s * .12), s * .012, Paint()..color = Colors.black);
    }
    canvas.drawPath(
      Path()
        ..moveTo(s * .52, s * .15)
        ..lineTo(s * .52, s * .2),
      Paint()
        ..color = const Color(0xFFFFF59D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .012,
    );
    _flower(canvas, Offset(s * .18, s * .4), s * .05, Colors.white, const Color(0xFFFFC107));
    _flower(canvas, Offset(s * .84, s * .42), s * .05, const Color(0xFFE91E63), const Color(0xFFFFC107));
  }

  void _banyan(Canvas canvas, double s) {
    canvas.drawRect(Rect.fromLTWH(s * .44, s * .5, s * .12, s * .42), _grad(const [Color(0xFF8D6E63), Color(0xFF4E342E)], Rect.fromLTWH(s * .44, 0, s * .12, s), vertical: false));
    // Aerial roots.
    final root = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = s * .008;
    for (final x in [.2, .28, .7, .8]) {
      canvas.drawLine(Offset(s * x, s * .46), Offset(s * x, s * .86), root);
    }
    // Canopy.
    for (final (x, y, r) in [(.5, .3, .26), (.26, .38, .18), (.74, .38, .18), (.36, .2, .16), (.64, .2, .16)]) {
      final c = Offset(s * x, s * y);
      canvas.drawCircle(c, s * r, Paint()
        ..shader = const RadialGradient(center: Alignment(-.3, -.3), colors: [Color(0xFF81C784), Color(0xFF1B5E20)])
            .createShader(Rect.fromCircle(center: c, radius: s * r)));
    }
    // Sacred threads round the trunk.
    for (var k = 0; k < 3; k++) {
      canvas.drawLine(Offset(s * .43, s * (.62 + k * .04)), Offset(s * .57, s * (.64 + k * .04)), Paint()
        ..color = k.isEven ? Colors.white : const Color(0xFFE53935)
        ..strokeWidth = s * .012);
    }
    canvas.drawRect(Rect.fromLTWH(s * .2, s * .92, s * .6, s * .03), Paint()..color = const Color(0xFF6D4C41));
  }

  void _flag(Canvas canvas, double s, {required bool tricolor}) {
    canvas.drawRect(Rect.fromLTWH(s * .2, s * .06, s * .025, s * .9), _grad(const [Color(0xFFE0E0E0), Color(0xFF757575)], Rect.fromLTWH(s * .2, 0, s * .025, s), vertical: false));
    canvas.drawCircle(Offset(s * .2125, s * .06), s * .025, _grad(_gold, Rect.fromLTWH(s * .19, s * .04, s * .05, s * .05)));
    Path wave(double top, double h) => Path()
      ..moveTo(s * .225, s * top)
      ..cubicTo(s * .45, s * (top - .05), s * .6, s * (top + .05), s * .88, s * top)
      ..lineTo(s * .88, s * (top + h))
      ..cubicTo(s * .6, s * (top + h + .05), s * .45, s * (top + h - .05), s * .225, s * (top + h))
      ..close();
    if (tricolor) {
      canvas.drawPath(wave(.1, .12), Paint()..color = const Color(0xFFFF9933));
      canvas.drawPath(wave(.22, .12), Paint()..color = Colors.white);
      canvas.drawPath(wave(.34, .12), Paint()..color = const Color(0xFF138808));
      final c = Offset(s * .55, s * .28);
      final chakra = Paint()
        ..color = const Color(0xFF000080)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .006;
      canvas.drawCircle(c, s * .05, chakra);
      for (var k = 0; k < 24; k++) {
        final a = k * math.pi / 12;
        canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * s * .05, chakra..strokeWidth = s * .003);
      }
    } else {
      // Saffron swallow-tailed flag.
      final p = Path()
        ..moveTo(s * .225, s * .1)
        ..cubicTo(s * .45, s * .04, s * .6, s * .16, s * .9, s * .12)
        ..lineTo(s * .7, s * .28)
        ..lineTo(s * .9, s * .44)
        ..cubicTo(s * .6, s * .48, s * .45, s * .38, s * .225, s * .44)
        ..close();
      canvas.drawPath(p, _grad(const [Color(0xFFFFB74D), Color(0xFFFF6F00), Color(0xFFE65100)], Rect.fromLTWH(s * .2, s * .04, s * .7, s * .44)));
    }
    _flower(canvas, Offset(s * .2125, s * .5), s * .05, _marigold, const Color(0xFFE65100));
  }

  void _book(Canvas canvas, double s) {
    final pageL = Path()
      ..moveTo(s * .5, s * .5)
      ..quadraticBezierTo(s * .32, s * .44, s * .1, s * .5)
      ..lineTo(s * .1, s * .84)
      ..quadraticBezierTo(s * .32, s * .78, s * .5, s * .86)
      ..close();
    final pageR = Path()
      ..moveTo(s * .5, s * .5)
      ..quadraticBezierTo(s * .68, s * .44, s * .9, s * .5)
      ..lineTo(s * .9, s * .84)
      ..quadraticBezierTo(s * .68, s * .78, s * .5, s * .86)
      ..close();
    canvas.drawPath(Path()..addRect(Rect.fromLTWH(s * .08, s * .52, s * .84, s * .38)), Paint()..color = const Color(0xFF8D1B1B));
    canvas.drawPath(pageL, Paint()..color = const Color(0xFFFFFDF5));
    canvas.drawPath(pageR, Paint()..color = const Color(0xFFFFF8E1));
    final line = Paint()
      ..color = const Color(0xFFBCAAA4)
      ..strokeWidth = s * .006;
    for (var k = 0; k < 5; k++) {
      canvas.drawLine(Offset(s * .15, s * (.58 + k * .05)), Offset(s * .44, s * (.58 + k * .05)), line);
      canvas.drawLine(Offset(s * .56, s * (.58 + k * .05)), Offset(s * .85, s * (.58 + k * .05)), line);
    }
    // Lamp of knowledge above the book.
    canvas.drawPath(
      Path()
        ..moveTo(s * .4, s * .4)
        ..quadraticBezierTo(s * .5, s * .5, s * .6, s * .4)
        ..close(),
      _grad(_gold, Rect.fromLTWH(s * .4, s * .38, s * .2, s * .1)),
    );
    _flame(canvas, Offset(s * .5, s * .39), s * .22);
  }

  void _sun(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    canvas.save();
    canvas.translate(0, 0);
    SunRaysPainter(color: const Color(0xFFFFB300), rays: 24).paint(canvas, Size(s, s));
    canvas.restore();
    canvas.drawCircle(c, s * .24, Paint()
      ..shader = const RadialGradient(colors: [Color(0xFFFFFDE7), Color(0xFFFFC107), Color(0xFFFF6F00)])
          .createShader(Rect.fromCircle(center: c, radius: s * .24)));
    // Chariot wheel in the sun.
    final spoke = Paint()
      ..color = const Color(0xFFB8860B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .01;
    canvas.drawCircle(c, s * .14, spoke);
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4;
      canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * s * .14, spoke);
    }
    canvas.drawCircle(c, s * .03, Paint()..color = const Color(0xFFB8860B));
  }

  void _paduka(Canvas canvas, double s) {
    void paduka(double cx, double tilt) {
      canvas.save();
      canvas.translate(cx, s * .52);
      canvas.rotate(tilt);
      final sole = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * .2, height: s * .56), Radius.circular(s * .1));
      canvas.drawRRect(sole, _grad(const [Color(0xFFD7A86E), Color(0xFF8D5524)], sole.outerRect, vertical: false));
      canvas.drawRRect(sole.deflate(s * .015), Paint()
        ..color = const Color(0xFFFFE082)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .008);
      // Toe knob.
      canvas.drawCircle(Offset(0, -s * .14), s * .035, _grad(_gold, Rect.fromCircle(center: Offset(0, -s * .14), radius: s * .035)));
      canvas.restore();
    }

    paduka(s * .37, -.12);
    paduka(s * .63, .12);
    for (final (x, y) in [(.2, .86), (.5, .9), (.8, .86)]) {
      _flower(canvas, Offset(s * x, s * y), s * .045, _marigold, const Color(0xFFE65100));
    }
    for (var k = 0; k < 9; k++) {
      final a = math.pi + k * math.pi / 8;
      canvas.drawCircle(Offset(s * .5, s * .5) + Offset(math.cos(a), math.sin(a)) * s * .42, s * .018, Paint()..color = const Color(0xFF6D4C41));
    }
  }

  void _gada(Canvas canvas, double s) {
    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.rotate(-.5);
    final handle = Rect.fromCenter(center: Offset(0, s * .18), width: s * .05, height: s * .5);
    canvas.drawRRect(RRect.fromRectAndRadius(handle, Radius.circular(s * .02)), _grad(_gold, handle, vertical: false));
    final head = Offset(0, -s * .16);
    canvas.drawCircle(head, s * .2, Paint()
      ..shader = const RadialGradient(center: Alignment(-.3, -.3), colors: [Color(0xFFFFF3B0), Color(0xFFFFC107), Color(0xFF8D6E00)])
          .createShader(Rect.fromCircle(center: head, radius: s * .2)));
    final band = Paint()
      ..color = const Color(0xFFB71C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .02;
    canvas.drawOval(Rect.fromCenter(center: head, width: s * .4, height: s * .12), band);
    canvas.drawCircle(head.translate(0, -s * .22), s * .04, _grad(_gold, Rect.fromCircle(center: head, radius: s * .2)));
    canvas.drawCircle(Offset(0, s * .45), s * .035, _grad(_gold, Rect.fromCircle(center: Offset(0, s * .45), radius: s * .035)));
    canvas.restore();
    _flower(canvas, Offset(s * .2, s * .8), s * .06, const Color(0xFFFF6F00), const Color(0xFFFFEB3B));
  }

  @override
  bool shouldRepaint(FestivalArtPainter old) => old.art != art;
}

/// Whole-banner festive scene behind the text for festivals that are about
/// a celebration rather than a deity: kites across the sky for Sankranti,
/// colour bursts for Holi, fireworks for Diwali, tricolour ribbons for
/// national days and stars for full-moon nights.
bool hasFestivalScene(String? art) => const {'kite', 'holi', 'diya', 'tricolor', 'moon'}.contains(art);

class FestivalScenePainter extends CustomPainter {
  const FestivalScenePainter(this.art, {required this.unit});
  final String art;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    switch (art) {
      case 'kite':
        _kites(canvas, size);
      case 'holi':
        _colours(canvas, size);
      case 'diya':
        _fireworks(canvas, size);
      case 'tricolor':
        _ribbons(canvas, size);
      case 'moon':
        _stars(canvas, size);
    }
  }

  void _kite(Canvas canvas, Offset c, double w, double tilt, List<Color> colors) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(tilt);
    final body = Path()
      ..moveTo(0, -w)
      ..lineTo(w * .8, 0)
      ..lineTo(0, w)
      ..lineTo(-w * .8, 0)
      ..close();
    canvas.drawPath(body, Paint()..color = colors[0]);
    canvas.drawPath(
      Path()
        ..moveTo(0, -w)
        ..lineTo(w * .8, 0)
        ..lineTo(0, 0)
        ..close()
        ..moveTo(0, w)
        ..lineTo(-w * .8, 0)
        ..lineTo(0, 0)
        ..close(),
      Paint()..color = colors[1],
    );
    final stick = Paint()
      ..color = Colors.black.withValues(alpha: .35)
      ..strokeWidth = w * .04;
    canvas.drawLine(Offset(0, -w), Offset(0, w), stick);
    canvas.drawLine(Offset(-w * .8, 0), Offset(w * .8, 0), stick);
    canvas.drawPath(
      Path()
        ..moveTo(0, w)
        ..lineTo(-w * .22, w * 1.3)
        ..lineTo(w * .22, w * 1.3)
        ..close(),
      Paint()..color = colors[1],
    );
    // Long string trailing down.
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(w * .8, w * 3, -w * .5, w * 6),
      Paint()
        ..color = Colors.white.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .025,
    );
    canvas.restore();
  }

  void _kites(Canvas canvas, Size size) {
    final u = unit;
    // Soft sun in the corner.
    final sun = Offset(size.width * .86, size.height * .12);
    canvas.drawCircle(
      sun,
      70 * u,
      Paint()
        ..shader = RadialGradient(colors: [const Color(0xCCFFF59D), const Color(0x00FFF59D)])
            .createShader(Rect.fromCircle(center: sun, radius: 70 * u)),
    );
    const palettes = [
      [Color(0xFFE91E63), Color(0xFFFFC107)],
      [Color(0xFF1E88E5), Color(0xFF76FF03)],
      [Color(0xFF8E24AA), Color(0xFFFF7043)],
      [Color(0xFF00897B), Color(0xFFFFEB3B)],
      [Color(0xFFD50000), Color(0xFF2962FF)],
      [Color(0xFFFF6D00), Color(0xFF00C853)],
    ];
    final spots = [
      (.1, .22, 22.0, -.3),
      (.9, .3, 18.0, .25),
      (.18, .5, 14.0, .2),
      (.82, .56, 24.0, -.2),
      (.08, .78, 16.0, .3),
      (.93, .8, 13.0, -.35),
      (.3, .1, 12.0, .15),
      (.7, .08, 15.0, -.1),
    ];
    for (final (i, (x, y, w, t)) in spots.indexed) {
      _kite(canvas, Offset(size.width * x, size.height * y), w * u, t, palettes[i % palettes.length]);
    }
  }

  void _colours(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    const colors = [Color(0xFFE91E63), Color(0xFFFFEB3B), Color(0xFF00E676), Color(0xFF2979FF), Color(0xFFFF6D00), Color(0xFFAA00FF)];
    for (final (i, (x, y)) in [(.05, .1), (.95, .12), (.04, .88), (.96, .9), (.5, .02), (.5, .98)].indexed) {
      final c = Offset(size.width * x, size.height * y);
      final color = colors[i];
      canvas.drawCircle(
        c,
        80 * unit,
        Paint()..shader = RadialGradient(colors: [color.withValues(alpha: .65), color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: 80 * unit)),
      );
      for (var j = 0; j < 14; j++) {
        final a = rnd.nextDouble() * 2 * math.pi, d = (20 + rnd.nextDouble() * 60) * unit;
        canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * d, (2 + rnd.nextDouble() * 5) * unit, Paint()..color = color.withValues(alpha: .8));
      }
    }
  }

  void _burst(Canvas canvas, Offset c, double r, Color color) {
    for (var k = 0; k < 18; k++) {
      final a = k * math.pi / 9;
      final p1 = c + Offset(math.cos(a), math.sin(a)) * r * .25;
      final p2 = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawLine(p1, p2, Paint()
        ..shader = LinearGradient(colors: [color.withValues(alpha: .1), color]).createShader(Rect.fromPoints(p1, p2))
        ..strokeWidth = 1.6 * unit
        ..strokeCap = StrokeCap.round);
      canvas.drawCircle(p2, 1.8 * unit, Paint()..color = Colors.white.withValues(alpha: .9));
    }
  }

  void _fireworks(Canvas canvas, Size size) {
    _burst(canvas, Offset(size.width * .12, size.height * .16), 34 * unit, const Color(0xFFFFD54F));
    _burst(canvas, Offset(size.width * .88, size.height * .14), 40 * unit, const Color(0xFFFF80AB));
    _burst(canvas, Offset(size.width * .9, size.height * .5), 24 * unit, const Color(0xFF80D8FF));
    _burst(canvas, Offset(size.width * .08, size.height * .52), 22 * unit, const Color(0xFFB9F6CA));
  }

  void _ribbons(Canvas canvas, Size size) {
    for (final (i, color) in const [Color(0xFFFF9933), Colors.white, Color(0xFF138808)].indexed) {
      final top = Path()
        ..moveTo(0, (10 + i * 9) * unit)
        ..cubicTo(size.width * .3, (0 + i * 9) * unit, size.width * .7, (26 + i * 9) * unit, size.width, (8 + i * 9) * unit);
      final bottom = Path()
        ..moveTo(0, size.height - (28 - i * 9) * unit)
        ..cubicTo(size.width * .3, size.height - (40 - i * 9) * unit, size.width * .7, size.height - (14 - i * 9) * unit, size.width, size.height - (30 - i * 9) * unit);
      final paint = Paint()
        ..color = color.withValues(alpha: .85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * unit;
      canvas.drawPath(top, paint);
      canvas.drawPath(bottom, paint);
    }
  }

  void _stars(Canvas canvas, Size size) {
    final rnd = math.Random(3);
    for (var k = 0; k < 40; k++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * .6);
      canvas.drawCircle(p, (.8 + rnd.nextDouble() * 1.8) * unit, Paint()..color = Colors.white.withValues(alpha: .4 + rnd.nextDouble() * .5));
    }
  }

  @override
  bool shouldRepaint(FestivalScenePainter old) => old.art != art || old.unit != unit;
}
