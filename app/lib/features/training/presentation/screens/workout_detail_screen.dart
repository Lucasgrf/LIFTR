import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/workout_card_palette.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_icon.dart';
import 'package:personal_fitness_os/core/widgets/liftr_confirm_dialog.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet.dart';
import 'package:personal_fitness_os/core/widgets/liftr_workout_card.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/workout_queue_provider.dart';
import 'package:personal_fitness_os/features/workout_session/domain/helpers/session_exercise_builder.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  const WorkoutDetailScreen({required this.workoutId, this.planId, super.key});

  final String workoutId;
  final String? planId;

  @override
  ConsumerState<WorkoutDetailScreen> createState() =>
      _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  bool _isReordering = false;
  bool _isStartingWorkout = false;

  Future<void> _startWorkout(Workout workout) async {
    if (_isStartingWorkout) return;
    setState(() => _isStartingWorkout = true);

    try {
      final useCase = ref.read(startWorkoutSessionUseCaseProvider);
      final defaultRest = ref.read(userSettingsProvider).defaultRestSeconds;
      final initialExercises = buildInitialSessionExercises(
        workout,
        defaultRestSeconds: defaultRest,
      );
      final result = await useCase.execute(
        workoutId: workout.id,
        workoutName: workout.name,
        initialExercises: initialExercises.isNotEmpty ? initialExercises : null,
      );

      if (!mounted) return;
      result.fold(
        (session) {
          ref.invalidate(dashboardDataProvider);
          context.push('/session/${session.id}');
        },
        (failure) => context.showSnackBar(
          'Erro ao iniciar treino: ${failure.message}',
          isError: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _isStartingWorkout = false);
    }
  }

  Future<void> _deleteExercise(WorkoutExercise exercise) async {
    final confirmed = await showLiftrConfirmDialog(
      context,
      title: 'Remover exercício?',
      message:
          '“${exercise.exercise?.name ?? 'Este exercício'}” será removido desta ficha.',
      confirmLabel: 'Remover',
    );
    if (confirmed != true || widget.planId == null) return;

    final result = await ref
        .read(trainingRepositoryProvider)
        .deleteWorkoutExercise(exercise.id);
    if (!mounted) return;
    result.fold(
      (_) {
        ref.invalidate(
          workoutDetailProvider((
            planId: widget.planId!,
            workoutId: widget.workoutId,
          )),
        );
        ref.invalidate(trainingPlanDetailProvider(widget.planId!));
        context.showSnackBar('Exercício removido.');
      },
      (failure) => context.showSnackBar(
        'Erro ao remover exercício: ${failure.message}',
        isError: true,
      ),
    );
  }

  Future<void> _reorderExercises(
    Workout workout,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final exercises = [...workout.exercises];
    final moved = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, moved);
    final result = await ref
        .read(reorderWorkoutExercisesUseCaseProvider)
        .execute(
          workoutId: workout.id,
          orderedWorkoutExerciseIds: exercises
              .map((exercise) => exercise.id)
              .toList(),
        );
    if (!mounted) return;
    result.fold(
      (_) => ref.invalidate(
        workoutDetailProvider((
          planId: widget.planId!,
          workoutId: widget.workoutId,
        )),
      ),
      (failure) => context.showSnackBar(
        'Erro ao reordenar: ${failure.message}',
        isError: true,
      ),
    );
  }

  void _openEditor() {
    if (_isReordering) {
      setState(() => _isReordering = false);
      return;
    }
    showLiftrSheet<void>(
      context: context,
      title: 'Ações da ficha',
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const LiftrIcon(LiftrIconName.plus),
            title: const Text('Adicionar exercício'),
            onTap: () {
              Navigator.pop(context);
              context.push(
                '/training/${widget.planId}/workout/${widget.workoutId}/add-exercise',
              );
            },
          ),
          ListTile(
            leading: const LiftrIcon(LiftrIconName.reorder),
            title: const Text('Reordenar exercícios'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _isReordering = true);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.planId == null) {
      return Scaffold(
        backgroundColor: context.appColors.background,
        body: const Center(child: Text('Programa não especificado')),
      );
    }

    final detailProvider = workoutDetailProvider((
      planId: widget.planId!,
      workoutId: widget.workoutId,
    ));
    final workoutAsync = ref.watch(detailProvider);
    final plan = ref
        .watch(trainingPlansStateProvider)
        .asData
        ?.value
        .where((item) => item.id == widget.planId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: workoutAsync.when(
        loading: () => const SafeArea(child: LiftrScreenSkeleton()),
        error: (error, stack) => ErrorStateWidget(
          message: userFacingMessage(
            error,
            stackTrace: stack,
            context: 'WorkoutDetailScreen.build',
          ),
          safetyNote: offlineSafetyNoteFor(error),
          onRetry: () => ref.invalidate(detailProvider),
        ),
        data: (workout) {
          final queue = plan == null
              ? const <Workout>[]
              : ref
                    .read(workoutQueueProvider.notifier)
                    .orderedWorkouts(plan.id, plan.workouts);
          final cardIndex = plan == null
              ? 0
              : queue.indexWhere((item) => item.id == workout.id);
          final cardColor = WorkoutCardPalette.forIndex(workout.sortOrder);
          final orderLabel = plan == null
              ? '${workout.sortOrder + 1}'
              : '${(cardIndex < 0 ? 0 : cardIndex) + 1}';

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                  children: [
                    ResponsiveContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              _IconButton(
                                label: 'Voltar',
                                icon: LiftrIconName.back,
                                onTap: () => context.pop(),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: _openEditor,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  foregroundColor:
                                      context.appColors.textPrimary,
                                  textStyle: context.textTheme.bodyMedium
                                      ?.copyWith(
                                        decoration: TextDecoration.underline,
                                      ),
                                ),
                                child: Text(
                                  _isReordering ? 'Concluir' : 'Editar',
                                ),
                              ),
                            ],
                          ),
                          LiftrWorkoutCard(
                            color: cardColor,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Ficha $orderLabel${plan == null ? '' : ' de ${plan.workouts.length}'}',
                                        style: _metaStyle(context),
                                      ),
                                    ),
                                    if (workout.estimatedDurationMinutes !=
                                        null)
                                      Text(
                                        'cerca de ${workout.estimatedDurationMinutes} min',
                                        style: _metaStyle(context),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  workout.name,
                                  style: context.textTheme.displayMedium
                                      ?.copyWith(
                                        fontSize: 40,
                                        height: 1,
                                        letterSpacing: -1.2,
                                        color: WorkoutCardPalette.ink,
                                      ),
                                ),
                                if (workout.notes?.trim().isNotEmpty ??
                                    false) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    workout.notes!.trim(),
                                    style: _cardBodyStyle(context),
                                  ),
                                ],
                                if (workout.exercises.isNotEmpty) ...[
                                  const SizedBox(height: 18),
                                  const _PrescriptionHeader(),
                                  Container(
                                    height: 2,
                                    color: WorkoutCardPalette.ink,
                                  ),
                                  for (
                                    var index = 0;
                                    index < workout.exercises.length;
                                    index++
                                  )
                                    _ExercisePrescription(
                                      exercise: workout.exercises[index],
                                      index: index + 1,
                                      isReordering: _isReordering,
                                      onTap: () => context.push(
                                        '/training/${widget.planId}/workout/${widget.workoutId}/exercise/${workout.exercises[index].id}/configure-sets',
                                      ),
                                      onDelete: () => _deleteExercise(
                                        workout.exercises[index],
                                      ),
                                      onReorder: (old, next) =>
                                          _reorderExercises(workout, old, next),
                                    ),
                                ] else ...[
                                  const SizedBox(height: 20),
                                  Text(
                                    'Toque em Editar para adicionar exercícios à ficha.',
                                    style: context.textTheme.bodyMedium
                                        ?.copyWith(
                                          color:
                                              WorkoutCardPalette.secondaryInk,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Toque num exercício para mudar séries, faixa ou carga.',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: ResponsiveContainer(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _isStartingWorkout
                            ? null
                            : () => _startWorkout(workout),
                        style: FilledButton.styleFrom(
                          backgroundColor: WorkoutCardPalette.ink,
                          foregroundColor: const Color(0xFFF4F5F0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: context.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: _isStartingWorkout
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('Começar ${workout.name}'),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

TextStyle? _metaStyle(BuildContext context) => context.textTheme.bodySmall
    ?.copyWith(color: WorkoutCardPalette.secondaryInk);
TextStyle? _cardBodyStyle(BuildContext context) =>
    context.textTheme.bodyMedium?.copyWith(color: WorkoutCardPalette.ink);

class _PrescriptionHeader extends StatelessWidget {
  const _PrescriptionHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          flex: 44,
          child: Text(
            'Exercício',
            style: context.textTheme.bodySmall?.copyWith(
              color: WorkoutCardPalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 22,
          child: Text(
            'Série',
            style: context.textTheme.bodySmall?.copyWith(
              color: WorkoutCardPalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 16,
          child: Text(
            'Reps',
            style: context.textTheme.bodySmall?.copyWith(
              color: WorkoutCardPalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 18,
          child: Text(
            'Carga',
            textAlign: TextAlign.right,
            style: context.textTheme.bodySmall?.copyWith(
              color: WorkoutCardPalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ExercisePrescription extends StatelessWidget {
  const _ExercisePrescription({
    required this.exercise,
    required this.index,
    required this.isReordering,
    required this.onTap,
    required this.onDelete,
    required this.onReorder,
  });

  final WorkoutExercise exercise;
  final int index;
  final bool isReordering;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;

  List<List<SetTemplate>> _groups() {
    final templates = [...exercise.setTemplates]
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    if (templates.isEmpty) return const [];
    final groups = <List<SetTemplate>>[];
    for (final template in templates) {
      final last = groups.isEmpty ? null : groups.last.last;
      final sameSeries =
          last != null &&
          last.setType == template.setType &&
          last.targetRepsMin == template.targetRepsMin &&
          last.targetRepsMax == template.targetRepsMax &&
          last.targetWeight == template.targetWeight;
      if (sameSeries) {
        groups.last.add(template);
      } else {
        groups.add([template]);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final groups = _groups();
    final exerciseName = exercise.exercise?.name ?? 'Exercício';
    final nameStyle = context.textTheme.bodyMedium?.copyWith(
      color: WorkoutCardPalette.ink,
      fontWeight: FontWeight.w600,
    );

    return InkWell(
      onTap: isReordering ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: WorkoutCardPalette.ink.withValues(alpha: .18),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 44,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$index. $exerciseName', style: nameStyle),
                          if (exercise.setTemplates.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'descanso ${_restLabel(exercise.setTemplates.first.restSeconds)}',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: WorkoutCardPalette.secondaryInk,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isReordering)
                      PopupMenuButton<String>(
                        tooltip: 'Opções para $exerciseName',
                        padding: EdgeInsets.zero,
                        icon: LiftrIcon(
                          LiftrIconName.more,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        onSelected: (value) {
                          if (value == 'delete') onDelete();
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Remover'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: groups.isEmpty
                    ? _PrescriptionValuesRow(
                        series: '1 a ${exercise.totalSetsCount}',
                        reps: '—',
                        load: '—',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (
                            var index = 0;
                            index < groups.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(height: 6),
                            _PrescriptionValuesRow(
                              series: _seriesLabel(groups[index]),
                              reps: _repsLabel(groups[index].first),
                              load: _loadLabel(groups[index].first),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _seriesLabel(List<SetTemplate> group) {
    final type = group.first.setType;
    if (type == SetType.warmup ||
        type == SetType.rampUp ||
        type == SetType.mobility) {
      return 'aquec.';
    }
    final first = group.first.setNumber;
    final last = group.last.setNumber;
    return first == last ? '$first' : '$first a $last';
  }

  String _repsLabel(SetTemplate template) {
    final min = template.targetRepsMin;
    final max = template.targetRepsMax;
    if (min == null && max == null) return '—';
    if (min == max) return '$min';
    if (min == null) return 'até $max';
    if (max == null) return '$min+';
    return '$min–$max';
  }

  String _loadLabel(SetTemplate template) {
    final weight = template.targetWeight;
    if (weight == null) return exercise.isCardio ? '—' : 'livre';
    final value = weight == weight.roundToDouble()
        ? weight.toInt().toString()
        : weight.toStringAsFixed(1).replaceAll('.', ',');
    return '$value kg';
  }

  String _restLabel(int seconds) {
    if (seconds % 60 == 0) return '${seconds ~/ 60} min';
    if (seconds < 60) return '$seconds s';
    return '${seconds ~/ 60} min ${seconds % 60}s';
  }
}

class _PrescriptionValuesRow extends StatelessWidget {
  const _PrescriptionValuesRow({
    required this.series,
    required this.reps,
    required this.load,
  });

  final String series;
  final String reps;
  final String load;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 39,
        child: Text(
          series,
          style: _style(context),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Expanded(
        flex: 29,
        child: Text(
          reps,
          style: _style(context),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Expanded(
        flex: 32,
        child: Text(
          load,
          textAlign: TextAlign.right,
          style: _style(context),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  TextStyle? _style(BuildContext context) =>
      context.textTheme.bodySmall?.copyWith(
        color: WorkoutCardPalette.ink,
        fontFeatures: AppTypography.tabularFeatures,
      );
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final LiftrIconName icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: LiftrIcon(icon, color: context.appColors.textPrimary),
        ),
      ),
    ),
  );
}
