import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/workout_queue_provider.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';

class FinishWorkoutModal extends ConsumerStatefulWidget {
  const FinishWorkoutModal({
    super.key,
    required this.session,
    required this.elapsedSeconds,
    required this.onFinished,
  });

  final WorkoutSession session;
  final int elapsedSeconds;
  final VoidCallback onFinished;

  @override
  ConsumerState<FinishWorkoutModal> createState() => _FinishWorkoutModalState();
}

class _FinishWorkoutModalState extends ConsumerState<FinishWorkoutModal> {
  double _rpe = 8.0;
  Mood _mood = Mood.good;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final useCase = ref.read(finishWorkoutSessionUseCaseProvider);
    final result = await useCase.execute(
      sessionId: widget.session.id,
      durationSeconds: widget.elapsedSeconds > 0
          ? widget.elapsedSeconds
          : widget.session.durationSeconds,
      perceivedExertion: _rpe,
      mood: _mood,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (_) {
        final activePlan = ref.read(activeTrainingPlanProvider) ??
            ref.read(dashboardDataProvider).asData?.value.activePlan;
        final completedWorkoutId = widget.session.workoutId;
        if (activePlan != null && completedWorkoutId != null) {
          ref.read(workoutQueueProvider.notifier).advanceAfterCompleted(
                activePlan.id,
                activePlan.workouts,
                completedWorkoutId,
              );
        }
        ref.invalidate(dashboardDataProvider);
        ref.invalidate(historyListProvider);
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
    final moods = [
      (Mood.awful, '😫', 'Péssimo'),
      (Mood.bad, '😕', 'Cansado'),
      (Mood.neutral, '😐', 'Normal'),
      (Mood.good, '😊', 'Bom'),
      (Mood.excellent, '🔥', 'Ótimo'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: moods.map((m) {
        final isSelected = _mood == m.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => setState(() => _mood = m.$1),
              borderRadius: BorderRadius.circular(radius.medium),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primaryMuted
                      : colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(radius.medium),
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(m.$2, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      m.$3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? colors.primaryLight
                            : colors.textSecondary,
                      ),
                    ),
                  ],
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Text('Finalizar treino', style: context.textTheme.headlineMedium),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(16),
              backgroundColor: colors.surfaceSubtle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${minutes}m',
                        style: context.textTheme.titleLarge?.copyWith(
                          color: colors.primaryLight,
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                      ),
                      Text(
                        'Duração',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${widget.session.totalWorkingSetsCount}',
                        style: context.textTheme.titleLarge?.copyWith(
                          color: fitnessColors.progressNeutral,
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                      ),
                      Text(
                        'Séries válidas',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${widget.session.totalVolumeKg.toStringAsFixed(0)} kg',
                        style: context.textTheme.titleLarge?.copyWith(
                          color: fitnessColors.progressUp,
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                      ),
                      Text(
                        'Volume',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Esforço percebido (RPE)',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_rpe.toStringAsFixed(1)} / 10',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: colors.primaryLight,
                    fontFeatures: AppTypography.tabularFeatures,
                  ),
                ),
              ],
            ),
            Slider(
              value: _rpe,
              min: 1.0,
              max: 10.0,
              divisions: 18,
              activeColor: colors.primary,
              onChanged: (val) => setState(() => _rpe = val),
            ),
            const SizedBox(height: 12),
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
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
