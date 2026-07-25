import 'dart:math';
import 'package:flutter/material.dart';

class HealthRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  HealthRingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant HealthRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class HealthHistoryPainter extends CustomPainter {
  final List<int> history;
  final Color lineColor;

  HealthHistoryPainter({required this.history, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withValues(alpha: 0.25), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final double stepX = size.width / (history.length > 1 ? history.length - 1 : 1);
    
    // Calculate Y coordinates
    double getY(int score) {
      final double percent = score / 100.0;
      return size.height - (percent * size.height * 0.8 + size.height * 0.1); // padding top/bottom
    }

    path.moveTo(0, getY(history[0]));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, getY(history[0]));

    for (int i = 0; i < history.length; i++) {
      final double x = i * stepX;
      final double y = getY(history[i]);
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
      
      // Draw point dots
      final pointPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      final outerPointPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(x, y), 3.5, pointPaint);
      canvas.drawCircle(Offset(x, y), 3.5, outerPointPaint);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HealthHistoryPainter oldDelegate) {
    return oldDelegate.history != history || oldDelegate.lineColor != lineColor;
  }
}
