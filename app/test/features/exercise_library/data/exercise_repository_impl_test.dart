import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/exercise_library/data/datasources/exercise_remote_datasource.dart';
import 'package:personal_fitness_os/features/exercise_library/data/models/exercise_model.dart';
import 'package:personal_fitness_os/features/exercise_library/data/repositories/exercise_repository_impl.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockExerciseRemoteDataSource extends Mock
    implements ExerciseRemoteDataSource {}

void main() {
  late MockExerciseRemoteDataSource mockRemoteDataSource;
  late ExerciseRepositoryImpl repository;

  const tModel = ExerciseModel(
    id: 'ex-1',
    name: 'Agachamento com Barra',
    primaryMuscleGroup: 'quadriceps',
    secondaryMuscles: ['glutes', 'hamstrings'],
    equipment: 'barbell',
    movementPattern: 'squat',
    instructions: 'Agache até quebrar o paralelo.',
    isCustom: false,
  );

  setUp(() {
    mockRemoteDataSource = MockExerciseRemoteDataSource();
    repository = ExerciseRepositoryImpl(mockRemoteDataSource);
  });

  group('getExercises', () {
    test('should return list of Exercise domain entities on success', () async {
      when(() => mockRemoteDataSource.fetchExercises())
          .thenAnswer((_) async => [tModel]);

      final result = await repository.getExercises();

      expect(result.isSuccess, isTrue);
      final list = (result as Success<List<Exercise>, Failure>).value;
      expect(list.length, 1);
      expect(list.first.id, 'ex-1');
      expect(list.first.name, 'Agachamento com Barra');
      verify(() => mockRemoteDataSource.fetchExercises()).called(1);
    });

    test('should return ServerFailure when PostgrestException is thrown', () async {
      when(() => mockRemoteDataSource.fetchExercises()).thenThrow(
        const PostgrestException(message: 'Database query timeout'),
      );

      final result = await repository.getExercises();

      expect(result.isError, isTrue);
      final failure = (result as Err<List<Exercise>, Failure>).failure;
      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Database query timeout');
    });

    test('should return NetworkFailure when SocketException is thrown', () async {
      when(() => mockRemoteDataSource.fetchExercises()).thenThrow(
        const SocketException('Failed host lookup'),
      );

      final result = await repository.getExercises();

      expect(result.isError, isTrue);
      final failure = (result as Err<List<Exercise>, Failure>).failure;
      expect(failure, isA<NetworkFailure>());
    });
  });

  group('getExerciseById', () {
    test('should return Exercise entity when found', () async {
      when(() => mockRemoteDataSource.fetchExerciseById('ex-1'))
          .thenAnswer((_) async => tModel);

      final result = await repository.getExerciseById('ex-1');

      expect(result.isSuccess, isTrue);
      expect((result as Success<Exercise, Failure>).value.id, 'ex-1');
    });

    test('should return ServerFailure on PostgrestException', () async {
      when(() => mockRemoteDataSource.fetchExerciseById('invalid'))
          .thenThrow(const PostgrestException(message: 'Row not found'));

      final result = await repository.getExerciseById('invalid');

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ServerFailure>());
    });
  });

  group('createCustomExercise', () {
    test('should insert and return created custom Exercise', () async {
      const customModel = ExerciseModel(
        id: 'custom-1',
        name: 'Crucifixo Invertido',
        primaryMuscleGroup: 'posterior_deltoid',
        isCustom: true,
        userId: 'user-abc',
      );

      when(() => mockRemoteDataSource.insertCustomExercise(any()))
          .thenAnswer((_) async => customModel);

      final result = await repository.createCustomExercise(
        name: 'Crucifixo Invertido',
        primaryMuscleGroup: 'posterior_deltoid',
      );

      expect(result.isSuccess, isTrue);
      final created = (result as Success<Exercise, Failure>).value;
      expect(created.isCustom, isTrue);
      expect(created.name, 'Crucifixo Invertido');
    });
  });

  group('updateExerciseNotes', () {
    test('should update notes and return updated entity', () async {
      const updatedModel = ExerciseModel(
        id: 'ex-1',
        name: 'Agachamento com Barra',
        primaryMuscleGroup: 'quadriceps',
        personalNotes: 'Aquecer bem os joelhos antes',
      );

      when(() => mockRemoteDataSource.updateExerciseNotes('ex-1', 'Aquecer bem os joelhos antes'))
          .thenAnswer((_) async => updatedModel);

      final result = await repository.updateExerciseNotes(
        exerciseId: 'ex-1',
        notes: 'Aquecer bem os joelhos antes',
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success<Exercise, Failure>).value.personalNotes, 'Aquecer bem os joelhos antes');
    });
  });
}
