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
            restSeconds: 120,
          ),
        );
      }
      _initialized = true;
    }
  }

  void _addSet(SetType type) {
    setState(() {
      _sets.add(
        SetTemplate(
          id: '',
          workoutExerciseId: widget.workoutExerciseId,
          setNumber: _sets.length + 1,
          setType: type,
          targetRepsMin: type == SetType.warmup ? 12 : 8,
          targetRepsMax: type == SetType.warmup ? 15 : 12,
          targetRirMin: type == SetType.working ? 1 : null,
          targetRirMax: type == SetType.working ? 2 : null,
          restSeconds: type == SetType.warmup ? 60 : 120,
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
                                  .withOpacity(0.15),
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
                              'Reps: ${template.repRangeText} · RIR: ${template.rirRangeText} · ${template.restSeconds}s',
                              style: TextStyle(color: context.appColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Add set actions
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
                      onPressed: () => _addSet(SetType.working),
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
