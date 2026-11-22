import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/repositories/exercise_repository.dart';
import 'package:personal_fitness_os/features/training/domain/entities/ai_generated_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';
import 'package:personal_fitness_os/features/training/domain/services/plan_persister_service.dart';

class _FakeExerciseRepository implements ExerciseRepository {
  _FakeExerciseRepository(List<Exercise> initial)
      : _exercises = List<Exercise>.from(initial);

  final List<Exercise> _exercises;
  final List<Exercise> createdCustomExercises = [];

  @override
  Future<Result<List<Exercise>, Failure>> getExercises() async =>
      Success(List.unmodifiable(_exercises));

  @override
  Future<Result<Exercise, Failure>> getExerciseById(String id) async {
    final ex = _exercises.where((e) => e.id == id).firstOrNull;
    if (ex == null) return const Err(ServerFailure('Not found'));
    return Success(ex);
  }

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
  }) async {
    final created = Exercise(
      id: 'custom-${createdCustomExercises.length + 1}',
      name: name,
      primaryMuscleGroup: primaryMuscleGroup,
      secondaryMuscles: secondaryMuscles ?? const [],
      equipment: equipment,
      movementPattern: movementPattern,
      isCustom: true,
    );
    createdCustomExercises.add(created);
    _exercises.add(created);
    return Success(created);
  }

  @override
  Future<Result<Exercise, Failure>> updateExerciseNotes({
    required String exerciseId,
    required String notes,
  }) async =>
      const Err(ServerFailure('Unsupported'));

  @override
  Future<Result<void, Failure>> deleteCustomExercise(String id) async =>
      const Success(null);
}

class _FakeTrainingRepository implements TrainingRepository {
  final List<TrainingPlan> plans = [];
  String? activePlanId;
  final List<WorkoutExercise> addedExercises = [];

  @override
  Future<Result<TrainingPlan, Failure>> createTrainingPlan({
    required String name,
    String? description,
    bool isActive = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final plan = TrainingPlan(
      id: 'plan-${plans.length + 1}',
      userId: 'u-1',
      name: name,
      description: description,
      isActive: isActive,
    );
    plans.add(plan);
    return Success(plan);
  }

  @override
  Future<Result<Workout, Failure>> addWorkoutToPlan({
    required String trainingPlanId,
    required String name,
    int? dayOfWeek,
    int sortOrder = 0,
    String? notes,
    int? estimatedDurationMinutes,
  }) async {
    return Success(
      Workout(
        id: 'workout-$sortOrder',
        trainingPlanId: trainingPlanId,
        name: name,
        dayOfWeek: dayOfWeek,
        sortOrder: sortOrder,
        notes: notes,
        estimatedDurationMinutes: estimatedDurationMinutes,
      ),
    );
  }

  @override
  Future<Result<WorkoutExercise, Failure>> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
    int sortOrder = 0,
    String? notes,
    List<SetTemplate>? initialSetTemplates,
  }) async {
    final we = WorkoutExercise(
      id: 'we-${addedExercises.length + 1}',
      workoutId: workoutId,
      exerciseId: exerciseId,
      sortOrder: sortOrder,
      notes: notes,
      setTemplates: initialSetTemplates ?? const [],
    );
    addedExercises.add(we);
    return Success(we);
  }

  @override
  Future<Result<TrainingPlan, Failure>> setActiveTrainingPlan(
    String planId,
  ) async {
    activePlanId = planId;
    final idx = plans.indexWhere((p) => p.id == planId);
    final updated = plans[idx].copyWith(isActive: true);
    plans[idx] = updated;
    return Success(updated);
  }

  @override
  Future<Result<TrainingPlan, Failure>> getTrainingPlanById(String id) async {
    final plan = plans.where((p) => p.id == id).first;
    return Success(plan);
  }

  @override
  Future<Result<List<TrainingPlan>, Failure>> getTrainingPlans() async =>
      Success(plans);

  @override
  Future<Result<TrainingPlan?, Failure>> getActiveTrainingPlan() async =>
      Success(plans.where((p) => p.isActive).firstOrNull);

  @override
  Future<Result<List<SetTemplate>, Failure>> configureSetTemplates({
    required String workoutExerciseId,
    required List<SetTemplate> setTemplates,
  }) async =>
      Success(setTemplates);

  @override
  Future<Result<void, Failure>> reorderWorkoutExercises({
    required String workoutId,
    required List<String> orderedWorkoutExerciseIds,
  }) async =>
      const Success(null);

  @override
  Future<Result<void, Failure>> reorderPlanWorkouts({
    required String trainingPlanId,
    required List<String> orderedWorkoutIds,
  }) async =>
      const Success(null);

  @override
  Future<Result<void, Failure>> deleteTrainingPlan(String planId) async =>
      const Success(null);

  @override
  Future<Result<void, Failure>> deleteWorkout(String workoutId) async =>
      const Success(null);

  @override
  Future<Result<void, Failure>> deleteWorkoutExercise(
    String workoutExerciseId,
  ) async =>
      const Success(null);
}

