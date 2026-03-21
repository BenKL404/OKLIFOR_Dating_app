import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/theme_extensions.dart';

/// Anneau type jauge (piste discrète + progression en [AppColors.togoRed]) à la place du dégradé Instagram.
class OklStoryGaugeRing extends StatelessWidget {
  const OklStoryGaugeRing({
    super.key,
    required this.outerSize,
    required this.child,
    this.showRing = true,
    this.progress = 1,
    this.strokeWidth = 2.5,
  });

  final double outerSize;
  final Widget child;
  final bool showRing;
  /// 0–1 : portion du cercle remplie en rouge (1 = statut non lu / actif).
  final double progress;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    if (!showRing) return child;

    final track = context.oklMeetIsDark
        ? Colors.white.withValues(alpha: 0.22)
        : context.oklOnSurface.withValues(alpha: 0.14);

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(outerSize, outerSize),
            painter: _StoryGaugeRingPainter(
              progress: progress.clamp(0.0, 1.0),
              trackColor: track,
              progressColor: AppColors.togoRed,
              strokeWidth: strokeWidth,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _StoryGaugeRingPainter extends CustomPainter {
  _StoryGaugeRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.shortestSide - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(c, r, trackPaint);

    final arcPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: c, radius: r);
    const start = -math.pi / 2;
    if (progress >= 0.999) {
      canvas.drawCircle(c, r, arcPaint);
    } else if (progress > 0) {
      canvas.drawArc(rect, start, 2 * math.pi * progress, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StoryGaugeRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
