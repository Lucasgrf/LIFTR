import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
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
    final moods = [
      (Mood.awful, '😫', 'Péssimo'),
      (Mood.bad, '😕', 'Cansado'),
      (Mood.neutral, '😐', 'Normal'),
      (Mood.good, '😊', 'Bom'),
      (Mood.excellent, '🔥', 'Excelente'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: moods.map((m) {
        final isSelected = _mood == m.$1;
        return InkWell(
          onTap: () => setState(() => _mood = m.$1),
          borderRadius: BorderRadius.circular(context.appRadius.medium),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.appColors.primary.withOpacity(0.2)
                  : context.appColors.surfaceVariant,
              borderRadius: BorderRadius.circular(context.appRadius.medium),
              border: Border.all(
                color: isSelected
                    ? context.appColors.primary
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(m.$2, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  m.$3,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? context.appColors.primary
                        : context.appColors.textSecondary,
                  ),
                ),
              ],
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

    final minutes = widget.elapsedSeconds ~/ 60;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Finalizar Treino',
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Summary metrics grid
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${minutes}m',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
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
                          fontWeight: FontWeight.bold,
                          color: fitnessColors.progressNeutral,
                        ),
                      ),
                      Text(
                        'Séries Válidas',
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
                          fontWeight: FontWeight.bold,
                          color: fitnessColors.progressUp,
                        ),
                      ),
                      Text(
                        'Tonelagem',
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

            // RPE Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Percepção de Esforço (RPE Geral):',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${_rpe.toStringAsFixed(1)} / 10',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
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
            const SizedBox(height: 16),

            // Mood
            Text(
              'Como você está se sentindo?',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _buildMoodSelector(context),
            const SizedBox(height: 16),

            // Notes
            AppInput(
              label: 'Notas do Treino (Opcional)',
              hint: 'Ex: Treino muito produtivo, bati PR no supino...',
              controller: _notesController,
              maxLines: 2,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),

            AppButton.primary(
              label: 'Salvar e Concluir Treino',
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
