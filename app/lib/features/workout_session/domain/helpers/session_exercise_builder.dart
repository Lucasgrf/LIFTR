import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/services/rest_duration_resolver.dart';

/// Builds initial [SessionExercise] items for a workout session, preserving
/// each exercise's exact prescribed set count, set types, rep range, RIR and rest.
List<SessionExercise> buildInitialSessionExercises(
  Workout workout, {
  int defaultRestSeconds = AppConstants.defaultRestSeconds,
}) {
  return workout.exercises.map((we) {
    final sortedTemplates = [...we.setTemplates]
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    final workingTemplates =
        sortedTemplates.where((s) => s.isWorkingSet).toList();
    final SetTemplate? primaryTemplate =
        workingTemplates.firstOrNull ?? sortedTemplates.firstOrNull;

    final bool isCardio = we.isCardio;

    final int targetSetsCount;
    if (isCardio) {
      targetSetsCount = sortedTemplates.isNotEmpty ? sortedTemplates.length : 1;
    } else if (workingTemplates.isNotEmpty) {
      targetSetsCount = workingTemplates.length;
    } else if (sortedTemplates.isNotEmpty) {
      targetSetsCount = sortedTemplates.length;
    } else {
      targetSetsCount = 3;
    }

    final targetRepsMin =
        primaryTemplate?.targetRepsMin ?? (isCardio ? 15 : 8);
    final targetRepsMax =
        primaryTemplate?.targetRepsMax ?? (isCardio ? 20 : 12);

    final int restSeconds = isCardio
        ? 0
        : RestDurationResolver.resolve(
            targetRepsMin: targetRepsMin,
            targetRepsMax: targetRepsMax,
            movementPattern: we.exercise?.movementPattern,
            primaryMuscleGroup: we.exercise?.primaryMuscleGroup,
            equipment: we.exercise?.equipment,
            isCardio: isCardio,
            explicitTemplateRestSeconds: primaryTemplate?.restSeconds,
          );

    return SessionExercise(
      id: '',
      sessionId: '',
      exerciseId: we.exerciseId,
      sortOrder: we.sortOrder,
      notes: we.notes,
      exercise: we.exercise,
      targetRestSeconds: restSeconds,
      targetSetsCount: targetSetsCount,
      targetRepsMin: targetRepsMin,
      targetRepsMax: targetRepsMax,
      targetRir: primaryTemplate?.targetRirMin ?? 2,
      prescribedSetTypes: sortedTemplates.map((t) => t.setType).toList(),
    );
  }).toList();
}
