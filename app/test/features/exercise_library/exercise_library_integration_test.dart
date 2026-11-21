import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/exercise_library/data/datasources/exercise_remote_datasource.dart';
import 'package:personal_fitness_os/features/exercise_library/data/models/exercise_model.dart';
import 'package:personal_fitness_os/features/exercise_library/data/repositories/exercise_repository_impl.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/create_custom_exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/get_exercise_by_id.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/get_exercises.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/search_exercises.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/update_exercise_notes.dart';

class MockExerciseRemoteDataSource extends Mock implements ExerciseRemoteDataSource {}

void main() {
  late MockExerciseRemoteDataSource mockDataSource;
  late ExerciseRepositoryImpl repository;
  late GetExercisesUseCase getExercisesUseCase;
  late SearchExercisesUseCase searchExercisesUseCase;
  late GetExerciseByIdUseCase getExerciseByIdUseCase;
  late CreateCustomExerciseUseCase createCustomExerciseUseCase;
  late UpdateExerciseNotesUseCase updateExerciseNotesUseCase;

  final tModelList = [
    const ExerciseModel(
      id: 'ex-1',
      name: 'Supino Reto com Barra',
      primaryMuscleGroup: 'chest',
      secondaryMuscles: ['triceps', 'anterior_deltoid'],
      equipment: 'barbell',
      movementPattern: 'horizontal_push',
      instructions: 'Deite e empurre.',
      isCustom: false,
    ),
    const ExerciseModel(
      id: 'ex-2',
      name: 'Desenvolvimento Militar',
      primaryMuscleGroup: 'anterior_deltoid',
      secondaryMuscles: ['triceps'],
      equipment: 'barbell',
      movementPattern: 'vertical_push',
      instructions: 'Empurre acima da cabeça.',
      isCustom: false,
    ),
    const ExerciseModel(
      id: 'ex-3',
      name: 'Remada Curvada',
      primaryMuscleGroup: 'back',
      secondaryMuscles: ['biceps'],
      equipment: 'barbell',
      movementPattern: 'horizontal_pull',
      instructions: 'Puxe até o abdômen.',
      isCustom: false,
    ),
  ];

  setUp(() {
    mockDataSource = MockExerciseRemoteDataSource();
    repository = ExerciseRepositoryImpl(mockDataSource);
    getExercisesUseCase = GetExercisesUseCase(repository);
    searchExercisesUseCase = SearchExercisesUseCase(repository);
    getExerciseByIdUseCase = GetExerciseByIdUseCase(repository);
    createCustomExerciseUseCase = CreateCustomExerciseUseCase(repository);
    updateExerciseNotesUseCase = UpdateExerciseNotesUseCase(repository);
  });

  group('Exercise Library End-to-End Integration Flow', () {
    test('should fetch, filter by query, filter by muscle and inspect details', () async {
      // 1. Fetch all exercises
      when(() => mockDataSource.fetchExercises()).thenAnswer((_) async => tModelList);

      final allResult = await getExercisesUseCase.execute();
      expect(allResult.isSuccess, isTrue);
      final allExercises = (allResult as Success<List<Exercise>, Failure>).value;
      expect(allExercises.length, 3);

      // 2. Search query "supino"
      final searchResult = await searchExercisesUseCase.execute(query: 'supino');
      expect(searchResult.isSuccess, isTrue);
      final searchList = (searchResult as Success<List<Exercise>, Failure>).value;
      expect(searchList.length, 1);
      expect(searchList.first.name, 'Supino Reto com Barra');

      // 3. Filter by muscle "chest"
      final muscleFilterResult = await searchExercisesUseCase.execute(muscleGroup: 'chest');
      expect(muscleFilterResult.isSuccess, isTrue);
      final muscleList = (muscleFilterResult as Success<List<Exercise>, Failure>).value;
      expect(muscleList.length, 1);
      expect(muscleList.first.id, 'ex-1');

      // 4. Inspect details of ex-1
      when(() => mockDataSource.fetchExerciseById('ex-1')).thenAnswer((_) async => tModelList[0]);
      final detailResult = await getExerciseByIdUseCase.execute('ex-1');
      expect(detailResult.isSuccess, isTrue);
      final detail = (detailResult as Success<Exercise, Failure>).value;
      expect(detail.instructions, 'Deite e empurre.');

      // 5. Update personal notes
      final updatedModel = tModelList[0].toDomain().copyWith(personalNotes: 'Pegada média');
      when(() => mockDataSource.updateExerciseNotes('ex-1', 'Pegada média'))
          .thenAnswer((_) async => ExerciseModel.fromDomain(updatedModel));

      final updateResult = await updateExerciseNotesUseCase.execute(
        exerciseId: 'ex-1',
        notes: 'Pegada média',
      );
      expect(updateResult.isSuccess, isTrue);
      expect((updateResult as Success<Exercise, Failure>).value.personalNotes, 'Pegada média');
    });

    test('should create custom exercise and verify repository persistence flow', () async {
      const customModel = ExerciseModel(
        id: 'custom-99',
        name: 'Elevação Lateral no Banco Inclinado',
        primaryMuscleGroup: 'lateral_deltoid',
        equipment: 'dumbbell',
        isCustom: true,
        userId: 'user-1',
      );

      when(() => mockDataSource.insertCustomExercise(any()))
          .thenAnswer((_) async => customModel);

      final createResult = await createCustomExerciseUseCase.execute(
        name: 'Elevação Lateral no Banco Inclinado',
        primaryMuscleGroup: 'lateral_deltoid',
        equipment: 'dumbbell',
      );

      expect(createResult.isSuccess, isTrue);
      final created = (createResult as Success<Exercise, Failure>).value;
      expect(created.id, 'custom-99');
      expect(created.isCustom, isTrue);
      expect(created.primaryMuscleGroup, 'lateral_deltoid');
    });
  });
}
