import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/progression/data/datasources/progression_remote_datasource.dart';
import 'package:personal_fitness_os/features/progression/data/repositories/progression_repository_impl.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockProgressionRemoteDataSource extends Mock
    implements ProgressionRemoteDataSource {}

void main() {
  late MockProgressionRemoteDataSource mockDataSource;
  late ProgressionRepositoryImpl repository;

  final tHistory = ExercisePerformanceHistory(
    exerciseId: 'ex-1',
    workoutSessionId: 'ws-1',
    workoutName: 'Treino A',
    date: DateTime(2026, 8, 20),
    loggedSets: const [],
  );

  setUp(() {
    mockDataSource = MockProgressionRemoteDataSource();
    repository = ProgressionRepositoryImpl(mockDataSource);
  });

  group('getLastExercisePerformance', () {
    test('should return ExercisePerformanceHistory on success', () async {
      when(() => mockDataSource.fetchLastExercisePerformance('ex-1'))
          .thenAnswer((_) async => tHistory);

      final result = await repository.getLastExercisePerformance('ex-1');

      expect(result.isSuccess, isTrue);
      final data = (result as Success<ExercisePerformanceHistory?, Failure>).value;
      expect(data?.exerciseId, 'ex-1');
      expect(data?.workoutName, 'Treino A');
    });

    test('should return AuthFailure on AuthException', () async {
      when(() => mockDataSource.fetchLastExercisePerformance('ex-1'))
          .thenThrow(const AuthException('Usuário não autenticado.'));

      final result = await repository.getLastExercisePerformance('ex-1');

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<AuthFailure>());
    });

    test('should return ServerFailure on PostgrestException', () async {
      when(() => mockDataSource.fetchLastExercisePerformance('ex-1'))
          .thenThrow(const PostgrestException(message: 'Query timeout'));

      final result = await repository.getLastExercisePerformance('ex-1');

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ServerFailure>());
    });
  });

  group('getRecentExercisePerformances', () {
    test('should return list of recent ExercisePerformanceHistory on success', () async {
      when(() => mockDataSource.fetchRecentExercisePerformances('ex-1', limit: 2))
          .thenAnswer((_) async => [tHistory]);

      final result = await repository.getRecentExercisePerformances('ex-1', limit: 2);

      expect(result.isSuccess, isTrue);
      final data =
          (result as Success<List<ExercisePerformanceHistory>, Failure>).value;
      expect(data, hasLength(1));
      expect(data.first.exerciseId, 'ex-1');
    });

    test('should return ServerFailure on PostgrestException', () async {
      when(() => mockDataSource.fetchRecentExercisePerformances('ex-1', limit: 2))
          .thenThrow(const PostgrestException(message: 'Query timeout'));

      final result = await repository.getRecentExercisePerformances('ex-1', limit: 2);

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ServerFailure>());
    });
  });
}
