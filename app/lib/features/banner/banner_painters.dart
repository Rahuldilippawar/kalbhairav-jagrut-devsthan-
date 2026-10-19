import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hand-drawn decorations for the Banner Studio. Everything scales with the
/// canvas so previews and 1080px exports look identical.

/// Radiating sun rays, echoing the temple logo.
class SunRaysPainter extends CustomPainter {
  const SunRaysPainter({required this.color, this.rays = 28});
  final Color color;
  final int rays;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final paint = Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: c, radius: r));
    final step = 2 * math.pi / rays;
    for (var i = 0; i < rays; i++) {
      final a = i * step;
      final long = i.isEven ? r : r * .78;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + long * math.cos(a - step * .18), c.dy + long * math.sin(a - step * .18))
        ..lineTo(c.dx + long * math.cos(a + step * .18), c.dy + long * math.sin(a + step * .18))
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(SunRaysPainter old) => old.color != color || old.rays != rays;
}

/// Double golden frame with ornamental corners and edge midpoints.
class OrnateBorderPainter extends CustomPainter {
  const OrnateBorderPainter({required this.color, required this.unit});
  final Color color;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final u = unit;
    final outer = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * u;
    final inner = Paint()
      ..color = color.withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 * u;
    final fill = Paint()..color = color;

    final r1 = Rect.fromLTWH(8 * u, 8 * u, size.width - 16 * u, size.height - 16 * u);
    final r2 = r1.deflate(6 * u);
    canvas.drawRRect(RRect.fromRectAndRadius(r1, Radius.circular(10 * u)), outer);
    canvas.drawRRect(RRect.fromRectAndRadius(r2, Radius.circular(6 * u)), inner);

    // Corner flourishes: nested quarter arcs, a lotus bud and dots.
    for (final (corner, sx, sy) in [
      (r1.topLeft, 1.0, 1.0),
      (r1.topRight, -1.0, 1.0),
      (r1.bottomLeft, 1.0, -1.0),
      (r1.bottomRight, -1.0, -1.0),
    ]) {
      canvas.save();
      canvas.translate(corner.dx, corner.dy);
      canvas.scale(sx, sy);
      for (final rad in [14.0, 22.0]) {
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: rad * u), 0, math.pi / 2, false, inner);
      }
      final bud = Path()
        ..moveTo(10 * u, 10 * u)
        ..quadraticBezierTo(22 * u, 12 * u, 30 * u, 30 * u)
        ..quadraticBezierTo(12 * u, 22 * u, 10 * u, 10 * u);
      canvas.drawPath(bud, fill);
      canvas.drawCircle(Offset(36 * u, 12 * u), 2 * u, fill);
      canvas.drawCircle(Offset(12 * u, 36 * u), 2 * u, fill);
      canvas.restore();
    }

    // Small diamonds at the middle of each edge.
    void diamond(Offset p) {
      final d = 5 * u;
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy - d)
          ..lineTo(p.dx + d, p.dy)
          ..lineTo(p.dx, p.dy + d)
          ..lineTo(p.dx - d, p.dy)
          ..close(),
        fill,
      );
    }

    diamond(r1.topCenter);
    diamond(r1.bottomCenter);
    diamond(r1.centerLeft);
    diamond(r1.centerRight);
  }

  @override
  bool shouldRepaint(OrnateBorderPainter old) => old.color != color || old.unit != unit;
}

/// Marigold toran (garland) with mango leaves, hung along the top edge.
class ToranPainter extends CustomPainter {
  const ToranPainter({required this.unit});
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final u = unit;
    final sag = 16 * u;
    final string = Paint()
      ..color = const Color(0xFF6D4C41)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * u;
    canvas.drawPath(
      Path()
        ..moveTo(0, 6 * u)
        ..quadraticBezierTo(size.width / 2, 6 * u + sag * 2, size.width, 6 * u),
      string,
    );
    double yAt(double x) {
      final t = x / size.width;
      return 6 * u + sag * 2 * 2 * t * (1 - t);
    }

