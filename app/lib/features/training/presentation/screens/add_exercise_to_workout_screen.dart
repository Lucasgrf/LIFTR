import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/exercise_card.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/muscle_filter_chips.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/services/rest_duration_resolver.dart';

class AddExerciseToWorkoutScreen extends ConsumerStatefulWidget {
  const AddExerciseToWorkoutScreen({
    required this.planId,
    required this.workoutId,
    super.key,
  });

  final String planId;
  final String workoutId;

  @override
  ConsumerState<AddExerciseToWorkoutScreen> createState() =>
      _AddExerciseToWorkoutScreenState();
}

class _AddExerciseToWorkoutScreenState
    extends ConsumerState<AddExerciseToWorkoutScreen> {
  late final TextEditingController _searchController;
  Exercise? _selectedExercise;

  // Set parameters
  int _warmupSetsCount = 0;
  int _workingSetsCount = 3;
  int _repsMin = 8;
  int _repsMax = 12;
  int _rirMin = 1;
  int _rirMax = 2;
  int _restSeconds = AppConstants.defaultRestSeconds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedExercise == null) return;

    setState(() => _isLoading = true);

    final initialSets = <SetTemplate>[];
    var currentSetNumber = 1;

    // Warmup sets
    for (var i = 0; i < _warmupSetsCount; i++) {
      initialSets.add(
        SetTemplate(
          id: '',
          workoutExerciseId: '',
          setNumber: currentSetNumber++,
          setType: SetType.warmup,
          targetRepsMin: 12,
          targetRepsMax: 15,
          restSeconds: 60,
        ),
      );
    }

    // Working sets
    for (var i = 0; i < _workingSetsCount; i++) {
      initialSets.add(
        SetTemplate(
          id: '',
          workoutExerciseId: '',
          setNumber: currentSetNumber++,
          setType: SetType.working,
          targetRepsMin: _repsMin,
          targetRepsMax: _repsMax,
          targetRirMin: _rirMin,
          targetRirMax: _rirMax,
          restSeconds: _restSeconds,
        ),
      );
    }

    final useCase = ref.read(addExerciseToWorkoutUseCaseProvider);
    final result = await useCase.execute(
      workoutId: widget.workoutId,
      exerciseId: _selectedExercise!.id,
      initialSetTemplates: initialSets,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (created) {
        ref.invalidate(trainingPlanDetailProvider(widget.planId));
        context.showSnackBar('"${_selectedExercise!.name}" adicionado com sucesso!');
        context.pop();
      },
      (failure) {
        context.showSnackBar(userFacingMessage(failure), isError: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedExercise != null) {
      return _buildPrescribeSetsView();
    }

    final filteredExercisesAsync = ref.watch(filteredExercisesListProvider);
    final searchQuery = ref.watch(exerciseSearchQueryProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text('Selecionar Exercício'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppInput(
              hint: 'Buscar exercício por nome...',
              controller: _searchController,
              prefix: Icon(Icons.search_rounded, color: context.appColors.textTertiary),
              suffix: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(exerciseSearchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              onChanged: (value) {
                ref.read(exerciseSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          const MuscleFilterChips(),
          const SizedBox(height: 8),

          Expanded(
            child: filteredExercisesAsync.when(
              loading: () => const LoadingWidget(),
              error: (err, _) => ErrorStateWidget(
                message: userFacingMessage(err),
                safetyNote: kOfflineDataSafetyNote,
                onRetry: () =>
                    ref.read(exerciseListStateProvider.notifier).refresh(),
              ),
              data: (exercises) {
                if (exercises.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.search_off_rounded,
                    title: 'Nenhum exercício encontrado',
                    subtitle: 'Tente alterar os termos de busca.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return ExerciseCard(
                      exercise: exercise,
                      onTap: () {
                        final recommendedRest = exercise.isCardio
                            ? 60
                            : RestDurationResolver.resolve(
                                targetRepsMin: _repsMin,
                                targetRepsMax: _repsMax,
                                movementPattern: exercise.movementPattern,
                                primaryMuscleGroup: exercise.primaryMuscleGroup,
                                equipment: exercise.equipment,
                              );
                        setState(() {
                          _selectedExercise = exercise;
                          _restSeconds = recommendedRest;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescribeSetsView() {
    final exercise = _selectedExercise!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() => _selectedExercise = null);
        }
      },
      child: Scaffold(
        backgroundColor: context.appColors.background,
        appBar: AppBar(
          title: const Text('Prescrever Séries'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => setState(() => _selectedExercise = null),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
          // Selected Exercise Card
          ExerciseCard(exercise: exercise),
          const SizedBox(height: 16),

          // Working Sets count
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuração de Séries',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                // Warmup sets counter
                _buildCounterRow(
                  title: 'Séries de Aquecimento',
                  subtitle: 'Não computam no volume semanal efetivo',
                  value: _warmupSetsCount,
                  onDecrement: _warmupSetsCount > 0
                      ? () => setState(() => _warmupSetsCount--)
                      : null,
                  onIncrement: () => setState(() => _warmupSetsCount++),
                ),
                const Divider(height: 24),

                // Working sets counter
                _buildCounterRow(
                  title: 'Séries Válidas (Trabalho)',
                  subtitle: 'Séries levadas próximas até a falha (RIR 0-3)',
                  value: _workingSetsCount,
                  onDecrement: _workingSetsCount > 1
                      ? () => setState(() => _workingSetsCount--)
                      : null,
                  onIncrement: () => setState(() => _workingSetsCount++),
                ),
                const Divider(height: 24),

                // Rep Range
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Faixa de Repetições',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        _buildSmallNumberSelector(
                          value: _repsMin,
                          onChanged: (v) => setState(() => _repsMin = v),
                          min: 1,
                          max: _repsMax,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('a'),
                        ),
                        _buildSmallNumberSelector(
                          value: _repsMax,
                          onChanged: (v) => setState(() => _repsMax = v),
                          min: _repsMin,
                          max: 50,
                        ),
                        const SizedBox(width: 6),
                        const Text('reps'),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Rest seconds
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tempo de Descanso',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    DropdownButton<int>(
                      value: _restSeconds,
                      dropdownColor: context.appColors.surfaceElevated,
                      items: const [
                        DropdownMenuItem(value: 60, child: Text('60s (1:00)')),
                        DropdownMenuItem(value: 90, child: Text('90s (1:30)')),
                        DropdownMenuItem(value: 120, child: Text('120s (2:00)')),
                        DropdownMenuItem(value: 150, child: Text('150s (2:30)')),
                        DropdownMenuItem(value: 180, child: Text('180s (3:00)')),
                        DropdownMenuItem(value: 240, child: Text('240s (4:00)')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _restSeconds = v);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          AppButton.primary(
            label: 'Confirmar e Adicionar ao Treino',
            icon: Icons.check_rounded,
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildCounterRow({
    required String title,
    required String subtitle,
    required int value,
    required VoidCallback? onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.appColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded),
              onPressed: onDecrement,
              color: context.appColors.primary,
            ),
            Text(
              '$value',
              style: context.textTheme.titleMedium?.copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: onIncrement,
              color: context.appColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallNumberSelector({
    required int value,
    required ValueChanged<int> onChanged,
    required int min,
    required int max,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.appColors.surfaceVariant,
        borderRadius: BorderRadius.circular(context.appRadius.small),
        border: Border.all(color: context.appColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          dropdownColor: context.appColors.surfaceElevated,
          isDense: true,
          items: List.generate(
            max - min + 1,
            (idx) => DropdownMenuItem(
              value: min + idx,
              child: Text('${min + idx}'),
            ),
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
