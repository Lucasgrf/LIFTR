import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';

class MuscleFilterChips extends ConsumerWidget {
  const MuscleFilterChips({
    super.key,
    this.horizontalPadding,
    this.selectedMuscle,
    this.onSelected,
  });

  final double? horizontalPadding;
  final String? selectedMuscle;
  final ValueChanged<String?>? onSelected;

  static const List<Map<String, String?>> muscleOptions = [
    {'label': 'Todos', 'key': null},
    {'label': 'Peito', 'key': 'chest'},
    {'label': 'Costas', 'key': 'back'},
    {'label': 'Quadríceps', 'key': 'quadriceps'},
    {'label': 'Posterior', 'key': 'hamstrings'},
    {'label': 'Glúteos', 'key': 'glutes'},
    {'label': 'Panturrilha', 'key': 'calves'},
    {'label': 'Ombros', 'key': 'shoulders'},
    {'label': 'Bíceps', 'key': 'biceps'},
    {'label': 'Tríceps', 'key': 'triceps'},
    {'label': 'Abdômen', 'key': 'abs'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final spacing = context.appSpacing;
    final effectiveSelectedMuscle = onSelected != null
        ? selectedMuscle
        : ref.watch(exerciseSelectedMuscleFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding ?? spacing.space16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            for (var index = 0; index < muscleOptions.length; index++) ...[
              if (index > 0) AppSpacing.horizontalGap8,
              Builder(
                builder: (context) {
                  final option = muscleOptions[index];
                  final key = option['key'];
                  final label = option['label']!;
                  final isSelected = effectiveSelectedMuscle == key;

                  return FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    label: Text(label),
                    labelStyle: context.textTheme.labelMedium?.copyWith(
                      color:
                          isSelected ? colors.onPrimary : colors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    backgroundColor: colors.surfaceElevated,
                    selectedColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radius.small),
                      side: BorderSide(
                        color: isSelected ? colors.primary : colors.border,
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.space8,
                      vertical: spacing.space4,
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      final nextValue = isSelected ? null : key;
                      if (onSelected != null) {
                        onSelected!(nextValue);
                      } else {
                        ref
                            .read(exerciseSelectedMuscleFilterProvider.notifier)
                            .state = nextValue;
                      }
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
