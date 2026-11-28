import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/workout_card_palette.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

class ProgressWorkoutsView extends ConsumerWidget {
  const ProgressWorkoutsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final historyAsync = ref.watch(historyListProvider);
    final activePlan = ref.watch(activeTrainingPlanProvider);

    return historyAsync.when(
      skipLoadingOnRefresh: historyAsync.hasValue,
      skipError: historyAsync.hasValue,
      loading: () => const LiftrScreenSkeleton(showHero: false, itemCount: 3),
      error: (error, stack) => ErrorStateWidget(
        message: userFacingMessage(
          error,
          stackTrace: stack,
          context: 'ProgressWorkoutsView.build',
        ),
        safetyNote: offlineSafetyNoteFor(error),
        onRetry: () => ref.invalidate(historyListProvider),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nenhum treino registrado ainda',
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Conclua um treino para preencher a primeira linha do seu histórico.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: colors.textPrimary,
                  textStyle: context.textTheme.bodyMedium?.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
                child: const Text('Ir para Hoje'),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${sessions.length} ${sessions.length == 1 ? 'treino finalizado' : 'treinos finalizados'}',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontFeatures: AppTypography.tabularFeatures,
              ),
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < sessions.length; index++) ...[
              if (index > 0)
                Divider(height: 1, thickness: 1, color: colors.divider),
              _WorkoutRecordRow(
                session: sessions[index],
                fichaColor:
                    activePlan?.workouts
                            .where(
                              (workout) =>
                                  workout.id == sessions[index].workoutId,
                            )
                            .firstOrNull ==
                        null
                    ? null
                    : WorkoutCardPalette.forIndex(
                        activePlan!.workouts
                            .firstWhere(
                              (workout) =>
                                  workout.id == sessions[index].workoutId,
                            )
                            .sortOrder,
                      ),
                onTap: () =>
                    context.push('/session/${sessions[index].id}/summary'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _WorkoutRecordRow extends StatelessWidget {
  const _WorkoutRecordRow({
    required this.session,
    required this.onTap,
    this.fichaColor,
  });

  final WorkoutSession session;
  final VoidCallback onTap;
  final Color? fichaColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final date = session.completedAt ?? session.startedAt;
    final stampColor =
        fichaColor ?? WorkoutCardPalette.forWorkout(session.workoutName);
    final stampLabel = ptBrDateFormat("d 'de' MMM").format(date);
    final volume = NumberFormat(
      '#,##0',
      'pt_BR',
    ).format(session.totalVolumeKg.round());

    return Semantics(
      button: true,
      label:
          '${session.workoutName}, ${ptBrDateFormat("d 'de' MMMM, HH:mm").format(date)}, ${session.totalWorkingSetsCount} séries em ${session.durationSeconds ~/ 60} minutos, $volume quilos',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 16,
                height: 20,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: stampColor,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: WorkoutCardPalette.ink.withValues(alpha: .15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.workoutName,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          stampLabel,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${session.totalWorkingSetsCount} séries em ${session.durationSeconds ~/ 60} min, ',
                          ),
                          TextSpan(
                            text: '$volume kg',
                            style: const TextStyle(
                              color: WorkoutCardPalette.penInk,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    if (session.mood != null ||
                        session.perceivedExertion != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (session.perceivedExertion != null)
                            'RPE ${session.perceivedExertion!.toStringAsFixed(1).replaceAll('.', ',')}',
                          if (session.mood != null)
                            _moodLabel(session.mood!.name),
                        ].join(' · '),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _moodLabel(String mood) => switch (mood) {
    'awful' => 'Muito difícil',
    'bad' => 'Difícil',
    'neutral' => 'Neutro',
    'good' => 'Bom',
    'excellent' => 'Ótimo',
    _ => mood,
  };
}
