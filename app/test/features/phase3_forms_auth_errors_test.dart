import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/repositories/exercise_repository.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/exercise_history_modal.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/add_exercise_to_workout_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/configure_sets_screen.dart';

class _ToggleErrorExerciseRepo implements ExerciseRepository {
  bool shouldFail = true;

  @override
  Future<Result<Exercise, Failure>> createCustomExercise({
    required String name,
    required String primaryMuscleGroup,
    List<String>? secondaryMuscles,
    String? equipment,
    String? movementPattern,
    String? instructions,
    String? commonMistakes,
    String? videoUrl,
    String? personalNotes,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<void, Failure>> deleteCustomExercise(String id) async =>
      const Success(null);

  @override
  Future<Result<Exercise, Failure>> getExerciseById(String id) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<Exercise>, Failure>> getExercises() async {
    if (shouldFail) {
      return const Err(NetworkFailure('SocketException: offline'));
    }
    return const Success([
      Exercise(
        id: 'ex-1',
        name: 'Supino Reto',
        primaryMuscleGroup: 'chest',
        equipment: 'barbell',
      ),
    ]);
  }

  @override
  Future<Result<Exercise, Failure>> updateExerciseNotes({
    required String exerciseId,
    required String notes,
  }) async =>
      throw UnimplementedError();
}

void main() {
  group('UX-04 ErrorStateWidget & Tentar novamente', () {
    testWidgets('ExerciseHistoryModal renders ErrorStateWidget and retries',
        (tester) async {
      var shouldFail = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseHistoryProvider('ex-1').overrideWith((ref) async {
              if (shouldFail) {
                throw TimeoutException('Timed out');
              }
              return const [];
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(
              body: ExerciseHistoryModal(
                exerciseId: 'ex-1',
                exerciseName: 'Agachamento Livre',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.textContaining('demorou mais que o esperado'), findsOneWidget);
      expect(find.text(kOfflineDataSafetyNote), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      shouldFail = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text('Nenhum histórico encontrado'), findsOneWidget);
    });

    testWidgets(
        'AddExerciseToWorkoutScreen shows ErrorStateWidget and retries on failure',
        (tester) async {
      final repo = _ToggleErrorExerciseRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const AddExerciseToWorkoutScreen(
              planId: 'plan-1',
              workoutId: 'w-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.textContaining('Sem conexão com a internet'), findsOneWidget);
      expect(find.text(kOfflineDataSafetyNote), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      repo.shouldFail = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text('Supino Reto'), findsOneWidget);
    });

    testWidgets(
        'ConfigureSetsScreen shows ErrorStateWidget with Tentar novamente on error',
        (tester) async {
      var shouldFail = true;
      const sampleWorkout = Workout(
        id: 'w-1',
        trainingPlanId: 'plan-1',
        name: 'Treino A',
        dayOfWeek: 1,
        exercises: [
          WorkoutExercise(
            id: 'we-1',
            workoutId: 'w-1',
            exerciseId: 'ex-1',
            exercise: Exercise(
              id: 'ex-1',
              name: 'Agachamento Livre',
              primaryMuscleGroup: 'legs',
              equipment: 'barbell',
            ),
            setTemplates: [
              SetTemplate(
                id: 'st-1',
                workoutExerciseId: 'we-1',
                setNumber: 1,
                setType: SetType.working,
                targetRepsMin: 8,
                targetRepsMax: 12,
                restSeconds: 120,
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutDetailProvider((planId: 'plan-1', workoutId: 'w-1'))
                .overrideWith((ref) async {
              if (shouldFail) {
                throw Exception('503 Service Unavailable');
              }
              return sampleWorkout;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const ConfigureSetsScreen(
              planId: 'plan-1',
              workoutId: 'w-1',
              workoutExerciseId: 'we-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(
        find.textContaining('servidor está temporariamente indisponível'),
        findsOneWidget,
      );
      expect(find.text(kOfflineDataSafetyNote), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      shouldFail = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text('Agachamento Livre'), findsOneWidget);
    });
  });
}
