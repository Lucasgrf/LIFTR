import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
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
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(radius.medium),
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
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.surfaceVariant
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(radius.small),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colors.background.withValues(alpha: 0.28),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    segments[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          );
        }),
      ),
    );
  }
}
