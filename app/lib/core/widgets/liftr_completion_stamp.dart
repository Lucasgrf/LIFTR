import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';

/// Completion mark reserved for a finished workout card.
class LiftrCompletionStamp extends StatelessWidget {
  const LiftrCompletionStamp({super.key, this.date});

  final String? date;

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.success;
    final radius = context.appRadius;
    return Semantics(
      label: date == null ? 'Treino feito' : 'Treino feito em $date',
      child: Transform.rotate(
        angle: -0.139626,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.circular(radius.xs),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1),
              borderRadius: BorderRadius.circular(radius.xs - 2),
            ),
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FEITO',
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.68,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    date!,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
