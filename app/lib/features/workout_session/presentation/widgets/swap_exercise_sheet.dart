import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';

class SwapExerciseSheet extends ConsumerStatefulWidget {
  const SwapExerciseSheet({
    super.key,
    required this.currentExercise,
    required this.onSelect,
  });

  final Exercise? currentExercise;
  final ValueChanged<Exercise> onSelect;

  static Future<void> show(
    BuildContext context, {
    required Exercise? currentExercise,
    required ValueChanged<Exercise> onSelect,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SwapExerciseSheet(
        currentExercise: currentExercise,
        onSelect: onSelect,
      ),
    );
  }

  @override
  ConsumerState<SwapExerciseSheet> createState() => _SwapExerciseSheetState();
}

class _SwapExerciseSheetState extends ConsumerState<SwapExerciseSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final exercisesAsync = ref.watch(exerciseListStateProvider);
    final historyAsync = ref.watch(historyListProvider);

    final allExercises = exercisesAsync.asData?.value ?? _offlineFallback;
    final currentMuscle =
        widget.currentExercise?.primaryMuscleGroup.toLowerCase() ?? '';
    final currentId = widget.currentExercise?.id;

    // Extract previously used exercises and their last working weight from history
    final lastWeightByExerciseId = <String, double>{};
    final usedExercisesById = <String, Exercise>{};
    final sessions = historyAsync.asData?.value ?? const [];
    for (final session in sessions) {
      for (final se in session.exercises) {
        if (se.exercise != null && se.sets.isNotEmpty) {
          usedExercisesById.putIfAbsent(se.exerciseId, () => se.exercise!);
          lastWeightByExerciseId.putIfAbsent(
            se.exerciseId,
            () => se.sets.first.weightKg,
          );
        }
      }
    }

    final filtered = allExercises.where((e) {
      if (e.id == currentId) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return e.name.toLowerCase().contains(q) ||
          e.primaryMuscleGroup.toLowerCase().contains(q);
    }).toList();

    final usedList = filtered
        .where((e) => usedExercisesById.containsKey(e.id))
        .toList();
    final usedIds = usedList.map((e) => e.id).toSet();

    final suggestedList = filtered
        .where(
          (e) =>
              !usedIds.contains(e.id) &&
              currentMuscle.isNotEmpty &&
              e.primaryMuscleGroup.toLowerCase() == currentMuscle,
        )
        .toList();
    final suggestedIds = suggestedList.map((e) => e.id).toSet();

    final catalogList = filtered
        .where((e) => !usedIds.contains(e.id) && !suggestedIds.contains(e.id))
        .toList();

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.78,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius.xl)),
        border: Border.all(color: colors.border),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(radius.full),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentMuscle.isNotEmpty
                              ? currentMuscle.toUpperCase()
                              : 'SUBSTITUIÇÃO',
                          style: AppTypography.eyebrow(context),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Trocar exercício',
                          style: context.textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'Fechar troca de exercício',
                    button: true,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Buscar exercício...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                children: [
                  if (usedList.isNotEmpty) ...[
                    const _SheetSectionLabel('JÁ USADOS POR VOCÊ'),
                    ...usedList.map(
                      (ex) => _SwapOptionRow(
                        exercise: ex,
                        subtitle:
                            'Última carga: ${lastWeightByExerciseId[ex.id]?.toStringAsFixed(1).replaceAll('.0', '') ?? '--'} kg',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onSelect(ex);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (suggestedList.isNotEmpty) ...[
                    const _SheetSectionLabel('SUGERIDOS PARA O MESMO GRUPO'),
                    ...suggestedList.map(
                      (ex) => _SwapOptionRow(
                        exercise: ex,
                        subtitle: 'Mesmo grupo muscular',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onSelect(ex);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (catalogList.isNotEmpty) ...[
                    const _SheetSectionLabel('CATÁLOGO COMPLETO'),
                    ...catalogList.map(
                      (ex) => _SwapOptionRow(
                        exercise: ex,
                        subtitle: ex.primaryMuscleGroup,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onSelect(ex);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                  if (usedList.isEmpty &&
                      suggestedList.isEmpty &&
                      catalogList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Nenhum exercício encontrado para "$_query".',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  const _SheetSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(label, style: AppTypography.eyebrow(context)),
    );
  }
}

class _SwapOptionRow extends StatelessWidget {
  const _SwapOptionRow({
    required this.exercise,
    required this.subtitle,
    required this.onTap,
  });

  final Exercise exercise;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name, style: context.textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

const List<Exercise> _offlineFallback = [
  Exercise(
    id: 'fallback-hack',
    name: 'Hack Squat',
    primaryMuscleGroup: 'legs',
    equipment: 'machine',
  ),
  Exercise(
    id: 'fallback-front-squat',
    name: 'Agachamento Frontal',
    primaryMuscleGroup: 'legs',
    equipment: 'barbell',
  ),
  Exercise(
    id: 'fallback-leg-ext',
    name: 'Cadeira Extensora',
    primaryMuscleGroup: 'legs',
    equipment: 'machine',
  ),
  Exercise(
    id: 'fallback-incline-db',
    name: 'Supino Inclinado com Halteres',
    primaryMuscleGroup: 'chest',
    equipment: 'dumbbell',
  ),
  Exercise(
    id: 'fallback-row',
    name: 'Remada Curvada',
    primaryMuscleGroup: 'back',
    equipment: 'barbell',
  ),
];