    final count = (size.width / (22 * u)).floor();
    final gap = size.width / count;
    for (var i = 0; i <= count; i++) {
      final x = i * gap;
      final y = yAt(x);
      // Hanging mango leaf between flowers.
      if (i < count) {
        final lx = x + gap / 2;
        final ly = yAt(lx);
        final leaf = Path()
          ..moveTo(lx, ly)
          ..quadraticBezierTo(lx + 6 * u, ly + 12 * u, lx, ly + 24 * u)
          ..quadraticBezierTo(lx - 6 * u, ly + 12 * u, lx, ly)
          ..close();
        canvas.drawPath(leaf, Paint()..color = const Color(0xFF2E7D32));
        canvas.drawLine(
          Offset(lx, ly + 2 * u),
          Offset(lx, ly + 22 * u),
          Paint()
            ..color = const Color(0xFF81C784)
            ..strokeWidth = .8 * u,
        );
      }
      // Marigold: petal ring + darker centre.
      final colors = i.isEven
          ? [const Color(0xFFFFD54F), const Color(0xFFFF8F00)]
          : [const Color(0xFFFFB74D), const Color(0xFFE65100)];
      final petal = Paint()..color = colors[0];
      for (var k = 0; k < 10; k++) {
        final a = k * math.pi / 5;
        canvas.drawCircle(Offset(x + 6 * u * math.cos(a), y + 6 * u * math.sin(a)), 4.2 * u, petal);
      }
      canvas.drawCircle(Offset(x, y), 6 * u, Paint()..color = colors[1]);
      canvas.drawCircle(Offset(x, y), 2.5 * u, Paint()..color = colors[0]);
    }
  }

  @override
  bool shouldRepaint(ToranPainter old) => old.unit != unit;
}

/// A row of lit clay diyas along the bottom edge.
class DiyaRowPainter extends CustomPainter {
  const DiyaRowPainter({required this.unit, this.count = 5});
  final double unit;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final u = unit;
    final gap = size.width / count;
    for (var i = 0; i < count; i++) {
      final cx = gap * (i + .5);
      final base = size.height - 4 * u;
      // Glow.
      canvas.drawCircle(
        Offset(cx, base - 22 * u),
        22 * u,
        Paint()
          ..shader = RadialGradient(colors: [const Color(0x88FFD54F), const Color(0x00FFD54F)])
              .createShader(Rect.fromCircle(center: Offset(cx, base - 22 * u), radius: 22 * u)),
      );
      // Bowl.
      final bowl = Path()
        ..moveTo(cx - 16 * u, base - 12 * u)
        ..quadraticBezierTo(cx, base + 4 * u, cx + 16 * u, base - 12 * u)
        ..lineTo(cx + 9 * u, base - 12 * u)
        ..quadraticBezierTo(cx, base - 9 * u, cx - 9 * u, base - 12 * u)
        ..close();
      canvas.drawPath(
        bowl,
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFFFFCA28), Color(0xFFBF6F00)])
              .createShader(Rect.fromLTWH(cx - 16 * u, base - 14 * u, 32 * u, 16 * u)),
      );
      // Flame.
      final flame = Path()
        ..moveTo(cx, base - 34 * u)
        ..quadraticBezierTo(cx + 7 * u, base - 20 * u, cx, base - 13 * u)
        ..quadraticBezierTo(cx - 7 * u, base - 20 * u, cx, base - 34 * u)
        ..close();
      canvas.drawPath(
        flame,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF59D), Color(0xFFFF9800), Color(0xFFE65100)],
          ).createShader(Rect.fromLTWH(cx - 7 * u, base - 34 * u, 14 * u, 21 * u)),
      );
    }
  }

  @override
  bool shouldRepaint(DiyaRowPainter old) => old.unit != unit || old.count != count;
}

