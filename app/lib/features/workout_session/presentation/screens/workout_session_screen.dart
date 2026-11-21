import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/finish_workout_modal.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/rest_timer_widget.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/session_exercise_card.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/swap_exercise_sheet.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  Timer? _ticker;
  int _elapsedSeconds = 0;
  int _expandedIndex = 0;
  final Map<String, Exercise> _swappedExercises = {};

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatElapsed(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _handleLogSet({
    required String sessionExerciseId,
    required int setNumber,
    required SetType setType,
    required double weightKg,
    required int repsCompleted,
    int? rirActual,
    int restSeconds = 90,
    String? exerciseName,
  }) async {
    final useCase = ref.read(logSetUseCaseProvider);
    final result = await useCase.execute(
      sessionExerciseId: sessionExerciseId,
      setNumber: setNumber,
      setType: setType,
      weightKg: weightKg,
      repsCompleted: repsCompleted,
      rirActual: rirActual,
    );

    result.fold(
      (_) {
        ref.invalidate(liveSessionDetailProvider(widget.sessionId));
        ref.read(restTimerNotifierProvider.notifier).start(
              restSeconds,
              exerciseName: exerciseName,
              setNumber: setNumber,
            );
      },
      (failure) {
        context.showSnackBar(
          'Erro ao registrar série: ${failure.message}',
          isError: true,
        );
      },
    );
  }

  Future<void> _handleDeleteSet(String setId) async {
    final useCase = ref.read(deleteLoggedSetUseCaseProvider);
    final result = await useCase.execute(setId);

    result.fold(
      (_) {
        ref.invalidate(liveSessionDetailProvider(widget.sessionId));
        context.showSnackBar('Série removida.');
      },
      (failure) {
        context.showSnackBar(
          'Erro ao remover série: ${failure.message}',
          isError: true,
        );
      },
    );
  }

  Future<void> _confirmAbandonSession() async {
    final colors = context.appColors;
    final radius = context.appRadius;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(radius.medium),
              ),
              child: Icon(Icons.close_rounded, color: colors.danger),
            ),
            const SizedBox(height: 14),
            Text(
              'Descartar treino?',
              style: ctx.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'As séries registradas nesta sessão serão perdidas.',
              style: ctx.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.danger,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius.medium),
                  ),
                ),
                child: const Text('Descartar treino'),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Continuar treinando',
                  style: ctx.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final useCase = ref.read(abandonWorkoutSessionUseCaseProvider);
      await useCase.execute(widget.sessionId);
      ref.read(restTimerNotifierProvider.notifier).stop();
      if (!mounted) return;
      context.go('/');
    }
  }

  void _openFinishModal(WorkoutSession session) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FinishWorkoutModal(
        session: session,
        elapsedSeconds: _elapsedSeconds,
        onFinished: () {
          ref.read(restTimerNotifierProvider.notifier).stop();
          context.go('/session/${session.id}/summary');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final radius = context.appRadius;
    final settings = ref.watch(userSettingsProvider);
    final sessionAsync = ref.watch(liveSessionDetailProvider(widget.sessionId));
    final restRunning = ref.watch(
      restTimerNotifierProvider.select((s) => s.isRunning),
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: sessionAsync.when(
          loading: () => const LiftrScreenSkeleton(showHero: false),
          error: (err, _) => ErrorStateWidget(
            message: err.toString(),
            onRetry: () =>
                ref.invalidate(liveSessionDetailProvider(widget.sessionId)),
          ),
          data: (session) {
            final totalTargetSets = session.exercises.fold<int>(
              0,
              (sum, e) => sum + e.targetSetsCount,
            );
            final completedSets = session.totalWorkingSetsCount;
            final sessionProgress = totalTargetSets > 0
                ? (completedSets / totalTargetSets).clamp(0.0, 1.0)
                : 0.0;
            final allCompleted =
                totalTargetSets > 0 && completedSets >= totalTargetSets;

            return Column(
              children: [
                // Sticky Top Session Header
                Container(
                  color: colors.background,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 6, 12, 8),
                        child: Row(
                          children: [
                            Semantics(
                              label: 'Descartar treino',
                              button: true,
                              child: IconButton(
                                onPressed: _confirmAbandonSession,
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
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.workoutName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatElapsed(_elapsedSeconds)} · $completedSets/$totalTargetSets séries',
                                    style: context.textTheme.labelSmall
                                        ?.copyWith(
                                      color: colors.textSecondary,
                                      fontFeatures:
                                          AppTypography.tabularFeatures,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Semantics(
                              label: 'Finalizar treino',
                              button: true,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _openFinishModal(session);
                                },
                                borderRadius:
                                    BorderRadius.circular(radius.small),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 44,
                                    minWidth: 78,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: allCompleted
                                        ? fitnessColors.progressUp
                                        : fitnessColors.progressUp
                                            .withValues(alpha: 0.14),
                                    borderRadius:
                                        BorderRadius.circular(radius.small),
                                  ),
                                  child: Text(
                                    'Finalizar',
                                    style: context.textTheme.labelMedium
                                        ?.copyWith(
                                      color: allCompleted
                                          ? fitnessColors.onSuccess
                                          : fitnessColors.progressUp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      LiftrProgressBar(
                        progress: sessionProgress,
                        height: 2,
                        color: colors.primary,
                        trackColor: colors.border,
                        borderRadius: 0,
                      ),
                    ],
                  ),
                ),

                // Exercises + Docked Rest Timer
                Expanded(
                  child: session.exercises.isEmpty
                      ? Column(
                          children: [
                            Expanded(
                              child: EmptyStateWidget(
                                icon: Icons.fitness_center_rounded,
                                title: 'Nenhum exercício na sessão',
                                subtitle:
                                    'Adicione exercícios para começar seu treino.',
                                actionLabel: 'Adicionar Exercício',
                                onAction: () => context.push('/exercises'),
                              ),
                            ),
                            const SafeArea(
                              top: false,
                              child: RestTimerWidget(stepSeconds: 15),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                0,
                                12,
                                0,
                                restRunning ? 156 : 40,
                              ),
                              itemCount: session.exercises.length,
                              itemBuilder: (context, index) {
                                final rawSe = session.exercises[index];
                                final swapped = _swappedExercises[rawSe.id];
                                final se = swapped != null
                                    ? rawSe.copyWith(
                                        exerciseId: swapped.id,
                                        exercise: swapped,
                                      )
                                    : rawSe;

                                final increment = settings.incrementForEquipment(
                                  se.exercise?.equipment,
                                );

                                return ResponsiveContainer(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: SessionExerciseCard(
                                      sessionExercise: se,
                                      isExpanded: _expandedIndex == index,
                                      exerciseIndex: index,
                                      totalExercises: session.exercises.length,
                                      weightIncrement: increment,
                                      showRir: false,
                                      onToggleExpand: () => setState(() {
                                        _expandedIndex =
                                            _expandedIndex == index ? -1 : index;
                                      }),
                                      onSwapExercise: () =>
                                          SwapExerciseSheet.show(
                                        context,
                                        currentExercise: se.exercise,
                                        onSelect: (chosen) {
                                          setState(() {
                                            _swappedExercises[rawSe.id] =
                                                chosen;
                                          });
                                        },
                                      ),
                                      onLogSet: ({
                                        required sessionExerciseId,
                                        required setNumber,
                                        required setType,
                                        required weightKg,
                                        required repsCompleted,
                                        rirActual,
                                        restSeconds = 90,
                                      }) =>
                                          _handleLogSet(
                                        sessionExerciseId: sessionExerciseId,
                                        setNumber: setNumber,
                                        setType: setType,
                                        weightKg: weightKg,
                                        repsCompleted: repsCompleted,
                                        rirActual: rirActual,
                                        restSeconds: restSeconds,
                                        exerciseName: se.exercise?.name,
                                      ),
                                      onDeleteSet: _handleDeleteSet,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: SafeArea(
                                top: false,
                                child: RestTimerWidget(stepSeconds: 15),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
