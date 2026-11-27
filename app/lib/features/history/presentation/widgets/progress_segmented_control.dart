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

    return Material(
      color: colors.surfaceSubtle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.medium),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: List.generate(segments.length, (index) {
            final isSelected = selectedIndex == index;
            return Expanded(
              child: Semantics(
                selected: isSelected,
                button: true,
                label: segments[index],
                child: AnimatedContainer(
                  duration: motion.resolve(context, motion.fast),
                  curve: motion.curveStandard,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.surfaceElevated
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(radius.small),
                    border: isSelected
                        ? Border.all(color: colors.border)
                        : null,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () {
                        if (selectedIndex == index) return;
                        HapticFeedback.selectionClick();
                        onChanged(index);
                      },
                      borderRadius: BorderRadius.circular(radius.small),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Center(
                            widthFactor: 1,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ExcludeSemantics(
                                child: Text(
                                  segments[index],
                                  maxLines: 1,
                                  softWrap: false,
                                  style: context.textTheme.labelMedium?.copyWith(
                                    color: isSelected
                                        ? colors.textPrimary
                                        : colors.textTertiary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