/// Layered mandala: petal rings, dotted circles and a lotus centre.
class MandalaPainter extends CustomPainter {
  const MandalaPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .006;
    final fill = Paint()..color = color;

    void petals(double inner, double outer, int n, {double width = .5, bool filled = false}) {
      final step = 2 * math.pi / n;
      for (var i = 0; i < n; i++) {
        final a = i * step;
        final p = Path()
          ..moveTo(c.dx + inner * math.cos(a - step * width / 2), c.dy + inner * math.sin(a - step * width / 2))
          ..quadraticBezierTo(
            c.dx + outer * 1.02 * math.cos(a - step * width / 3),
            c.dy + outer * 1.02 * math.sin(a - step * width / 3),
            c.dx + outer * math.cos(a),
            c.dy + outer * math.sin(a),
          )
          ..quadraticBezierTo(
            c.dx + outer * 1.02 * math.cos(a + step * width / 3),
            c.dy + outer * 1.02 * math.sin(a + step * width / 3),
            c.dx + inner * math.cos(a + step * width / 2),
            c.dy + inner * math.sin(a + step * width / 2),
          );
        canvas.drawPath(p, filled ? fill : line);
      }
    }

    void dots(double radius, int n, double d) {
      for (var i = 0; i < n; i++) {
        final a = i * 2 * math.pi / n;
        canvas.drawCircle(Offset(c.dx + radius * math.cos(a), c.dy + radius * math.sin(a)), d, fill);
      }
    }

    canvas.drawCircle(c, r * .98, line);
    dots(r * .94, 72, r * .008);
    petals(r * .68, r * .9, 24, width: .8);
    petals(r * .7, r * .84, 24, width: .45);
    canvas.drawCircle(c, r * .66, line);
    dots(r * .62, 48, r * .009);
    petals(r * .4, r * .58, 16, width: .85);
    canvas.drawCircle(c, r * .38, line);
    petals(r * .14, r * .34, 12, width: .9, filled: false);
    petals(r * .16, r * .28, 12, width: .5, filled: true);
    canvas.drawCircle(c, r * .12, line);
    canvas.drawCircle(c, r * .05, fill);
  }

  @override
  bool shouldRepaint(MandalaPainter old) => old.color != color;
}

/// Temple doorway: a cusped arch frame with a kalash at its crown.
class TempleArchPainter extends CustomPainter {
  const TempleArchPainter({required this.color, required this.unit});
  final Color color;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final u = unit;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * u;
    final thin = Paint()
      ..color = color.withValues(alpha: .6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 * u;
    final fill = Paint()..color = color;

    Path arch(double inset) {
      final l = inset, r = size.width - inset, b = size.height - inset;
      final top = inset + 34 * u;
      final shoulder = top + (size.width - 2 * inset) * .22;
      final mid = size.width / 2;
      return Path()
        ..moveTo(l, b)
        ..lineTo(l, shoulder)
        // Cusped (multi-lobed) arch up to the crown.
        ..quadraticBezierTo(l, top + 10 * u, mid - (mid - l) * .45, top + 8 * u)
        ..quadraticBezierTo(mid - 10 * u, top + 4 * u, mid, top - 6 * u)
        ..quadraticBezierTo(mid + 10 * u, top + 4 * u, mid + (r - mid) * .45, top + 8 * u)
        ..quadraticBezierTo(r, top + 10 * u, r, shoulder)
        ..lineTo(r, b)
        ..close();
    }

    canvas.drawPath(arch(10 * u), stroke);
    canvas.drawPath(arch(16 * u), thin);

    // Kalash with coconut and leaves at the crown.
    final cx = size.width / 2, cy = 10 * u + 22 * u;
    final pot = Path()
      ..moveTo(cx - 9 * u, cy)
      ..quadraticBezierTo(cx - 13 * u, cy + 10 * u, cx, cy + 12 * u)
      ..quadraticBezierTo(cx + 13 * u, cy + 10 * u, cx + 9 * u, cy)
      ..close();
    canvas.drawPath(pot, fill);
    canvas.drawRect(Rect.fromLTWH(cx - 6 * u, cy - 3 * u, 12 * u, 3 * u), fill);
    for (final s in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(cx, cy - 3 * u)
          ..quadraticBezierTo(cx + s * 10 * u, cy - 8 * u, cx + s * 14 * u, cy - 4 * u)
          ..quadraticBezierTo(cx + s * 8 * u, cy - 3 * u, cx, cy - 3 * u),
        fill,
      );
    }
    canvas.drawCircle(Offset(cx, cy - 8 * u), 5 * u, fill);

