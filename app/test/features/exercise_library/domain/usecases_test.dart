import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/repositories/exercise_repository.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/create_custom_exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/get_exercise_by_id.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/get_exercises.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/search_exercises.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/update_exercise_notes.dart';

class MockExerciseRepository extends Mock implements ExerciseRepository {}

void main() {
  late MockExerciseRepository mockRepository;
  late GetExercisesUseCase getExercisesUseCase;
  late SearchExercisesUseCase searchExercisesUseCase;
  late GetExerciseByIdUseCase getExerciseByIdUseCase;
  late CreateCustomExerciseUseCase createCustomExerciseUseCase;
  late UpdateExerciseNotesUseCase updateExerciseNotesUseCase;

  const tExercise1 = Exercise(
    id: '1',
    name: 'Supino Reto com Barra',
    primaryMuscleGroup: 'chest',
    secondaryMuscles: ['triceps', 'anterior_deltoid'],
    equipment: 'barbell',
    movementPattern: 'horizontal_push',
    instructions: 'Deite no banco e empurre a barra.',
    isCustom: false,
  );

  const tExercise2 = Exercise(
    id: '2',
    name: 'Puxada na Frente',
    primaryMuscleGroup: 'back',
    secondaryMuscles: ['biceps'],
    equipment: 'cable',
    movementPattern: 'vertical_pull',
    instructions: 'Puxe a barra até o queixo.',
    isCustom: false,
  );

  final tExercises = [tExercise1, tExercise2];

  setUp(() {
    mockRepository = MockExerciseRepository();
    getExercisesUseCase = GetExercisesUseCase(mockRepository);
    searchExercisesUseCase = SearchExercisesUseCase(mockRepository);
    getExerciseByIdUseCase = GetExerciseByIdUseCase(mockRepository);
    createCustomExerciseUseCase = CreateCustomExerciseUseCase(mockRepository);
    updateExerciseNotesUseCase = UpdateExerciseNotesUseCase(mockRepository);
  });

  group('GetExercisesUseCase', () {
    test('should return list of exercises on repository success', () async {
      when(() => mockRepository.getExercises())
          .thenAnswer((_) async => Success(tExercises));

      final result = await getExercisesUseCase.execute();

      expect(result, isA<Success<List<Exercise>, Failure>>());
      expect((result as Success).value, tExercises);
      verify(() => mockRepository.getExercises()).called(1);
    });

    test('should return Failure on repository failure', () async {
      when(() => mockRepository.getExercises())
          .thenAnswer((_) async => const Err(ServerFailure('Database error')));

      final result = await getExercisesUseCase.execute();

      expect(result, isA<Err<List<Exercise>, Failure>>());
      expect((result as Err).failure, isA<ServerFailure>());
    });
  });

  group('SearchExercisesUseCase', () {
    setUp(() {
      when(() => mockRepository.getExercises())
          .thenAnswer((_) async => Success(tExercises));
    });

    test('should return all exercises when query and filters are empty', () async {
      final result = await searchExercisesUseCase.execute();

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.length, 2);
    });

    test('should filter exercises by name case-insensitive', () async {
      final result = await searchExercisesUseCase.execute(query: 'supino');

      expect(result.isSuccess, isTrue);
      final list = (result as Success).value;
      expect(list.length, 1);
      expect(list.first.name, 'Supino Reto com Barra');
    });

    test('should filter exercises by muscleGroup', () async {
      final result = await searchExercisesUseCase.execute(muscleGroup: 'back');

      expect(result.isSuccess, isTrue);
      final list = (result as Success).value;
      expect(list.length, 1);
      expect(list.first.name, 'Puxada na Frente');
    });

    test('should filter exercises by equipment', () async {
      final result = await searchExercisesUseCase.execute(equipment: 'barbell');

      expect(result.isSuccess, isTrue);
      final list = (result as Success).value;
      expect(list.length, 1);
      expect(list.first.name, 'Supino Reto com Barra');
    });

    test('should return empty list when no exercise matches query', () async {
      final result = await searchExercisesUseCase.execute(query: 'inexistente');

      expect(result.isSuccess, isTrue);
      expect((result as Success).value, isEmpty);
    });
  });

  group('GetExerciseByIdUseCase', () {
    test('should return exercise when valid ID is provided', () async {
      when(() => mockRepository.getExerciseById('1'))
          .thenAnswer((_) async => Success(tExercise1));

      final result = await getExerciseByIdUseCase.execute('1');

      expect(result.isSuccess, isTrue);
      expect((result as Success).value, tExercise1);
    });

    test('should return ValidationFailure when empty ID is provided', () async {
      final result = await getExerciseByIdUseCase.execute('   ');

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
      verifyNever(() => mockRepository.getExerciseById(any()));
    });
  });

  group('CreateCustomExerciseUseCase', () {
    test('should create custom exercise on valid input', () async {
      final customExercise = tExercise1.copyWith(isCustom: true, userId: 'user-123');

      when(() => mockRepository.createCustomExercise(
            name: any(named: 'name'),
            primaryMuscleGroup: any(named: 'primaryMuscleGroup'),
            secondaryMuscles: any(named: 'secondaryMuscles'),
            equipment: any(named: 'equipment'),
            movementPattern: any(named: 'movementPattern'),
            instructions: any(named: 'instructions'),
            commonMistakes: any(named: 'commonMistakes'),
            videoUrl: any(named: 'videoUrl'),
            personalNotes: any(named: 'personalNotes'),
          )).thenAnswer((_) async => Success(customExercise));

      final result = await createCustomExerciseUseCase.execute(
        name: 'Supino Reto com Barra',
        primaryMuscleGroup: 'chest',
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.isCustom, isTrue);
    });

    test('should return ValidationFailure when name is empty', () async {
      final result = await createCustomExerciseUseCase.execute(
        name: '',
        primaryMuscleGroup: 'chest',
      );

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });

  group('UpdateExerciseNotesUseCase', () {
    test('should update notes on valid input', () async {
      final updated = tExercise1.copyWith(personalNotes: 'Banco no pino 3');

      when(() => mockRepository.updateExerciseNotes(
            exerciseId: '1',
            notes: 'Banco no pino 3',
          )).thenAnswer((_) async => Success(updated));

      final result = await updateExerciseNotesUseCase.execute(
        exerciseId: '1',
        notes: 'Banco no pino 3',
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.personalNotes, 'Banco no pino 3');
    });

    test('should return ValidationFailure when exerciseId is empty', () async {
      final result = await updateExerciseNotesUseCase.execute(
        exerciseId: '',
        notes: 'Alguma nota',
      );

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });
}
