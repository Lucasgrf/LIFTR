import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/exercise_card.dart';

class MuscleFilterChips extends ConsumerWidget {
  const MuscleFilterChips({super.key});

  static const List<Map<String, String?>> muscleOptions = [
    {'label': 'Todos', 'key': null},
    {'label': 'Peito', 'key': 'chest'},
    {'label': 'Costas', 'key': 'back'},
    {'label': 'Quadríceps', 'key': 'quadriceps'},
    {'label': 'Posterior', 'key': 'hamstrings'},
    {'label': 'Glúteos', 'key': 'glutes'},
    {'label': 'Panturrilha', 'key': 'calves'},
    {'label': 'Ombros', 'key': 'anterior_deltoid'},
    {'label': 'Bíceps', 'key': 'biceps'},
    {'label': 'Tríceps', 'key': 'triceps'},
    {'label': 'Abdômen', 'key': 'abs'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMuscle = ref.watch(exerciseSelectedMuscleFilterProvider);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: muscleOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = muscleOptions[index];
          final key = option['key'];
          final label = option['label']!;
          final isSelected = selectedMuscle == key;

          final chipColor = key == null
              ? context.appColors.primary
              : ExerciseCard.getMuscleColor(context, key);

          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            label: Text(label),
            labelStyle: context.textTheme.labelMedium?.copyWith(
              color: isSelected ? Colors.white : context.appColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            backgroundColor: context.appColors.surfaceVariant,
            selectedColor: chipColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.appRadius.full),
              side: BorderSide(
                color: isSelected ? chipColor : context.appColors.border,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onSelected: (selected) {
              ref.read(exerciseSelectedMuscleFilterProvider.notifier).state =
                  isSelected ? null : key;
            },
          );
        },
      ),
    );
  }
}