    // Bells hanging inside the arch.
    for (final x in [size.width * .22, size.width * .78]) {
      final top = 10 * u + 34 * u + (size.width - 20 * u) * .1;
      canvas.drawLine(Offset(x, top - 14 * u), Offset(x, top), thin);
      final bell = Path()
        ..moveTo(x - 6 * u, top + 10 * u)
        ..quadraticBezierTo(x - 6 * u, top, x, top)
        ..quadraticBezierTo(x + 6 * u, top, x + 6 * u, top + 10 * u)
        ..close();
      canvas.drawPath(bell, fill);
      canvas.drawCircle(Offset(x, top + 12 * u), 1.8 * u, fill);
    }
  }

  @override
  bool shouldRepaint(TempleArchPainter old) => old.color != color || old.unit != unit;
}

/// Temple shikhar silhouette with a flag, along the bottom edge.
class ShikharPainter extends CustomPainter {
  const ShikharPainter({required this.color, required this.unit});
  final Color color;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final u = unit;
    final paint = Paint()..color = color;
    final b = size.height, mid = size.width / 2;
    final h = size.height * .9;
    final p = Path()..moveTo(0, b);
    // Side shrines.
    for (final (x, w, ht) in [(size.width * .16, 46.0, .45), (size.width * .84, 46.0, .45)]) {
      p
        ..lineTo(x - w * u / 2, b)
        ..lineTo(x - w * u / 2, b - h * ht * .45)
        ..quadraticBezierTo(x - w * u / 3, b - h * ht, x, b - h * ht)
        ..quadraticBezierTo(x + w * u / 3, b - h * ht, x + w * u / 2, b - h * ht * .45)
        ..lineTo(x + w * u / 2, b);
    }
    canvas.drawPath(p..close(), paint);
    // Main shikhar with tiers.
    final w = 92 * u;
    final main = Path()
      ..moveTo(mid - w / 2, b)
      ..lineTo(mid - w / 2, b - h * .32)
      ..lineTo(mid - w * .42, b - h * .36)
      ..quadraticBezierTo(mid - w * .36, b - h * .82, mid, b - h * .9)
      ..quadraticBezierTo(mid + w * .36, b - h * .82, mid + w * .42, b - h * .36)
      ..lineTo(mid + w / 2, b - h * .32)
      ..lineTo(mid + w / 2, b)
      ..close();
    canvas.drawPath(main, paint);
    canvas.drawCircle(Offset(mid, b - h * .93), 4 * u, paint);
    // Flag.
    final pole = Offset(mid, b - h * .95);
    canvas.drawLine(pole, pole.translate(0, -20 * u), Paint()
      ..color = color
      ..strokeWidth = 1.4 * u);
    canvas.drawPath(
      Path()
        ..moveTo(pole.dx, pole.dy - 20 * u)
        ..lineTo(pole.dx + 18 * u, pole.dy - 15 * u)
        ..lineTo(pole.dx, pole.dy - 10 * u)
        ..close(),
      Paint()..color = const Color(0xFFFF6F00),
    );
    // Doorway glow.
    canvas.drawRRect(
      RRect.fromRectAndCorners(Rect.fromLTWH(mid - 9 * u, b - 24 * u, 18 * u, 24 * u),
          topLeft: Radius.circular(9 * u), topRight: Radius.circular(9 * u)),
      Paint()..color = const Color(0xFFFFC107).withValues(alpha: .85),
    );
  }

  @override
  bool shouldRepaint(ShikharPainter old) => old.color != color || old.unit != unit;
}

