import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';

class ProgressSegmentedControl extends StatelessWidget {
  const ProgressSegmentedControl({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const segments = <String>[
    'Exercícios',
    'Peso',
    'Consistência',
    'Treinos',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < segments.length; index++) ...[
              if (index > 0) const SizedBox(width: 24),
              Semantics(
                container: true,
                excludeSemantics: true,
                label: segments[index],
                button: true,
                selected: selectedIndex == index,
                onTap: () {
                  if (selectedIndex == index) return;
                  HapticFeedback.selectionClick();
                  onChanged(index);
                },
                child: InkWell(
                  excludeFromSemantics: true,
                  onTap: () {
                    if (selectedIndex == index) return;
                    HapticFeedback.selectionClick();
                    onChanged(index);
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == index
                              ? colors.textPrimary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 1),
                      child: Text(
                        segments[index],
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: selectedIndex == index
                              ? colors.textPrimary
                              : colors.textSecondary,
                          fontWeight: selectedIndex == index
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
