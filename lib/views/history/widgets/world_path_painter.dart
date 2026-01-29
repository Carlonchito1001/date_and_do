import 'dart:math';
import 'package:flutter/material.dart';

enum WorldPathStyle { smooth, dashed, dotted, wave }

class WorldPathPainter extends CustomPainter {
  final List<Offset> normalizedPoints; // 0..1
  final WorldPathStyle style;
  final double strokeWidth;
  final Color color;
  final double opacity;

  WorldPathPainter(
    this.normalizedPoints, {
    this.style = WorldPathStyle.smooth,
    this.strokeWidth = 4,
    this.color = Colors.white,
    this.opacity = 0.7,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (normalizedPoints.length < 2) return;

    final points = normalizedPoints
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = _buildSmoothPath(points);

    switch (style) {
      case WorldPathStyle.smooth:
        canvas.drawPath(path, paint);
        break;

      case WorldPathStyle.dashed:
        _drawDashedPath(canvas, path, paint, dash: 14, gap: 10);
        break;

      case WorldPathStyle.dotted:
        _drawDashedPath(canvas, path, paint, dash: 2, gap: 12);
        break;

      case WorldPathStyle.wave:
        final wavePath = _buildWavePath(path, amplitude: 5, wavelength: 26);
        canvas.drawPath(wavePath, paint);
        break;
    }
  }

  Path _buildSmoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      path.quadraticBezierTo(mid.dx, mid.dy, p1.dx, p1.dy);
    }
    return path;
  }

  void _drawDashedPath(
    Canvas canvas,
    Path source,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = min(distance + dash, metric.length);
        final extract = metric.extractPath(distance, next);
        canvas.drawPath(extract, paint);
        distance = next + gap;
      }
    }
  }

  Path _buildWavePath(
    Path source, {
    double amplitude = 5,
    double wavelength = 26,
  }) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      final len = metric.length;
      if (len <= 1) continue;

      for (double d = 0; d <= len; d += 2) {
        final t = d / len;
        final pos = metric.getTangentForOffset(d);
        if (pos == null) continue;

        final normal = Offset(-pos.vector.dy, pos.vector.dx); // perpendicular
        final wave = sin(t * 2 * pi * (len / wavelength)) * amplitude;
        final p =
            pos.position +
            normal * (wave / (normal.distance == 0 ? 1 : normal.distance));

        if (d == 0) {
          out.moveTo(p.dx, p.dy);
        } else {
          out.lineTo(p.dx, p.dy);
        }
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant WorldPathPainter oldDelegate) {
    return oldDelegate.normalizedPoints != normalizedPoints ||
        oldDelegate.style != style ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.opacity != opacity;
  }
}
