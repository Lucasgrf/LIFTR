import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';

/// Blank, ruled ficha shown when the account has no training plan yet.
class LiftrBlankFiche extends StatelessWidget {
  const LiftrBlankFiche({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(context.appRadius.small),
        border: Border.all(color: colors.divider, width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 116,
            child: CustomPaint(painter: _FicheRulePainter(colors.divider)),
          ),
          const SizedBox(height: 24),
          Text(title, style: context.textTheme.displayMedium),
          const SizedBox(height: 8),
          Text(description, style: context.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Thin empty paper edges beneath a blank ficha, matching the open deck.
class LiftrBlankFicheDeck extends StatelessWidget {
  const LiftrBlankFicheDeck({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 16,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 8,
            right: 8,
            height: 10,
            child: _BlankEdge(color: colors.divider),
          ),
          Positioned(
            top: 6,
            left: 16,
            right: 16,
            height: 10,
            child: _BlankEdge(color: colors.divider),
          ),
        ],
      ),
    );
  }
}

class _BlankEdge extends StatelessWidget {
  const _BlankEdge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
    ),
  );
}

class _FicheRulePainter extends CustomPainter {
  const _FicheRulePainter(this.lineColor);

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (var y = 31.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FicheRulePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
