import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';

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

    final int restSeconds;
    if (isCardio) {
      restSeconds = 0;
    } else if (primaryTemplate != null && primaryTemplate.restSeconds > 0) {
      restSeconds = primaryTemplate.restSeconds;
    } else {
      restSeconds = defaultRestSeconds;
    }

    return SessionExercise(
      id: '',
      sessionId: '',
      exerciseId: we.exerciseId,
      sortOrder: we.sortOrder,
      notes: we.notes,
      exercise: we.exercise,
      targetRestSeconds: restSeconds,
      targetSetsCount: targetSetsCount,
      targetRepsMin: primaryTemplate?.targetRepsMin ?? (isCardio ? 15 : 8),
      targetRepsMax: primaryTemplate?.targetRepsMax ?? (isCardio ? 20 : 12),
      targetRir: primaryTemplate?.targetRirMin ?? 2,
      prescribedSetTypes: sortedTemplates.map((t) => t.setType).toList(),
    );
  }).toList();
}
