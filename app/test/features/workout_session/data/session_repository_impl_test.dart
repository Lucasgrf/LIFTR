import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_remote_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/logged_set_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/workout_session_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/repositories/session_repository_impl.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSessionRemoteDataSource extends Mock
    implements SessionRemoteDataSource {}

void main() {
  late MockSessionRemoteDataSource mockDataSource;
  late SessionRepositoryImpl repository;

  final tSessionModel = WorkoutSessionModel(
    id: 'session-1',
    userId: 'user-1',
    startedAt: DateTime(2026, 8, 22, 10, 0),
    status: 'in_progress',
  );

  const tLoggedSetModel = LoggedSetModel(
    id: 'set-1',
    sessionExerciseId: 'se-1',
    setNumber: 1,
    setType: 'working',
    weightKg: 100.0,
    repsCompleted: 8,
  );

  setUp(() {
    mockDataSource = MockSessionRemoteDataSource();
    repository = SessionRepositoryImpl(mockDataSource);
  });

  group('startSession', () {
    test('should start and return WorkoutSession entity', () async {
      when(() => mockDataSource.insertSession(any()))
          .thenAnswer((_) async => tSessionModel);

      final result = await repository.startSession();

      expect(result.isSuccess, isTrue);
      expect((result as Success<WorkoutSession, Failure>).value.id, 'session-1');
    });

    test('should return ServerFailure on PostgrestException', () async {
      when(() => mockDataSource.insertSession(any())).thenThrow(
        const PostgrestException(message: 'Insert session failed'),
      );

      final result = await repository.startSession();

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ServerFailure>());
    });
  });

  group('getActiveSession', () {
    test('should return active session when in progress', () async {
      when(() => mockDataSource.fetchActiveSession())
          .thenAnswer((_) async => tSessionModel);

      final result = await repository.getActiveSession();

      expect(result.isSuccess, isTrue);
      expect((result as Success<WorkoutSession?, Failure>).value?.isInProgress, isTrue);
    });

    test('should return null when no session is in progress', () async {
      when(() => mockDataSource.fetchActiveSession())
          .thenAnswer((_) async => null);

      final result = await repository.getActiveSession();

      expect(result.isSuccess, isTrue);
      expect((result as Success<WorkoutSession?, Failure>).value, isNull);
    });
  });

  group('logSet', () {
    test('should insert set and return LoggedSet entity', () async {
      when(() => mockDataSource.insertLoggedSet(any()))
          .thenAnswer((_) async => tLoggedSetModel);

      final result = await repository.logSet(
        sessionExerciseId: 'se-1',
        setNumber: 1,
        weightKg: 100.0,
        repsCompleted: 8,
      );

      expect(result.isSuccess, isTrue);
      final set = (result as Success<LoggedSet, Failure>).value;
      expect(set.weightKg, 100.0);
      expect(set.repsCompleted, 8);
    });
  });

  group('finishSession', () {
    test('should complete session on success', () async {
      final completedModel = tSessionModel.copyWith(
        status: 'completed',
        durationSeconds: 3600,
      );

      when(() => mockDataSource.updateSession('session-1', any()))
          .thenAnswer((_) async => completedModel);

      final result = await repository.finishSession(
        sessionId: 'session-1',
        durationSeconds: 3600,
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success<WorkoutSession, Failure>).value.isCompleted, isTrue);
    });
  });
}
