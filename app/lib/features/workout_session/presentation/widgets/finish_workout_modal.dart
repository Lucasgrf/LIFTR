import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/constants/supabase_config.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet_header.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/workout_queue_provider.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/services/session_performance_calculator.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/workout_mood_icon.dart';

class FinishWorkoutModal extends ConsumerStatefulWidget {
  const FinishWorkoutModal({
    super.key,
    required this.session,
    required this.elapsedSeconds,
    required this.onFinished,
    this.embedded = false,
  });

  final WorkoutSession session;
  final int elapsedSeconds;
  final VoidCallback onFinished;
  final bool embedded;

  @override
  ConsumerState<FinishWorkoutModal> createState() => _FinishWorkoutModalState();
}

class _FinishWorkoutModalState extends ConsumerState<FinishWorkoutModal> {
  Mood _mood = Mood.good;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit(SessionPerformanceSummary perf) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final useCase = ref.read(finishWorkoutSessionUseCaseProvider);
    final result = await useCase.execute(
      sessionId: widget.session.id,
      durationSeconds: widget.elapsedSeconds > 0
          ? widget.elapsedSeconds
          : widget.session.durationSeconds,
      perceivedExertion: perf.autoRpe,
      executionScore: perf.executionScore,
      mood: _mood,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (_) {
        try {
          final activePlan =
              ref.read(dashboardDataProvider).asData?.value.activePlan ??
                  (SupabaseConfig.isConfigured
                      ? ref.read(activeTrainingPlanProvider)
                      : null);
          final completedWorkoutId = widget.session.workoutId;
          if (activePlan != null && completedWorkoutId != null) {
            ref.read(workoutQueueProvider.notifier).advanceAfterCompleted(
                  activePlan.id,
                  activePlan.workouts,
                  completedWorkoutId,
                );
          }
        } catch (_) {}
        ref.invalidate(liveSessionDetailProvider(widget.session.id));
        ref.invalidate(dashboardDataProvider);
        ref.invalidate(historyListProvider);
        ref.invalidate(currentWeekSummaryProvider);
        ref.invalidate(weeklyComparisonProvider);
        if (SupabaseConfig.isConfigured) {
          try {
            unawaited(
              ref
                  .read(weeklyComparisonRepositoryProvider)
                  .syncWeekSnapshot(DateTime.now())
                  .then((_) {}),
            );
          } catch (_) {}
        }
        Navigator.of(context).pop();
        widget.onFinished();
      },
      (failure) {
        context.showSnackBar(
          'Erro ao finalizar treino: ${failure.message}',
          isError: true,
        );
      },
    );
  }

  Widget _buildMoodSelector(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: Mood.values.map((mood) {
        final meta = WorkoutMoodMeta.resolve(context, mood);
        final isSelected = _mood == mood;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Semantics(
              label: 'Sensação: ${meta.label}',
              selected: isSelected,
              button: true,
              child: InkWell(
                onTap: () => setState(() => _mood = mood),
                borderRadius: BorderRadius.circular(radius.medium),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 62),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? meta.color.withValues(alpha: 0.16)
                        : colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(radius.medium),
                    border: Border.all(
                      color: isSelected ? meta.color : colors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      WorkoutMoodIcon(
                        mood: mood,
                        size: 24,
                        color: isSelected
                            ? meta.color
                            : meta.color.withValues(alpha: 0.72),
                      ),
                      SizedBox(height: context.appSpacing.space4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          meta.label,
                          maxLines: 1,
                          softWrap: false,
                          style: context.textTheme.labelSmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? meta.color
                                : colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final radius = context.appRadius;
    final minutes = widget.elapsedSeconds ~/ 60;
    final cardioSeconds = widget.session.totalCardioDurationSeconds;

    final prevWeightsAsync =
        ref.watch(sessionPreviousWeightsProvider(widget.session.id));
    final prevWeights = prevWeightsAsync.asData?.value ?? const <String, double>{};
    final perf = SessionPerformanceCalculator.evaluate(
      widget.session,
      previousMaxWeightByExerciseId: prevWeights,
    );

    final scoreTone = perf.executionScore >= 85
        ? LiftrBadgeTone.success
        : (perf.executionScore >= 65
            ? LiftrBadgeTone.brand
            : LiftrBadgeTone.warning);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LiftrSheetHeader(
          eyebrow: 'ENCERRAMENTO',
          title: 'Finalizar treino',
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(16),
          backgroundColor: colors.surfaceSubtle,
          child: Row(
            children: [
              Expanded(
                child: _FinishMetricItem(
                  value: '${minutes}m',
                  label: 'Duração',
                  valueColor: colors.primaryLight,
                ),
              ),
              Expanded(
                child: _FinishMetricItem(
                  value: '${widget.session.totalWorkingSetsCount}',
                  label: 'Séries válidas',
                  valueColor: fitnessColors.progressNeutral,
                ),
              ),
              if (cardioSeconds > 0)
                Expanded(
                  child: _FinishMetricItem(
                    value: formatCardioSeconds(cardioSeconds),
                    label: 'Cardio',
                    valueColor: colors.primaryLight,
                  ),
                )
              else
                Expanded(
                  child: _FinishMetricItem(
                    value: '${widget.session.totalVolumeKg.toStringAsFixed(0)} kg',
                    label: 'Volume',
                    valueColor: fitnessColors.progressUp,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Automatic RPE & Execution Score card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(radius.large),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      'AVALIAÇÃO AUTOMÁTICA',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.eyebrow(context),
                    ),
                    LiftrBadge(
                      label: perf.scoreLabel,
                      tone: scoreTone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RPE estimado',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          perf.autoRpe
                              .toStringAsFixed(1)
                              .replaceAll('.', ','),
                          style: context.textTheme.headlineMedium?.copyWith(
                            color: colors.primaryLight,
                            fontFeatures: AppTypography.tabularFeatures,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: colors.divider,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Execução',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${perf.executionScore}%',
                          style: context.textTheme.headlineMedium?.copyWith(
                            color: fitnessColors.progressUp,
                            fontFeatures: AppTypography.tabularFeatures,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                perf.rationale,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Como você se sentiu?',
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _buildMoodSelector(context),
        const SizedBox(height: 16),
        AppInput(
          label: 'Notas do treino (opcional)',
          hint: 'Ex: Bati PR no agachamento com boa técnica...',
          controller: _notesController,
          maxLines: 2,
          keyboardType: TextInputType.multiline,
        ),
        const SizedBox(height: 22),
        AppButton.primary(
          label: 'Salvar e concluir treino',
          icon: Icons.check_circle_rounded,
          isLoading: _isLoading,
          onPressed: () => _submit(perf),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius.xl)),
        border: Border.all(color: colors.border),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(child: content),
    );
  }
}

class _FinishMetricItem extends StatelessWidget {
  const _FinishMetricItem({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleLarge?.copyWith(
            color: valueColor,
            fontFeatures: AppTypography.tabularFeatures,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}
