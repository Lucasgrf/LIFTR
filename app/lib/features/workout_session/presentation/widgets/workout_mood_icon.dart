import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';

class WorkoutMoodMeta {
  const WorkoutMoodMeta({
    required this.mood,
    required this.label,
    required this.level,
    required this.color,
  });

  final Mood mood;
  final String label;
  final int level;
  final Color color;

  static WorkoutMoodMeta resolve(BuildContext context, Mood mood) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    switch (mood) {
      case Mood.awful:
        return WorkoutMoodMeta(
          mood: mood,
          label: 'Fraco',
          level: 1,
          color: colors.danger,
        );
      case Mood.bad:
        return WorkoutMoodMeta(
          mood: mood,
          label: 'Cansado',
          level: 2,
          color: fitnessColors.dropSetTag,
        );
      case Mood.neutral:
        return WorkoutMoodMeta(
          mood: mood,
          label: 'Normal',
          level: 3,
          color: colors.textSecondary,
        );
      case Mood.good:
        return WorkoutMoodMeta(
          mood: mood,
          label: 'Forte',
          level: 4,
          color: colors.info,
        );
      case Mood.excellent:
        return WorkoutMoodMeta(
          mood: mood,
          label: 'Muito forte',
          level: 5,
          color: fitnessColors.progressUp,
        );
    }
  }
}

/// Custom gym-focused flexed-arm + strength-bar vector icon in the
/// Technical Humanism / Modular Vector Kinematics style, replacing emojis.
class WorkoutMoodIcon extends StatelessWidget {
  const WorkoutMoodIcon({
    super.key,
    required this.mood,
    this.size = 24,
    this.color,
  });

  final Mood mood;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final meta = WorkoutMoodMeta.resolve(context, mood);
    final effectiveColor = color ?? meta.color;

    return Semantics(
      label: 'Sensação: ${meta.label}',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _WorkoutMoodArmPainter(
            level: meta.level,
            color: effectiveColor,
          ),
        ),
      ),
    );
  }
}

class _WorkoutMoodArmPainter extends CustomPainter {
  const _WorkoutMoodArmPainter({
    required this.level,
    required this.color,
  });

  final int level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.085).clamp(1.5, 2.6)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Stylized geometric flexed arm (silhouette evolves from relaxed to peaked)
    final armPath = Path();
    if (level <= 1) {
      // Low/relaxed arm angle
      armPath.moveTo(w * 0.14, h * 0.56);
      armPath.lineTo(w * 0.46, h * 0.58);
      armPath.lineTo(w * 0.68, h * 0.46);
      armPath.lineTo(w * 0.74, h * 0.36);
      canvas.drawPath(armPath, stroke);
      canvas.drawCircle(Offset(w * 0.75, h * 0.33), w * 0.075, fill);
    } else if (level == 2) {
      // Mildly raised forearm
      armPath.moveTo(w * 0.14, h * 0.58);
      armPath.lineTo(w * 0.44, h * 0.58);
      armPath.quadraticBezierTo(w * 0.40, h * 0.45, w * 0.32, h * 0.48);
      armPath.moveTo(w * 0.44, h * 0.58);
      armPath.lineTo(w * 0.64, h * 0.38);
      armPath.lineTo(w * 0.68, h * 0.28);
      canvas.drawPath(armPath, stroke);
      canvas.drawCircle(Offset(w * 0.69, h * 0.25), w * 0.08, fill);
    } else if (level == 3) {
      // Steady 90-deg flexed arm
      armPath.moveTo(w * 0.14, h * 0.58);
      armPath.lineTo(w * 0.46, h * 0.58);
      armPath.quadraticBezierTo(w * 0.40, h * 0.40, w * 0.26, h * 0.45);
      armPath.moveTo(w * 0.46, h * 0.58);
      armPath.lineTo(w * 0.58, h * 0.32);
      armPath.lineTo(w * 0.54, h * 0.22);
      canvas.drawPath(armPath, stroke);
      canvas.drawCircle(Offset(w * 0.52, h * 0.19), w * 0.085, fill);
    } else if (level == 4) {
      // Strong flexed bicep peak
      armPath.moveTo(w * 0.14, h * 0.58);
      armPath.lineTo(w * 0.48, h * 0.58);
      armPath.quadraticBezierTo(w * 0.36, h * 0.33, w * 0.22, h * 0.43);
      armPath.moveTo(w * 0.48, h * 0.58);
      armPath.lineTo(w * 0.58, h * 0.28);
      armPath.lineTo(w * 0.48, h * 0.20);
      canvas.drawPath(armPath, stroke);
      canvas.drawCircle(Offset(w * 0.45, h * 0.18), w * 0.09, fill);
    } else {
      // Peak contraction + sharp power ticks
      armPath.moveTo(w * 0.14, h * 0.58);
      armPath.lineTo(w * 0.50, h * 0.58);
      armPath.quadraticBezierTo(w * 0.35, h * 0.29, w * 0.20, h * 0.42);
      armPath.moveTo(w * 0.50, h * 0.58);
      armPath.lineTo(w * 0.60, h * 0.26);
      armPath.lineTo(w * 0.48, h * 0.18);
      canvas.drawPath(armPath, stroke);
      canvas.drawCircle(Offset(w * 0.45, h * 0.17), w * 0.095, fill);

      // Power ticks above bicep peak
      final tickStroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.065).clamp(1.2, 2.0)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(w * 0.28, h * 0.22),
        Offset(w * 0.24, h * 0.13),
        tickStroke,
      );
      canvas.drawLine(
        Offset(w * 0.36, h * 0.18),
        Offset(w * 0.36, h * 0.09),
        tickStroke,
      );
    }

    // 2. Five-bar strength meter along the bottom edge
    final barTrackPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final barGap = w * 0.045;
    final totalBarsWidth = w * 0.72;
    final barWidth = (totalBarsWidth - barGap * 4) / 5;
    final startX = (w - totalBarsWidth) / 2;
    final baseY = h * 0.90;

    for (var i = 0; i < 5; i++) {
      final barHeight = h * (0.09 + i * 0.025);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          startX + i * (barWidth + barGap),
          baseY - barHeight,
          barWidth,
          barHeight,
        ),
        Radius.circular(barWidth * 0.35),
      );
      canvas.drawRRect(rect, (i + 1) <= level ? fill : barTrackPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WorkoutMoodArmPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.color != color;
  }
}

class WorkoutMoodChip extends StatelessWidget {
  const WorkoutMoodChip({
    super.key,
    required this.mood,
    this.compact = false,
  });

  final Mood mood;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final meta = WorkoutMoodMeta.resolve(context, mood);
    final radius = context.appRadius;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radius.small),
        border: Border.all(
          color: meta.color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          WorkoutMoodIcon(
            mood: mood,
            size: compact ? 16 : 18,
            color: meta.color,
          ),
          const SizedBox(width: 5),
          Text(
            meta.label,
            style: context.textTheme.labelSmall?.copyWith(
              color: meta.color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 11,
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
        ],
      ),
    );
  }
}
