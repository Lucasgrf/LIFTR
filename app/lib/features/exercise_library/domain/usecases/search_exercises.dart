import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/repositories/exercise_repository.dart';

/// Use case for filtering and searching exercises by query, muscle group, and equipment.
class SearchExercisesUseCase {
  const SearchExercisesUseCase(this._repository);

  final ExerciseRepository _repository;

  Future<Result<List<Exercise>, Failure>> execute({
    String query = '',
    String? muscleGroup,
    String? equipment,
  }) async {
    final result = await _repository.getExercises();

    return result.map((exercises) {
      return exercises.where((exercise) {
        // Text query filter (case-insensitive)
        if (query.trim().isNotEmpty) {
          final normalizedQuery = _normalize(query);
          final matchesName = _normalize(exercise.name).contains(normalizedQuery);
          final matchesPrimary = _normalize(exercise.primaryMuscleGroup).contains(normalizedQuery);
          final matchesSecondary = exercise.secondaryMuscles.any(
            (m) => _normalize(m).contains(normalizedQuery),
          );
          final matchesEquipment = exercise.equipment != null &&
              _normalize(exercise.equipment!).contains(normalizedQuery);

          if (!matchesName && !matchesPrimary && !matchesSecondary && !matchesEquipment) {
            return false;
          }
        }

        // Muscle group filter
        if (muscleGroup != null && muscleGroup.isNotEmpty && muscleGroup.toLowerCase() != 'all') {
          final normalizedFilterMuscle = muscleGroup.toLowerCase();
          final matchesPrimary = exercise.primaryMuscleGroup.toLowerCase() == normalizedFilterMuscle;
          final matchesSecondary = exercise.secondaryMuscles.any(
            (m) => m.toLowerCase() == normalizedFilterMuscle,
          );

          if (!matchesPrimary && !matchesSecondary) {
            return false;
          }
        }

        // Equipment filter
        if (equipment != null && equipment.isNotEmpty && equipment.toLowerCase() != 'all') {
          if (exercise.equipment?.toLowerCase() != equipment.toLowerCase()) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  String _normalize(String input) {
    return input.toLowerCase().trim();
  }
}
