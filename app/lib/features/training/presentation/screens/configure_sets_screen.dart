import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
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

  static const List<int> restOptions = [0, 60, 90, 120, 150, 180, 240];

  /// Builds the rest duration options for the dropdown, preserving any
  /// custom [currentSeconds] value outside [restOptions] without mutating it.
  static List<int> restDropdownValuesFor(int currentSeconds) {
    if (restOptions.contains(currentSeconds)) {
      return restOptions;
    }
    return [...restOptions, currentSeconds]..sort();
  }

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
        context.showSnackBar(
          userFacingMessage(failure, context: 'ConfigureSetsScreen._save'),
          isError: true,
        );
      },
    );
  }

  Widget _buildInputPair(
    BuildContext context, {
    required Widget first,
    required Widget second,
    double horizontalGap = 8,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 300;
        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              AppSpacing.verticalGap8,
              second,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            SizedBox(width: horizontalGap),
            Expanded(child: second),
          ],
        );
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
      body: SafeArea(
        top: false,
        child: workoutAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => ErrorStateWidget(
          message: userFacingMessage(
            err,
            stackTrace: st,
            context: 'ConfigureSetsScreen.build',
          ),
          safetyNote: offlineSafetyNoteFor(err),
          onRetry: () => ref.invalidate(
            workoutDetailProvider(
              (planId: widget.planId, workoutId: widget.workoutId),
            ),
          ),
        ),
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
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 40),
            children: [
              ResponsiveContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  padding: EdgeInsets.all(context.appSpacing.space16),
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final badge = Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SetTemplateRow.getSetTypeColor(
                                context,
                                template.setType,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                context.appRadius.small,
                              ),
                            ),
                            child: Text(
                              'Série ${idx + 1}',
                              style: context.textTheme.labelLarge?.copyWith(
                                color: SetTemplateRow.getSetTypeColor(
                                  context,
                                  template.setType,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                          final isCompact = constraints.maxWidth < 300;
                          const setTypeLabels = <SetType, String>{
                            SetType.warmup: 'Aquecimento',
                            SetType.rampUp: 'Reconhecimento',
                            SetType.working: 'Válida (Trabalho)',
                            SetType.dropSet: 'Drop-set',
                            SetType.mobility: 'Mobilidade',
                          };
                          final typeDropdown = DropdownButton<SetType>(
                            value: template.setType,
                            isExpanded: true,
                            alignment: isCompact
                                ? AlignmentDirectional.centerStart
                                : AlignmentDirectional.centerEnd,
                            dropdownColor: context.appColors.surfaceElevated,
                            underline: const SizedBox(),
                            selectedItemBuilder: (context) => [
                              for (final label in setTypeLabels.values)
                                Align(
                                  alignment: isCompact
                                      ? AlignmentDirectional.centerStart
                                      : AlignmentDirectional.centerEnd,
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            items: [
                              for (final entry in setTypeLabels.entries)
                                DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(
                                    entry.value,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (newType) {
                              if (newType != null) {
                                setState(() {
                                  final cur = _sets[idx];
                                  _sets[idx] = cur.copyWith(setType: newType);
                                });
                              }
                            },
                          );
                          final deleteButton = IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                            ),
                            color: context.appColors.danger,
                            tooltip: 'Remover série',
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            onPressed: () => _removeSet(idx),
                          );

                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(child: badge),
                                    deleteButton,
                                  ],
                                ),
                                typeDropdown,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              badge,
                              AppSpacing.horizontalGap8,
                              Expanded(child: typeDropdown),
                              deleteButton,
                            ],
                          );
                        },
                      ),
                      AppSpacing.verticalGap12,
                      if (isCardio)
                        _buildInputPair(
                          context,
                          first: AppNumericInput(
                            label: 'Min. mín.',
                            value: (template.targetRepsMin ?? 15).toDouble(),
                            min: 1,
                            max: 180,
                            unit: 'min',
                            onChanged: (v) {
                              final nextMin = v.round();
                              setState(() {
                                final cur = _sets[idx];
                                final curMax = cur.targetRepsMax ?? nextMin;
                                final nextMax =
                                    nextMin > curMax ? nextMin : curMax;
                                _sets[idx] = cur.copyWith(
                                  targetRepsMin: nextMin,
                                  targetRepsMax: nextMax,
                                );
                              });
                            },
                          ),
                          second: AppNumericInput(
                            label: 'Min. máx.',
                            value: (template.targetRepsMax ?? 20).toDouble(),
                            min: 1,
                            max: 180,
                            unit: 'min',
                            onChanged: (v) {
                              final nextMax = v.round();
                              setState(() {
                                final cur = _sets[idx];
                                final curMin = cur.targetRepsMin ?? nextMax;
                                final nextMin =
                                    nextMax < curMin ? nextMax : curMin;
                                _sets[idx] = cur.copyWith(
                                  targetRepsMin: nextMin,
                                  targetRepsMax: nextMax,
                                );
                              });
                            },
                          ),
                        )
                      else ...[
                        _buildInputPair(
                          context,
                          first: AppNumericInput(
                            label: 'Reps mín.',
                            value: (template.targetRepsMin ?? 8).toDouble(),
                            min: 1,
                            max: 50,
                            onChanged: (v) {
                              final nextMin = v.round();
                              setState(() {
                                final cur = _sets[idx];
                                final curMax = cur.targetRepsMax ?? nextMin;
                                final nextMax =
                                    nextMin > curMax ? nextMin : curMax;
                                _sets[idx] = cur.copyWith(
                                  targetRepsMin: nextMin,
                                  targetRepsMax: nextMax,
                                );
                              });
                            },
                          ),
                          second: AppNumericInput(
                            label: 'Reps máx.',
                            value: (template.targetRepsMax ?? 12).toDouble(),
                            min: 1,
                            max: 50,
                            onChanged: (v) {
                              final nextMax = v.round();
                              setState(() {
                                final cur = _sets[idx];
                                final curMin = cur.targetRepsMin ?? nextMax;
                                final nextMin =
                                    nextMax < curMin ? nextMax : curMin;
                                _sets[idx] = cur.copyWith(
                                  targetRepsMin: nextMin,
                                  targetRepsMax: nextMax,
                                );
                              });
                            },
                          ),
                        ),
                        AppSpacing.verticalGap8,
                        _buildInputPair(
                          context,
                          first: AppNumericInput(
                            label: 'RIR mín.',
                            value: (template.targetRirMin ?? 1).toDouble(),
                            min: 0,
                            max: 5,
                            onChanged: (v) {
                              final nextMin = v.round();
                              setState(() {
                                final cur = _sets[idx];
                                final curMax = cur.targetRirMax ?? nextMin;
                                final nextMax =
                                    nextMin > curMax ? nextMin : curMax;
                                _sets[idx] = cur.copyWith(
                                  targetRirMin: nextMin,
                                  targetRirMax: nextMax,
                                );
                              });
                            },
                          ),
                          second: AppNumericInput(
                            label: 'RIR máx.',
                            value: (template.targetRirMax ?? 2).toDouble(),
                            min: 0,
                            max: 5,
                            onChanged: (v) {
                              final nextMax = v.round();
                              setState(() {
                                final cur = _sets[idx];
                                final curMin = cur.targetRirMin ?? nextMax;
                                final nextMin =
                                    nextMax < curMin ? nextMax : curMin;
                                _sets[idx] = cur.copyWith(
                                  targetRirMin: nextMin,
                                  targetRirMax: nextMax,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                      AppSpacing.verticalGap8,
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 300;
                          final restValues =
                              ConfigureSetsScreen.restDropdownValuesFor(
                            template.restSeconds,
                          );
                          String formatRest(int v) => v == 0
                              ? 'Sem descanso'
                              : ConfigureSetsScreen.restOptions.contains(v)
                                  ? '${v}s'
                                  : '${v}s (personalizado)';
                          final labelWidget = Text(
                            'Descanso',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          );
                          final restDropdown = DropdownButton<int>(
                            value: template.restSeconds,
                            isExpanded: true,
                            alignment: isCompact
                                ? AlignmentDirectional.centerStart
                                : AlignmentDirectional.centerEnd,
                            dropdownColor: context.appColors.surfaceElevated,
                            isDense: true,
                            underline: const SizedBox(),
                            selectedItemBuilder: (context) => [
                              for (final v in restValues)
                                Align(
                                  alignment: isCompact
                                      ? AlignmentDirectional.centerStart
                                      : AlignmentDirectional.centerEnd,
                                  child: Text(
                                    formatRest(v),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            items: restValues
                                .map(
                                  (v) => DropdownMenuItem<int>(
                                    value: v,
                                    child: Text(
                                      formatRest(v),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  final cur = _sets[idx];
                                  _sets[idx] = cur.copyWith(restSeconds: v);
                                });
                              }
                            },
                          );

                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                labelWidget,
                                AppSpacing.verticalGap4,
                                restDropdown,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              labelWidget,
                              AppSpacing.horizontalGap8,
                              Expanded(child: restDropdown),
                            ],
                          );
                        },
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
                  label: const Text(
                    '+ Bloco de cardio',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                _buildInputPair(
                  context,
                  horizontalGap: 10,
                  first: OutlinedButton.icon(
                    onPressed: () => _addSet(SetType.warmup),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      '+ Aquecimento',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  second: OutlinedButton.icon(
                    onPressed: () => _addSet(
                      SetType.working,
                      movementPattern: exercise.exercise?.movementPattern,
                      primaryMuscleGroup: exercise.exercise?.primaryMuscleGroup,
                      equipment: exercise.exercise?.equipment,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      '+ Série Válida',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              AppButton.primary(
                label: 'Salvar Configuração de Séries',
                icon: Icons.check_rounded,
                isLoading: _isLoading,
                onPressed: _save,
              ),
                  ],
                ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }
}
