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
    ref.read(exerciseSearchQueryProvider.notifier).state = '';
    ref.read(exerciseSelectedMuscleFilterProvider.notifier).state = null;
    ref.read(exerciseSelectedEquipmentFilterProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercisesAsync = ref.watch(filteredExercisesListProvider);
    final searchQuery = ref.watch(exerciseSearchQueryProvider);
    final selectedMuscle = ref.watch(exerciseSelectedMuscleFilterProvider);
    final hasActiveFilter = searchQuery.isNotEmpty || selectedMuscle != null;

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
      body: ResponsiveContainer(
        child: Column(
          children: [
            // Search input
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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

            // Muscle group filter chips
            const MuscleFilterChips(horizontalPadding: 0),
            const SizedBox(height: 8),

            // Exercise List content
            Expanded(
              child: filteredExercisesAsync.when(
                loading: () => const LoadingWidget(),
                error: (error, st) => ErrorStateWidget(
                  message: userFacingMessage(
                    error,
                    stackTrace: st,
                    context: 'ExerciseListScreen.build',
                  ),
                  safetyNote: offlineSafetyNoteFor(error),
                  onRetry: () => ref.read(exerciseListStateProvider.notifier).refresh(),
                ),
                data: (exercises) {
                  if (exercises.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.fitness_center_rounded,
                      title: 'Nenhum exercício encontrado',
                      subtitle: hasActiveFilter
                          ? 'Tente buscar por outro nome ou limpar os filtros aplicados.'
                          : 'Nenhum exercício cadastrado no momento.',
                      actionLabel: hasActiveFilter ? 'Limpar Filtros' : 'Criar Exercício',
                      onAction: hasActiveFilter
                          ? _clearFilters
                          : () => context.push('/exercises/new'),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(exerciseListStateProvider.notifier).refresh(),
                    color: context.appColors.primary,
                    child: ListView.builder(
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
