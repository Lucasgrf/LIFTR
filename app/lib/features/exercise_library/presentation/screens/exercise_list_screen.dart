import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/exercise_card.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/muscle_filter_chips.dart';

class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String? _selectedMuscle;

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

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedMuscle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseListStateProvider);
    final filteredExercisesAsync = exercisesAsync.whenData(
      (exercises) => filterExercises(
        exercises,
        query: _searchQuery,
        selectedMuscle: _selectedMuscle,
      ),
    );
    final hasActiveFilter = _searchQuery.isNotEmpty || _selectedMuscle != null;

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text('Biblioteca de Exercícios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
            onPressed: () => ref.read(exerciseListStateProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveContainer(
          child: Column(
            children: [
            // Search input
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: AppInput(
                hint: 'Buscar exercício por nome...',
                controller: _searchController,
                prefix: Icon(Icons.search_rounded, color: context.appColors.textTertiary),
                suffix: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),

            // Muscle group filter chips
            MuscleFilterChips(
              horizontalPadding: 0,
              selectedMuscle: _selectedMuscle,
              onSelected: (value) => setState(() => _selectedMuscle = value),
            ),
            const SizedBox(height: 8),

            // Exercise List content
            Expanded(
              child: filteredExercisesAsync.when(
                loading: () => const LoadingWidget(),
                error: (error, st) => RefreshIndicator(
                  onRefresh: () =>
                      ref.read(exerciseListStateProvider.notifier).refresh(),
                  color: context.appColors.primary,
                  child: LayoutBuilder(
                    builder: (context, constraints) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: ErrorStateWidget(
                            message: userFacingMessage(
                              error,
                              stackTrace: st,
                              context: 'ExerciseListScreen.build',
                            ),
                            safetyNote: offlineSafetyNoteFor(error),
                            onRetry: () => ref
                                .read(exerciseListStateProvider.notifier)
                                .refresh(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (exercises) {
                  if (exercises.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => ref
                          .read(exerciseListStateProvider.notifier)
                          .refresh(),
                      color: context.appColors.primary,
                      child: LayoutBuilder(
                        builder: (context, constraints) => ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: EmptyStateWidget(
                                icon: Icons.fitness_center_rounded,
                                title: 'Nenhum exercício encontrado',
                                subtitle: hasActiveFilter
                                    ? 'Tente buscar por outro nome ou limpar os filtros aplicados.'
                                    : 'Nenhum exercício cadastrado no momento.',
                                actionLabel: _searchQuery.isNotEmpty
                                    ? 'Limpar busca'
                                    : (hasActiveFilter
                                        ? 'Limpar Filtros'
                                        : 'Criar Exercício'),
                                onAction: hasActiveFilter
                                    ? _clearFilters
                                    : () => context.push('/exercises/new'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(exerciseListStateProvider.notifier).refresh(),
                    color: context.appColors.primary,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 4, bottom: 88),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return ExerciseCard(
                          exercise: exercise,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          onTap: () => context.push('/exercises/${exercise.id}'),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/exercises/new'),
        backgroundColor: context.appColors.primary,
        foregroundColor: context.appColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Novo Exercício',
          style: context.textTheme.labelLarge?.copyWith(
            color: context.appColors.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
