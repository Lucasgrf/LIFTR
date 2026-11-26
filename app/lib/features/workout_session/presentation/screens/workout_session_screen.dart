import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/offline_banner_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/services/rest_duration_resolver.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/finish_workout_modal.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/rest_timer_widget.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/session_elapsed_text.dart';
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
  int _expandedIndex = 0;
  int _collapseManualSignal = 0;
  bool _leavingSession = false;
  final Map<String, Exercise> _swappedExercises = {};

  Future<void> _handleLogSet({
    required String sessionExerciseId,
    required int setNumber,
    required SetType setType,
    required double weightKg,
    required int repsCompleted,
    int? durationSeconds,
    int? rirActual,
    int restSeconds = AppConstants.defaultRestSeconds,
    List<DropSetEntry> dropSets = const [],
    String? existingSetId,
    String? exerciseName,
    bool isCardio = false,
  }) async {
    final useCase = ref.read(logSetUseCaseProvider);
    final result = await useCase.execute(
      sessionExerciseId: sessionExerciseId,
      setNumber: setNumber,
      setType: setType,
      weightKg: weightKg,
      repsCompleted: repsCompleted,
      durationSeconds: durationSeconds,
      rirActual: rirActual,
      isWarmup: setType == SetType.warmup,
      dropSets: dropSets,
      existingSetId: existingSetId,
    );

    result.fold(
      (_) {
        ref.invalidate(liveSessionDetailProvider(widget.sessionId));
        if (!isCardio && restSeconds > 0) {
          ref.read(restTimerNotifierProvider.notifier).start(
                restSeconds,
                exerciseName: exerciseName,
                setNumber: setNumber,
              );
        }
      },
      (failure) {
        context.showSnackBar(
          'Erro ao registrar série: ${failure.message}',
          isError: true,
        );
      },
    );
  }

  Future<void> _handleDeleteSet(
    String setId, {
    String? exerciseName,
    String? sessionExerciseId,
    LoggedSet? deletedSet,
    bool isCardio = false,
  }) async {
    final useCase = ref.read(deleteLoggedSetUseCaseProvider);
    final result = await useCase.execute(setId);
    if (!mounted) return;

    result.fold(
      (_) {
        ref.invalidate(liveSessionDetailProvider(widget.sessionId));
        final timerState = ref.read(restTimerNotifierProvider);
        if (timerState.isVisible &&
            deletedSet != null &&
            timerState.setNumber == deletedSet.setNumber &&
            (exerciseName == null || timerState.exerciseName == exerciseName)) {
          ref.read(restTimerNotifierProvider.notifier).stop();
        }
        if (deletedSet != null && sessionExerciseId != null) {
          final messenger = ScaffoldMessenger.maybeOf(context);
          messenger?.hideCurrentSnackBar();
          messenger?.showSnackBar(
            SnackBar(
              content: Text('Série ${deletedSet.setNumber} desmarcada'),
              action: SnackBarAction(
                label: 'Desfazer',
                onPressed: () {
                  _handleLogSet(
                    sessionExerciseId: sessionExerciseId,
                    setNumber: deletedSet.setNumber,
                    setType: deletedSet.setType,
                    weightKg: deletedSet.weightKg,
                    repsCompleted: deletedSet.repsCompleted,
                    durationSeconds: deletedSet.durationSeconds,
                    rirActual: deletedSet.rirActual,
                    restSeconds: 0,
                    dropSets: deletedSet.dropSets,
                    exerciseName: exerciseName,
                    isCardio: isCardio,
                  );
                },
              ),
            ),
          );
        } else {
          context.showSnackBar('Série desfeita.');
        }
      },
      (failure) {
        context.showSnackBar(
          'Erro ao desfazer série: ${failure.message}',
          isError: true,
        );
      },
    );
  }

  Future<void> _handleAddExercise(
    WorkoutSession session,
    Exercise chosen,
  ) async {
    final useCase = ref.read(addExerciseToSessionUseCaseProvider);
    final result = await useCase.execute(
      sessionId: session.id,
      exerciseId: chosen.id,
      sortOrder: session.exercises.length,
    );

    if (!mounted) return;
    result.fold(
      (_) {
        ref.invalidate(liveSessionDetailProvider(widget.sessionId));
      },
      (failure) {
        context.showSnackBar(
          'Erro ao adicionar exercício: ${failure.message}',
          isError: true,
        );
      },
    );
  }

  Future<void> _handleSwapExercise(
    SessionExercise currentSe,
    Exercise chosen,
  ) async {
    final previous = _swappedExercises[currentSe.id];
    setState(() {
      _swappedExercises[currentSe.id] = chosen;
    });

    final useCase = ref.read(swapSessionExerciseUseCaseProvider);
    final result = await useCase.execute(
      sessionExerciseId: currentSe.id,
      newExerciseId: chosen.id,
      replacedExerciseId: currentSe.replacedExerciseId ?? currentSe.exerciseId,
    );

    if (!mounted) return;
    result.fold(
      (_) {
        ref.invalidate(liveSessionDetailProvider(widget.sessionId));
      },
      (failure) {
        setState(() {
          if (previous != null) {
            _swappedExercises[currentSe.id] = previous;
          } else {
            _swappedExercises.remove(currentSe.id);
          }
        });
        context.showSnackBar(
          'Erro ao trocar exercício: ${failure.message}',
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
            AppButton.destructive(
              label: 'Descartar treino',
              onPressed: () => Navigator.of(ctx).pop(true),
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
      _leavingSession = true;
      context.go('/');
    }
  }

  void _openFinishModal(WorkoutSession session) {
    final elapsedSeconds = SessionElapsedText.computeElapsedSeconds(
      session.startedAt,
      now: ref.read(appClockProvider)(),
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FinishWorkoutModal(
        session: session,
        elapsedSeconds: elapsedSeconds,
        onFinished: () {
          ref.read(restTimerNotifierProvider.notifier).stop();
          if (mounted) {
            _leavingSession = true;
          }
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
    final spacing = context.appSpacing;
    final settings = ref.watch(userSettingsProvider);
    ref.watch(sessionAutoSyncProvider);
    final isOffline = ref.watch(isOfflineModeProvider);
    final pendingSyncCount = ref.watch(pendingSyncCountProvider);
    final sessionAsync = ref.watch(liveSessionDetailProvider(widget.sessionId));
    final restVisible = ref.watch(
      restTimerNotifierProvider.select((s) => s.isVisible),
    );
    final restMinimized = ref.watch(
      restTimerNotifierProvider.select((s) => s.isMinimized),
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop || _leavingSession) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text(
              'Treino continua ativo. Você pode retomá-lo em "Hoje".',
            ),
          ),
        );
      },
      child: Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (isOffline)
              OfflineBannerWidget(pendingChangesCount: pendingSyncCount),
            Expanded(
              child: sessionAsync.when(
                loading: () => const LiftrScreenSkeleton(showHero: false),
                error: (err, _) => ErrorStateWidget(
                  message: err.toString(),
                  onRetry: () =>
                      ref.invalidate(liveSessionDetailProvider(widget.sessionId)),
                ),
                data: (session) {
            final totalTargetSets = session.exercises
                .where((e) => !e.isCardio)
                .fold<int>(0, (sum, e) => sum + e.targetSetsCount);
            final completedSets = session.totalWorkingSetsCount;
            final cardioExercises =
                session.exercises.where((e) => e.isCardio).toList();
            final cardioCompleted = cardioExercises.where(
              (e) => e.totalCardioDurationSeconds > 0,
            ).length;
            final totalProgressUnits =
                totalTargetSets + cardioExercises.length;
            final completedProgressUnits = completedSets + cardioCompleted;
            final sessionProgress = totalProgressUnits > 0
                ? (completedProgressUnits / totalProgressUnits).clamp(0.0, 1.0)
                : 0.0;
            final allCompleted = totalProgressUnits > 0 &&
                completedProgressUnits >= totalProgressUnits;
            final cardioSeconds = session.totalCardioDurationSeconds;
            final metaParts = [
              if (totalTargetSets > 0 || completedSets > 0)
                '$completedSets/$totalTargetSets séries',
              if (cardioSeconds > 0)
                '${formatCardioSeconds(cardioSeconds)} cardio',
            ];
            final subtitleStyle = context.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
              fontFeatures: AppTypography.tabularFeatures,
            );

            return Column(
              children: [
                // Sticky Top Session Header
                Container(
                  color: colors.background,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          spacing.space4,
                          spacing.space8,
                          spacing.space12,
                          spacing.space8,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _confirmAbandonSession,
                              tooltip: 'Descartar treino',
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              icon: Icon(
                                Icons.close_rounded,
                                color: colors.textSecondary,
                              ),
                            ),
                            SizedBox(width: spacing.space4),
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
                                  Wrap(
                                    children: [
                                      SessionElapsedText(
                                        startedAt: session.startedAt,
                                        nowProvider: ref.watch(appClockProvider),
                                        style: subtitleStyle,
                                      ),
                                      if (metaParts.isNotEmpty)
                                        Text(
                                          ' · ${metaParts.join(' · ')}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: subtitleStyle,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: spacing.space8),
                            Semantics(
                              label: 'Finalizar treino',
                              button: true,
                              child: Material(
                                color: allCompleted
                                    ? fitnessColors.progressUp
                                    : fitnessColors.progressUp
                                        .withValues(alpha: 0.14),
                                borderRadius:
                                    BorderRadius.circular(radius.small),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _openFinishModal(session);
                                  },
                                  borderRadius:
                                      BorderRadius.circular(radius.small),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 48,
                                      minWidth: 72,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: spacing.space12,
                                      ),
                                      child: Center(
                                        widthFactor: 1,
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
                                onAction: () => SwapExerciseSheet.show(
                                  context,
                                  currentExercise: null,
                                  title: 'Adicionar exercício',
                                  subtitle: 'Catálogo de exercícios',
                                  closeSemanticLabel:
                                      'Fechar seleção de exercício',
                                  onSelect: (chosen) =>
                                      _handleAddExercise(session, chosen),
                                ),
                              ),
                            ),
                            SafeArea(
                              top: false,
                              bottom: restVisible,
                              child: const RestTimerWidget(stepSeconds: 15),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            NotificationListener<ScrollUpdateNotification>(
                              onNotification: (notification) {
                                final delta = notification.scrollDelta;
                                if (delta != null && delta > 1.5) {
                                  final timerState =
                                      ref.read(restTimerNotifierProvider);
                                  if (timerState.isVisible &&
                                      !timerState.isMinimized) {
                                    ref
                                        .read(
                                            restTimerNotifierProvider.notifier)
                                        .minimize();
                                  }
                                }
                                return false;
                              },
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                excludeFromSemantics: true,
                                onTap: () => setState(() => _collapseManualSignal++),
                                child: ListView.builder(
                                padding: EdgeInsets.fromLTRB(
                                  0,
                                  spacing.space12,
                                  0,
                                  (!restVisible
                                          ? 40.0
                                          : (restMinimized ? 84.0 : 188.0)) +
                                      (allCompleted ? 88.0 : 0.0),
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

                                  final increment =
                                      settings.incrementForEquipment(
                                    se.exercise?.equipment,
                                  );

                                  return ResponsiveContainer(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: SessionExerciseCard(
                                        sessionExercise: se,
                                        isExpanded: _expandedIndex == index,
                                        exerciseIndex: index,
                                        totalExercises:
                                            session.exercises.length,
                                        weightIncrement: increment,
                                        showRir: false,
                                        collapseSignal: _collapseManualSignal,
                                        onToggleExpand: () => setState(() {
                                          _expandedIndex =
                                              _expandedIndex == index
                                                  ? -1
                                                  : index;
                                        }),
                                        onSwapExercise: () =>
                                            SwapExerciseSheet.show(
                                          context,
                                          currentExercise: se.exercise,
                                          onSelect: (chosen) =>
                                              _handleSwapExercise(
                                                  rawSe, chosen),
                                        ),
                                        onLogSet: ({
                                          required sessionExerciseId,
                                          required setNumber,
                                          required setType,
                                          required weightKg,
                                          required repsCompleted,
                                          durationSeconds,
                                          rirActual,
                                          restSeconds =
                                              AppConstants.defaultRestSeconds,
                                          dropSets = const [],
                                          existingSetId,
                                        }) {
                                          final resolvedRest = se.isCardio
                                              ? 0
                                              : RestDurationResolver.resolve(
                                                  targetRepsMin:
                                                      se.targetRepsMin,
                                                  targetRepsMax:
                                                      se.targetRepsMax,
                                                  movementPattern: se.exercise
                                                      ?.movementPattern,
                                                  primaryMuscleGroup: se
                                                      .exercise
                                                      ?.primaryMuscleGroup,
                                                  equipment:
                                                      se.exercise?.equipment,
                                                  isCardio: se.isCardio,
                                                  setType: setType,
                                                  explicitTemplateRestSeconds:
                                                      restSeconds > 0
                                                          ? restSeconds
                                                          : null,
                                                );
                                          return _handleLogSet(
                                            sessionExerciseId:
                                                sessionExerciseId,
                                            setNumber: setNumber,
                                            setType: setType,
                                            weightKg: weightKg,
                                            repsCompleted: repsCompleted,
                                            durationSeconds: durationSeconds,
                                            rirActual: rirActual,
                                            restSeconds: resolvedRest,
                                            dropSets: dropSets,
                                            existingSetId: existingSetId,
                                            exerciseName: se.exercise?.name,
                                            isCardio: se.isCardio,
                                          );
                                        },
                                        onDeleteSet: (setId) {
                                          final matched = se.sets
                                              .where((s) => s.id == setId)
                                              .firstOrNull;
                                          return _handleDeleteSet(
                                            setId,
                                            exerciseName: se.exercise?.name,
                                            sessionExerciseId: se.id,
                                            deletedSet: matched,
                                            isCardio: se.isCardio,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SafeArea(
                                    top: false,
                                    bottom: restVisible && !allCompleted,
                                    child: const RestTimerWidget(stepSeconds: 15),
                                  ),
                                  if (allCompleted)
                                    Material(
                                      color: colors.surface,
                                      child: SafeArea(
                                        top: false,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              top: BorderSide(
                                                color: colors.border,
                                              ),
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: spacing.space16,
                                            vertical: spacing.space12,
                                          ),
                                          child: ResponsiveContainer(
                                            child: AppButton.primary(
                                              label: 'Finalizar treino',
                                              icon: Icons.check_circle_rounded,
                                              onPressed: () {
                                                HapticFeedback.lightImpact();
                                                _openFinishModal(session);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
          ],
        ),
      ),
      ),
    );
  }
}
