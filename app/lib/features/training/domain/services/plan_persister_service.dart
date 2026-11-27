import 'package:personal_fitness_os/core/constants/app_constants.dart';
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
import 'package:personal_fitness_os/features/workout_session/domain/services/rest_duration_resolver.dart';

/// Persists a [GeneratedTrainingPlan] (from Gemini AI or imported share code)
/// into the user's account, resolving existing catalog exercises and
/// auto-creating missing custom exercises without duplication.
class PlanPersisterService {
  const PlanPersisterService({
    required TrainingRepository trainingRepository,
    required ExerciseRepository exerciseRepository,
  })  : _trainingRepository = trainingRepository,
        _exerciseRepository = exerciseRepository;

  final TrainingRepository _trainingRepository;
  final ExerciseRepository _exerciseRepository;

  static String _normalizeName(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<Result<TrainingPlan, Failure>> persistPlan(
    GeneratedTrainingPlan draft, {
    bool activateImmediately = true,
  }) async {
    if (draft.workouts.isEmpty) {
      return const Err(
        ValidationFailure('O programa precisa ter ao menos uma sessão de treino.'),
      );
    }

    // 1. Load user's visible exercise catalog (global + user's custom exercises).
    final byId = <String, Exercise>{};
    final byLowerName = <String, Exercise>{};

    final exercisesResult = await _exerciseRepository.getExercises();
    exercisesResult.fold(
      (list) {
        for (final ex in list) {
          byId[ex.id.trim()] = ex;
          byLowerName[_normalizeName(ex.name)] = ex;
        }
      },
      (_) {
        // Proceed with empty cache if catalog fetch fails; missing items will be created.
      },
    );

    // 2. Create the training plan (inactive first so setActiveTrainingPlan
    // cleanly deactivates any previously active plan).
    final planResult = await _trainingRepository.createTrainingPlan(
      name: draft.planName.trim().isEmpty
          ? 'Programa LIFTR'
          : draft.planName.trim(),
      description: draft.description?.trim(),
      isActive: false,
      startDate: DateTime.now(),
    );

    TrainingPlan? createdPlan;
    Failure? planFailure;
    planResult.fold(
      (p) => createdPlan = p,
      (f) => planFailure = f,
    );
    if (planFailure != null || createdPlan == null) {
      return Err(
        planFailure ?? const UnexpectedFailure('Falha ao criar programa.'),
      );
    }

    final persistedWorkouts = <Workout>[];

    // 3. Persist workouts and their exercises + set templates in order.
    for (int wIdx = 0; wIdx < draft.workouts.length; wIdx++) {
      final wSpec = draft.workouts[wIdx];
      final workoutResult = await _trainingRepository.addWorkoutToPlan(
        trainingPlanId: createdPlan!.id,
        name: wSpec.name.trim().isEmpty
            ? 'Treino ${wIdx + 1}'
            : wSpec.name.trim(),
        dayOfWeek: wSpec.dayOfWeek,
        sortOrder: wIdx,
        notes: wSpec.notes,
        estimatedDurationMinutes: wSpec.estimatedDurationMinutes,
      );

      Workout? createdWorkout;
      Failure? workoutFailure;
      workoutResult.fold(
        (w) => createdWorkout = w,
        (f) => workoutFailure = f,
      );
      if (workoutFailure != null || createdWorkout == null) {
        return Err(
          workoutFailure ??
              const UnexpectedFailure('Falha ao criar sessão do programa.'),
        );
      }

      final persistedExercises = <WorkoutExercise>[];

      for (int eIdx = 0; eIdx < wSpec.exercises.length; eIdx++) {
        final exSpec = wSpec.exercises[eIdx];
        final resolvedResult = await _resolveOrCreateExercise(
          exSpec,
          byId: byId,
          byLowerName: byLowerName,
        );

        Exercise? resolvedExercise;
        Failure? resolveFailure;
        resolvedResult.fold(
          (ex) => resolvedExercise = ex,
          (f) => resolveFailure = f,
        );
        if (resolveFailure != null || resolvedExercise == null) {
          return Err(
            resolveFailure ??
                UnexpectedFailure(
                  'Falha ao preparar o exercício "${exSpec.exerciseName}".',
                ),
          );
        }

        final templates = _buildSetTemplates(exSpec);
        final weResult = await _trainingRepository.addExerciseToWorkout(
          workoutId: createdWorkout!.id,
          exerciseId: resolvedExercise!.id,
          sortOrder: eIdx,
          notes: exSpec.notes,
          initialSetTemplates: templates,
        );

        WorkoutExercise? createdWe;
        Failure? weFailure;
        weResult.fold(
          (we) => createdWe = we,
          (f) => weFailure = f,
        );
        if (weFailure != null || createdWe == null) {
          return Err(
            weFailure ??
                UnexpectedFailure(
                  'Falha ao adicionar "${exSpec.exerciseName}" ao treino.',
                ),
          );
        }

        persistedExercises.add(
          createdWe!.copyWith(
            exercise: createdWe!.exercise ?? resolvedExercise,
          ),
        );
      }

      persistedWorkouts.add(
        createdWorkout!.copyWith(exercises: persistedExercises),
      );
    }

    // 4. Activate the plan if requested (deactivates previous plans).
    var finalPlan = createdPlan!.copyWith(
      isActive: activateImmediately,
      workouts: persistedWorkouts,
    );

    if (activateImmediately) {
      final activateResult =
          await _trainingRepository.setActiveTrainingPlan(createdPlan!.id);
      activateResult.fold(
        (activated) {
          finalPlan = activated.workouts.isNotEmpty
              ? activated
              : activated.copyWith(workouts: persistedWorkouts);
        },
        (_) {},
      );
    }

    // 5. Attempt a fresh reload so all nested DB IDs are authoritative.
    final reloadedResult =
        await _trainingRepository.getTrainingPlanById(createdPlan!.id);
    return reloadedResult.fold(
      (reloaded) => Success(
        reloaded.workouts.isNotEmpty
            ? reloaded
            : reloaded.copyWith(workouts: persistedWorkouts),
      ),
      (_) => Success(finalPlan),
    );
  }

  Future<Result<Exercise, Failure>> _resolveOrCreateExercise(
    GeneratedExerciseSpec spec, {
    required Map<String, Exercise> byId,
    required Map<String, Exercise> byLowerName,
  }) async {
    final candidateId = spec.exerciseId?.trim();
    if (candidateId != null &&
        candidateId.isNotEmpty &&
        byId.containsKey(candidateId)) {
      return Success(byId[candidateId]!);
    }

    final normName = _normalizeName(spec.exerciseName);
    if (normName.isNotEmpty && byLowerName.containsKey(normName)) {
      return Success(byLowerName[normName]!);
    }

    // Exercise does not exist on this user's account (e.g. brother's custom
    // exercise or seed not yet applied) -> create custom exercise automatically.
    final primaryMuscle = (spec.primaryMuscleGroup != null &&
            spec.primaryMuscleGroup!.trim().isNotEmpty)
        ? spec.primaryMuscleGroup!.trim()
        : (spec.isCardio ? 'cardio' : 'full_body');

    final movementPattern = (spec.movementPattern != null &&
            spec.movementPattern!.trim().isNotEmpty)
        ? spec.movementPattern!.trim()
        : (spec.isCardio ? 'cardio' : 'isolation');

    final createResult = await _exerciseRepository.createCustomExercise(
      name: spec.exerciseName.trim().isEmpty
          ? 'Exercício Personalizado'
          : spec.exerciseName.trim(),
      primaryMuscleGroup: primaryMuscle,
      equipment: spec.equipment,
      movementPattern: movementPattern,
    );

    return createResult.fold(
      (created) {
        byId[created.id.trim()] = created;
        byLowerName[_normalizeName(created.name)] = created;
        return Success(created);
      },
      (failure) => Err(failure),
    );
  }

  List<SetTemplate> _buildSetTemplates(GeneratedExerciseSpec spec) {
    if (spec.exactSets != null && spec.exactSets!.isNotEmpty) {
      return List.generate(spec.exactSets!.length, (idx) {
        final s = spec.exactSets![idx];
        return SetTemplate(
          id: 'tpl-${idx + 1}',
          workoutExerciseId: '',
          setNumber: idx + 1,
          setType: s.setType,
          targetRepsMin: s.targetRepsMin,
          targetRepsMax: s.targetRepsMax,
          targetRirMin: s.targetRirMin,
          targetRirMax: s.targetRirMax,
          targetWeight: s.targetWeight,
          restSeconds: s.restSeconds,
          notes: s.notes,
        );
      });
    }

    if (spec.isCardio) {
      final durationMin = (spec.targetDurationMinutes ?? 15).clamp(5, 180);
      return [
        SetTemplate(
          id: 'tpl-1',
          workoutExerciseId: '',
          setNumber: 1,
          setType: SetType.working,
          restSeconds: 0,
          notes: '$durationMin min',
        ),
      ];
    }

    final count = spec.setsCount.clamp(1, 10);
    final repsMin = spec.targetRepsMin ?? 8;
    final repsMax = spec.targetRepsMax ?? (repsMin < 12 ? 12 : repsMin);
    final rirMin = spec.targetRirMin ?? 1;
    final rirMax = spec.targetRirMax ?? 2;
    final rest = RestDurationResolver.resolve(
      targetRepsMin: repsMin,
      targetRepsMax: repsMax,
      movementPattern: spec.movementPattern,
      primaryMuscleGroup: spec.primaryMuscleGroup,
      equipment: spec.equipment,
      explicitTemplateRestSeconds: spec.restSeconds > 0 ? spec.restSeconds : null,
    );

    return List.generate(
      count,
      (idx) => SetTemplate(
        id: 'tpl-${idx + 1}',
        workoutExerciseId: '',
        setNumber: idx + 1,
        setType: SetType.working,
        targetRepsMin: repsMin,
        targetRepsMax: repsMax,
        targetRirMin: rirMin,
        targetRirMax: rirMax,
        restSeconds: rest,
      ),
    );
  }
}
