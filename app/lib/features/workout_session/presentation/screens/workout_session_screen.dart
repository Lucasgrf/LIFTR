import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/finish_workout_modal.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/rest_timer_widget.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/session_exercise_card.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/session_timer_header.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  Timer? _ticker;
  int _elapsedSeconds = 0;

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
        context.showSnackBar('Erro ao registrar série: ${failure.message}', isError: true);
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
        context.showSnackBar('Erro ao remover série: ${failure.message}', isError: true);
      },
    );
  }

  Future<void> _confirmAbandonSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar Treino?'),
        content: const Text(
          'Os dados deste treino não serão contabilizados no seu histórico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: ctx.fitnessColors.progressDown),
            child: const Text('Descartar'),
          ),
        ],
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
    showModalBottomSheet(
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
    final sessionAsync = ref.watch(liveSessionDetailProvider(widget.sessionId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: sessionAsync.when(
          data: (s) => Text(s.workoutName),
          loading: () => const Text('Executando Treino'),
          error: (_, __) => const Text('Treino'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Descartar Treino',
            onPressed: _confirmAbandonSession,
          ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, _) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(liveSessionDetailProvider(widget.sessionId)),
        ),
        data: (session) {
          if (session.exercises.isEmpty) {
            return Column(
              children: [
                Expanded(
                  child: EmptyStateWidget(
                    icon: Icons.fitness_center_rounded,
                    title: 'Nenhum exercício na sessão',
                    subtitle: 'Adicione exercícios para começar seu treino.',
                    actionLabel: 'Adicionar Exercício',
                    onAction: () => context.push('/exercises'),
                  ),
                ),
                const RestTimerWidget(),
              ],
            );
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  // Timer & metrics header
                  SessionTimerHeader(
                    session: session,
                    elapsedSeconds: _elapsedSeconds,
                  ),
                  const SizedBox(height: 16),

                  // Exercises list
                  ...session.exercises.map(
                    (se) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SessionExerciseCard(
                        sessionExercise: se,
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
                  ),

                  const SizedBox(height: 8),

                  // Finish Button
                  AppButton.primary(
                    label: 'Finalizar Treino',
                    icon: Icons.flag_rounded,
                    onPressed: () => _openFinishModal(session),
                  ),
                ],
              ),

              // Floating Rest Timer Bar at Bottom
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: RestTimerWidget(),
              ),
            ],
          );
        },
      ),
    );
  }
}
