import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/utils/pt_br_copy_utils.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/charts/exercise_load_progression_chart.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_editorial_page_header.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/exercise_card.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/exercise_diagram.dart';
import 'package:personal_fitness_os/features/history/presentation/mappers/exercise_chart_mapper.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  const ExerciseDetailScreen({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  late final TextEditingController _notesController;
  bool _isSavingNotes = false;
  bool _notesInitialized = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initializeNotes(String? initialNotes) {
    if (!_notesInitialized && initialNotes != null) {
      _notesController.text = initialNotes;
      _notesInitialized = true;
    }
  }

  Future<void> _saveNotes(Exercise exercise) async {
    setState(() => _isSavingNotes = true);
    final useCase = ref.read(updateExerciseNotesUseCaseProvider);
    final result = await useCase.execute(
      exerciseId: exercise.id,
      notes: _notesController.text,
    );

    if (!mounted) return;
    setState(() => _isSavingNotes = false);

    result.fold(
      (updated) {
        ref.invalidate(exerciseDetailProvider(exercise.id));
        ref.read(exerciseListStateProvider.notifier).refresh();
        context.showSnackBar('Anotações salvas com sucesso!');
      },
      (failure) {
        context.showSnackBar(
          'Erro ao salvar anotações: ${failure.message}',
          isError: true,
        );
      },
    );
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        context.showSnackBar(
          'Não foi possível abrir o link do vídeo.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseAsync = ref.watch(exerciseDetailProvider(widget.exerciseId));
    final historyAsync = ref.watch(exerciseHistoryProvider(widget.exerciseId));

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ResponsiveContainer(
              child: LiftrEditorialPageHeader(
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/exercises');
                  }
                },
              ),
            ),
            Expanded(
              child: exerciseAsync.when(
                loading: () => const LoadingWidget(),
                error: (error, st) => ErrorStateWidget(
                  message: userFacingMessage(
                    error,
                    stackTrace: st,
                    context: 'ExerciseDetailScreen.build',
                  ),
                  safetyNote: offlineSafetyNoteFor(error),
                  onRetry: () =>
                      ref.refresh(exerciseDetailProvider(widget.exerciseId)),
                ),
                data: (exercise) {
                  _initializeNotes(exercise.personalNotes);
                  final primaryMuscleLabel = ExerciseCard.getMuscleLabel(
                    exercise.primaryMuscleGroup,
                  );
                  final equipmentLabel = ExerciseCard.getEquipmentLabel(
                    exercise.equipment,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
                    child: ResponsiveContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ExerciseDiagram(
                              exercise: exercise,
                              size: 120,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            exercise.name,
                            style: context.textTheme.displayMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            [
                              primaryMuscleLabel,
                              equipmentLabel,
                            ].where((value) => value.isNotEmpty).join(' · '),
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                          if (exercise.movementPattern != null &&
                              exercise.movementPattern!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              formatMovementPatternPtBr(
                                exercise.movementPattern,
                              ),
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.appColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Divider(color: context.appColors.divider, height: 1),

                          historyAsync.when(
                            data: (records) {
                              if (records.isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  child: ExerciseLoadProgressionChart(
                                    series: mapExerciseHistoryToLoadSeries(
                                      records,
                                      loadColor: context.appColors.primary,
                                      e1rmColor: context.appColors.info,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),

                          // Secondary Muscles
                          if (exercise.secondaryMuscles.isNotEmpty) ...[
                            Text(
                              'Também trabalha',
                              style: context.textTheme.titleMedium?.copyWith(
                                color: context.appColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: exercise.secondaryMuscles.map((muscle) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.appColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ExerciseCard.getMuscleLabel(muscle),
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                          color: context.appColors.textPrimary,
                                        ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                          ],

                          if (exercise.instructions != null &&
                              exercise.instructions!.isNotEmpty) ...[
                            Divider(
                              color: context.appColors.divider,
                              height: 1,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Execução',
                              style: context.textTheme.titleMedium?.copyWith(
                                color: context.appColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const SizedBox(height: 8),
                            Text(
                              exercise.instructions!,
                              style: context.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 20),
                          ],

                          if (exercise.commonMistakes != null &&
                              exercise.commonMistakes!.isNotEmpty) ...[
                            Text(
                              'Observações de execução',
                              style: context.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              exercise.commonMistakes!,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.appColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Video link if available
                          if (exercise.videoUrl != null &&
                              exercise.videoUrl!.isNotEmpty) ...[
                            AppButton.secondary(
                              label: 'Assistir Vídeo Demonstrativo',
                              icon: Icons.play_circle_outline_rounded,
                              onPressed: () => _openVideo(exercise.videoUrl!),
                            ),
                            const SizedBox(height: 24),
                          ],

                          Divider(color: context.appColors.divider, height: 1),
                          const SizedBox(height: 16),
                          Text(
                            'Minha ficha',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: context.appColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Anotações para lembrar na próxima vez.',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.appColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AppInput(
                            hint:
                                'Ex: Banco inclinado no terceiro furo, pegada fechada...',
                            controller: _notesController,
                            maxLines: 4,
                            keyboardType: TextInputType.multiline,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 160,
                              child: AppButton.primary(
                                label: 'Salvar Notas',
                                icon: Icons.save_rounded,
                                isLoading: _isSavingNotes,
                                onPressed: () => _saveNotes(exercise),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
