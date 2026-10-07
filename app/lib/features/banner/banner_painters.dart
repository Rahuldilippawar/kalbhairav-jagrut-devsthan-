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