/// Lotus in bloom, drawn at the bottom centre.
class LotusPainter extends CustomPainter {
  const LotusPainter({required this.unit});
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final u = unit;
    final base = Offset(size.width / 2, size.height - 6 * u);
    void petal(double angle, double len, double wid, List<Color> colors) {
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(angle);
      final p = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-wid, -len * .5, 0, -len)
        ..quadraticBezierTo(wid, -len * .5, 0, 0);
      canvas.drawPath(
        p,
        Paint()
          ..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: colors)
              .createShader(Rect.fromLTWH(-wid, -len, wid * 2, len)),
      );
      canvas.restore();
    }

    const outer = [Color(0xFFAD1457), Color(0xFFF48FB1)];
    const inner = [Color(0xFFC2185B), Color(0xFFFFCDD2)];
    for (final a in [-1.25, 1.25]) {
      petal(a, 46 * u, 14 * u, outer);
    }
    for (final a in [-.85, .85]) {
      petal(a, 56 * u, 16 * u, outer);
    }
    for (final a in [-.42, .42]) {
      petal(a, 62 * u, 16 * u, inner);
    }
    petal(0, 68 * u, 17 * u, inner);
    // Leaves.
    for (final s in [-1.0, 1.0]) {
      final leaf = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(base.dx + s * 50 * u, base.dy - 14 * u, base.dx + s * 96 * u, base.dy - 2 * u)
        ..quadraticBezierTo(base.dx + s * 50 * u, base.dy + 6 * u, base.dx, base.dy);
      canvas.drawPath(leaf, Paint()..color = const Color(0xFF2E7D32));
    }
  }

  @override
  bool shouldRepaint(LotusPainter old) => old.unit != unit;
}

/// Soft four-point sparkles scattered over the canvas (fixed pattern).
class SparklePainter extends CustomPainter {
  const SparklePainter({required this.color, required this.unit});
  final Color color;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final paint = Paint()..color = color;
    for (var i = 0; i < 26; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final s = (1.5 + rnd.nextDouble() * 3.5) * unit;
      final path = Path()
        ..moveTo(p.dx, p.dy - s * 2)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + s * 2, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + s * 2)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - s * 2, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - s * 2);
      canvas.drawPath(path, paint..color = color.withValues(alpha: .35 + rnd.nextDouble() * .6));
    }
  }

  @override
  bool shouldRepaint(SparklePainter old) => old.color != color || old.unit != unit;
}

/// Paithani-style zari band: gold stripes with a row of triangles
/// (kangoora) and small peacock-eye dots. [flip] points them downwards.
class ZariBandPainter extends CustomPainter {
  const ZariBandPainter({required this.unit, this.flip = false});
  final double unit;
  final bool flip;

  @override
  void paint(Canvas canvas, Size size) {
    final u = unit;
    canvas.save();
    if (flip) {
      canvas.translate(0, size.height);
      canvas.scale(1, -1);
    }
    final gold = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF3B0), Color(0xFFE0A800), Color(0xFFB8860B)],
      ).createShader(Offset.zero & size);
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, h * .34), gold);
    canvas.drawRect(Rect.fromLTWH(0, h * .4, size.width, h * .05), gold);
    final step = 16 * u;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawPath(
        Path()
          ..moveTo(x, h * .45)
          ..lineTo(x + step / 2, h * .82)
          ..lineTo(x + step, h * .45)
          ..close(),
        gold,
      );
      canvas.drawCircle(Offset(x + step / 2, h * .17), 2.6 * u, Paint()..color = const Color(0xFF00695C));
      canvas.drawCircle(Offset(x + step / 2, h * .17), 1.2 * u, Paint()..color = const Color(0xFF1A237E));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ZariBandPainter old) => old.unit != unit || old.flip != flip;
}
