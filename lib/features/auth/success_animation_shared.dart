import 'package:flutter/material.dart';

/// Shared timing and paint assets for success animations (2FA, welcome back).
const Duration successAnimationDuration = Duration(milliseconds: 1100);
const Duration welcomeBackAnimationDuration = Duration(milliseconds: 1300);
const double successBadgeSize = 140.0;
const double successCheckSize = 72.0;
const Color successBadgeColor = Color(0xFF34A853);

/// Painter that progressively draws the success check mark.
class SuccessCheckPainter extends CustomPainter {
  SuccessCheckPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.55)
      ..lineTo(size.width * 0.45, size.height * 0.75)
      ..lineTo(size.width * 0.82, size.height * 0.3);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final extractPath = metric.extractPath(
      0,
      metric.length * progress,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant SuccessCheckPainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}
