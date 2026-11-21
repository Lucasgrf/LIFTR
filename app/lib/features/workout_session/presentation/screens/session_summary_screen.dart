import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';

class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final sessionAsync = ref.watch(liveSessionDetailProvider(sessionId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Resumo do Treino'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: sessionAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, _) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(liveSessionDetailProvider(sessionId)),
        ),
        data: (session) {
          final minutes = session.durationSeconds ~/ 60;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // Celebration Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary,
                      colors.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(context.appRadius.large),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Treino Concluído!',
                      style: context.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.workoutName,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Metrics Grid
              Row(
                children: [
                  _buildStatCard(
                    context,
                    title: 'Duração',
                    value: '${minutes} min',
                    icon: Icons.timer_outlined,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    context,
                    title: 'Séries Válidas',
                    value: '${session.totalWorkingSetsCount}',
                    icon: Icons.checklist_rounded,
                    color: fitnessColors.progressNeutral,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    context,
                    title: 'Tonelagem',
                    value: '${session.totalVolumeKg.toStringAsFixed(0)} kg',
                    icon: Icons.fitness_center_rounded,
                    color: fitnessColors.progressUp,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // RPE & Mood card if available
              if (session.perceivedExertion != null || session.mood != null)
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (session.perceivedExertion != null)
                        Column(
                          children: [
                            Text(
                              'RPE Geral',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${session.perceivedExertion!.toStringAsFixed(1)} / 10',
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      if (session.mood != null)
                        Column(
                          children: [
                            Text(
                              'Sensação',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              session.mood!.name.toUpperCase(),
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: fitnessColors.progressUp,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Exercises Breakdown Title
              Text(
                'Exercícios Realizados',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Exercise List
              ...session.exercises.map((se) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              se.exercise?.name ?? 'Exercício',
                              style: context.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              '${se.completedSetsCount} séries',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (se.sets.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: se.sets.map((s) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(context.appRadius.small),
                                ),
                                child: Text(
                                  '#${s.setNumber}: ${s.weightKg}kg × ${s.repsCompleted}',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              AppButton.primary(
                label: 'Voltar ao Início',
                icon: Icons.home_rounded,
                onPressed: () => context.go('/'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.appColors.textTertiary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
