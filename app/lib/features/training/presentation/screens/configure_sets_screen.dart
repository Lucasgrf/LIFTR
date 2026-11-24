import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/set_template_row.dart';
import 'package:personal_fitness_os/features/workout_session/domain/services/rest_duration_resolver.dart';

class ConfigureSetsScreen extends ConsumerStatefulWidget {
  const ConfigureSetsScreen({
    required this.planId,
    required this.workoutId,
    required this.workoutExerciseId,
    super.key,
  });

  final String planId;
  final String workoutId;
  final String workoutExerciseId;

  @override
  ConsumerState<ConfigureSetsScreen> createState() => _ConfigureSetsScreenState();
}

class _ConfigureSetsScreenState extends ConsumerState<ConfigureSetsScreen> {
  final List<SetTemplate> _sets = [];
  bool _initialized = false;
  bool _isLoading = false;

  void _initSets(List<SetTemplate> initial) {
    if (!_initialized) {
      _sets.addAll(initial);
      if (_sets.isEmpty) {
        _sets.add(
          const SetTemplate(
            id: '',
            workoutExerciseId: '',
            setNumber: 1,
            setType: SetType.working,
            targetRepsMin: 8,
            targetRepsMax: 12,
            restSeconds: AppConstants.defaultRestSeconds,
          ),
        );
      }
      _initialized = true;
    }
  }

  void _addSet(
    SetType type, {
    bool isCardio = false,
    String? movementPattern,
    String? primaryMuscleGroup,
    String? equipment,
  }) {
    final repsMin = isCardio ? 15 : (type == SetType.warmup ? 12 : 8);
    final repsMax = isCardio ? 20 : (type == SetType.warmup ? 15 : 12);
    final rest = isCardio
        ? 0
        : RestDurationResolver.resolve(
            targetRepsMin: repsMin,
            targetRepsMax: repsMax,
            movementPattern: movementPattern,
            primaryMuscleGroup: primaryMuscleGroup,
            equipment: equipment,
            setType: type,
          );
    setState(() {
      _sets.add(
        SetTemplate(
          id: '',
          workoutExerciseId: widget.workoutExerciseId,
          setNumber: _sets.length + 1,
          setType: isCardio ? SetType.working : type,
          targetRepsMin: repsMin,
          targetRepsMax: repsMax,
          targetRirMin: !isCardio &&
                  (type == SetType.working || type == SetType.dropSet)
              ? 1
              : null,
          targetRirMax: !isCardio &&
                  (type == SetType.working || type == SetType.dropSet)
              ? 2
              : null,
          restSeconds: rest,
        ),
      );
    });
  }

  void _removeSet(int index) {
    setState(() {
      _sets.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_sets.isEmpty) {
      context.showSnackBar('Adicione ao menos uma série.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final normalizedSets = [
      for (var i = 0; i < _sets.length; i++)
        _sets[i].copyWith(
          setNumber: i + 1,
          workoutExerciseId: widget.workoutExerciseId,
        ),
    ];

    final useCase = ref.read(configureSetTemplatesUseCaseProvider);
    final result = await useCase.execute(
      workoutExerciseId: widget.workoutExerciseId,
      setTemplates: normalizedSets,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (_) {
        ref.invalidate(trainingPlanDetailProvider(widget.planId));
        context.showSnackBar('Séries atualizadas com sucesso!');
        context.pop();
      },
      (failure) {
        context.showSnackBar('Erro ao salvar séries: ${failure.message}', isError: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(
      workoutDetailProvider((planId: widget.planId, workoutId: widget.workoutId)),
    );

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text('Configurar Séries do Exercício'),
      ),
      body: workoutAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
        data: (workout) {
          final exercise = workout.exercises
              .where((e) => e.id == widget.workoutExerciseId)
              .firstOrNull;

          if (exercise == null) {
            return const Center(child: Text('Exercício não encontrado.'));
          }

          _initSets(exercise.setTemplates);
          final isCardio = exercise.isCardio;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              Text(
                exercise.exercise?.name ?? 'Exercício',
                style: context.textTheme.titleLarge?.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Sets list
              ..._sets.asMap().entries.map((entry) {
                final idx = entry.key;
                final template = entry.value;

                return AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: SetTemplateRow.getSetTypeColor(context, template.setType)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(context.appRadius.small),
                            ),
                            child: Text(
                              'Série ${idx + 1}',
                              style: TextStyle(
                                color: SetTemplateRow.getSetTypeColor(context, template.setType),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          DropdownButton<SetType>(
                            value: template.setType,
                            dropdownColor: context.appColors.surfaceElevated,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: SetType.warmup,
                                child: Text('Aquecimento'),
                              ),
                              DropdownMenuItem(
                                value: SetType.rampUp,
                                child: Text('Reconhecimento'),
                              ),
                              DropdownMenuItem(
                                value: SetType.working,
                                child: Text('Válida (Trabalho)'),
                              ),
                              DropdownMenuItem(
                                value: SetType.dropSet,
                                child: Text('Drop-set'),
                              ),
                              DropdownMenuItem(
                                value: SetType.mobility,
                                child: Text('Mobilidade'),
                              ),
                            ],
                            onChanged: (newType) {
                              if (newType != null) {
                                setState(() {
                                  _sets[idx] = template.copyWith(setType: newType);
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            color: Colors.redAccent,
                            onPressed: () => _removeSet(idx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isCardio
                                  ? 'Tempo: ${template.repRangeText} min'
                                  : 'Reps: ${template.repRangeText} · RIR: ${template.rirRangeText}',
                              style: TextStyle(color: context.appColors.textSecondary),
                            ),
                          ),
                          DropdownButton<int>(
                            value: [0, 60, 90, 120, 150, 180, 240]
                                    .contains(template.restSeconds)
                                ? template.restSeconds
                                : (isCardio ? 0 : AppConstants.defaultRestSeconds),
                            dropdownColor: context.appColors.surfaceElevated,
                            isDense: true,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('Sem descanso')),
                              DropdownMenuItem(value: 60, child: Text('60s')),
                              DropdownMenuItem(value: 90, child: Text('90s')),
                              DropdownMenuItem(value: 120, child: Text('120s')),
                              DropdownMenuItem(value: 150, child: Text('150s')),
                              DropdownMenuItem(value: 180, child: Text('180s')),
                              DropdownMenuItem(value: 240, child: Text('240s')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _sets[idx] = template.copyWith(restSeconds: v);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Add set actions
              if (isCardio)
                OutlinedButton.icon(
                  onPressed: () => _addSet(SetType.working, isCardio: true),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('+ Bloco de cardio'),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addSet(SetType.warmup),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('+ Aquecimento'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addSet(
                          SetType.working,
                          movementPattern: exercise.exercise?.movementPattern,
                          primaryMuscleGroup: exercise.exercise?.primaryMuscleGroup,
                          equipment: exercise.exercise?.equipment,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('+ Série Válida'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),

              AppButton.primary(
                label: 'Salvar Configuração de Séries',
                icon: Icons.check_rounded,
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          );
        },
      ),
    );
  }
}
