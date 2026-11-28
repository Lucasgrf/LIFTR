import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_editorial_page_header.dart';
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
    final hasActiveFilter = _searchQuery.isNotEmpty || _selectedMuscle != null;

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ResponsiveContainer(
              heightFactor: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LiftrEditorialPageHeader(
                    title: 'Exercícios',
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  // Search input
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: AppInput(
                      hint: 'Buscar exercício por nome...',
                      controller: _searchController,
                      prefix: Icon(
                        Icons.search_rounded,
                        color: context.appColors.textTertiary,
                      ),
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
                    onSelected: (value) =>
                        setState(() => _selectedMuscle = value),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Exercise List content
            Expanded(
              child: ResponsiveContainer(
                child: exercisesAsync.hasError && !exercisesAsync.hasValue
                    ? LayoutBuilder(
                        builder: (context, constraints) => RefreshIndicator(
                          color: context.appColors.primary,
                          onRefresh: () async {
                            await ref
                                .read(exerciseListStateProvider.notifier)
                                .refresh();
                          },
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: ErrorStateWidget(
                                  message: userFacingMessage(
                                    exercisesAsync.error!,
                                    stackTrace: exercisesAsync.stackTrace,
                                    context: 'ExerciseListScreen.build',
                                  ),
                                  safetyNote: offlineSafetyNoteFor(
                                    exercisesAsync.error!,
                                  ),
                                  onRetry: () => ref
                                      .read(exerciseListStateProvider.notifier)
                                      .refresh(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : exercisesAsync.when(
                        skipLoadingOnRefresh: exercisesAsync.hasValue,
                        skipError: exercisesAsync.hasValue,
                        loading: () => const LoadingWidget(),
                        error: (error, st) => ErrorStateWidget(
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
                        data: (allExercises) {
                          final exercises = filterExercises(
                            allExercises,
                            query: _searchQuery,
                            selectedMuscle: _selectedMuscle,
                          );
                          Future<void> refreshExercises() async {
                            final hadData = ref
                                .read(exerciseListStateProvider)
                                .hasValue;
                            final failure = await ref
                                .read(exerciseListStateProvider.notifier)
                                .refresh();
                            if (failure != null && hadData && context.mounted) {
                              final msg = userFacingMessage(
                                failure,
                                stackTrace: failure.stackTrace,
                                context: 'ExerciseListScreen.refreshExercises',
                              );
                              context.showSnackBar(
                                '$msg Mostrando dados salvos.',
                              );
                            }
                          }

                          if (exercises.isEmpty) {
                            return RefreshIndicator(
                              onRefresh: refreshExercises,
                              color: context.appColors.primary,
                              child: LayoutBuilder(
                                builder: (context, constraints) => ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
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
                                            : () => context.push(
                                                '/exercises/new',
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: refreshExercises,
                            color: context.appColors.primary,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                top: 4,
                                bottom: 20,
                              ),
                              itemCount: exercises.length,
                              itemBuilder: (context, index) {
                                final exercise = exercises[index];
                                return ExerciseCard(
                                  exercise: exercise,
                                  onTap: () =>
                                      context.push('/exercises/${exercise.id}'),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: ResponsiveContainer(
          heightFactor: 1,
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
          child: OutlinedButton.icon(
            onPressed: () => context.push('/exercises/new'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Novo exercício'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              foregroundColor: context.appColors.textPrimary,
              side: BorderSide(
                color: context.appColors.textPrimary,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.appRadius.medium),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