void main() {
  group('PlanPersisterService', () {
    test(
        'resolves by ID, falls back to case-insensitive name, and auto-creates missing custom exercise once across workouts',
        () async {
      final exerciseRepo = _FakeExerciseRepository(const [
        Exercise(
          id: 'global-bench',
          name: 'Supino reto com barra',
          primaryMuscleGroup: 'chest',
        ),
        Exercise(
          id: 'global-squat',
          name: 'Agachamento livre com barra',
          primaryMuscleGroup: 'legs',
        ),
      ]);
      final trainingRepo = _FakeTrainingRepository();
      final service = PlanPersisterService(
        trainingRepository: trainingRepo,
        exerciseRepository: exerciseRepo,
      );

      const draft = GeneratedTrainingPlan(
        planName: 'ABCD Personalizado',
        splitType: 'ABCD',
        description: 'Plano para irmão/amiga',
        workouts: [
          GeneratedWorkoutSpec(
            name: 'Treino A',
            exercises: [
              // 1. Exact ID match
              GeneratedExerciseSpec(
                exerciseId: 'global-bench',
                exerciseName: 'Supino reto com barra',
                setsCount: 4,
                targetRepsMin: 8,
                targetRepsMax: 10,
              ),
              // 2. Missing custom exercise -> auto-created
              GeneratedExerciseSpec(
                exerciseId: 'other-account-custom-uuid',
                exerciseName: 'Remada Cavalinho Especial',
                primaryMuscleGroup: 'back',
                setsCount: 3,
              ),
            ],
          ),
          GeneratedWorkoutSpec(
            name: 'Treino B',
            exercises: [
              // 3. Name match despite foreign ID
              GeneratedExerciseSpec(
                exerciseId: 'foreign-squat-uuid',
                exerciseName: 'agachamento livre com barra',
                setsCount: 4,
              ),
              // 4. Same custom exercise again -> reuses created custom-1
              GeneratedExerciseSpec(
                exerciseName: 'remada cavalinho especial',
                primaryMuscleGroup: 'back',
                setsCount: 3,
              ),
              // 5. Cardio exercise -> 1 duration set with 0 rest
              GeneratedExerciseSpec(
                exerciseName: 'Esteira / Cardio',
                isCardio: true,
                targetDurationMinutes: 25,
              ),
            ],
          ),
        ],
      );

      final result = await service.persistPlan(draft, activateImmediately: true);
      expect(result.isSuccess, isTrue);

      // Only 2 custom exercises created: 'Remada Cavalinho Especial' (reused in Treino B!)
      // and 'Esteira / Cardio'.
      expect(exerciseRepo.createdCustomExercises, hasLength(2));
      expect(
        exerciseRepo.createdCustomExercises.first.name,
        'Remada Cavalinho Especial',
      );

      expect(trainingRepo.addedExercises, hasLength(5));
      expect(trainingRepo.addedExercises[0].exerciseId, 'global-bench');
      expect(trainingRepo.addedExercises[0].setTemplates, hasLength(4));
      expect(trainingRepo.addedExercises[1].exerciseId, 'custom-1');
      expect(trainingRepo.addedExercises[2].exerciseId, 'global-squat');
      expect(trainingRepo.addedExercises[3].exerciseId, 'custom-1');

      final cardioWe = trainingRepo.addedExercises[4];
      expect(cardioWe.setTemplates, hasLength(1));
      expect(cardioWe.setTemplates.first.restSeconds, 0);
      expect(cardioWe.setTemplates.first.notes, '25 min');
      expect(trainingRepo.activePlanId, 'plan-1');
    });
  });
}
