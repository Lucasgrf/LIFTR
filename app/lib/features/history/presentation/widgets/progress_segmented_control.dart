import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';

class ProgressSegmentedControl extends StatelessWidget {
  const ProgressSegmentedControl({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const List<String> segments = [
    'Exercícios',
    'Peso',
    'Consistência',
    'Treinos',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final motion = context.appMotion;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(radius.medium),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: List.generate(segments.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: Semantics(
              selected: isSelected,
              button: true,
              child: InkWell(
                onTap: () {
                  if (selectedIndex == index) return;
                  HapticFeedback.selectionClick();
                  onChanged(index);
                },
                borderRadius: BorderRadius.circular(radius.small),
                child: AnimatedContainer(
                  duration: motion.resolve(context, motion.fast),
                  curve: motion.curveStandard,
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.surfaceElevated
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(radius.small),
                    border: isSelected
                        ? Border.all(color: colors.border)
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      segments[index],
                      maxLines: 1,
                      softWrap: false,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? colors.textPrimary
                            : colors.textTertiary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
