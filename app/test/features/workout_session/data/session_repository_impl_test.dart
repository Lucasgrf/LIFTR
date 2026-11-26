import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_local_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_remote_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/logged_set_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/session_exercise_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/workout_session_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/repositories/session_repository_impl.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  group('swapSessionExercise', () {
    test('should update session exercise and return updated entity', () async {
      const updatedModel = SessionExerciseModel(
        id: 'se-1',
        sessionId: 'session-1',
        exerciseId: 'ex-2',
        replacedExerciseId: 'ex-1',
      );

      when(() => mockDataSource.updateSessionExercise('se-1', any()))
          .thenAnswer((_) async => updatedModel);

      final result = await repository.swapSessionExercise(
        sessionExerciseId: 'se-1',
        newExerciseId: 'ex-2',
        replacedExerciseId: 'ex-1',
      );

      expect(result.isSuccess, isTrue);
      final entity = (result as Success<SessionExercise, Failure>).value;
      expect(entity.exerciseId, 'ex-2');
      expect(entity.replacedExerciseId, 'ex-1');
    });

    test('should return ServerFailure when updateSessionExercise throws PostgrestException',
        () async {
      when(() => mockDataSource.updateSessionExercise('se-1', any())).thenThrow(
        const PostgrestException(message: 'Update failed'),
      );

      final result = await repository.swapSessionExercise(
        sessionExerciseId: 'se-1',
        newExerciseId: 'ex-2',
        replacedExerciseId: 'ex-1',
      );

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ServerFailure>());
    });
  });

  group('restoreLoggedSet', () {
    final originalDropSet = LoggedSet(
      id: 'set-drop-1',
      sessionExerciseId: 'se-1',
      setNumber: 2,
      setType: SetType.dropSet,
      weightKg: 80.0,
      repsCompleted: 10,
      rirActual: 1,
      rpeActual: 8.5,
      restSecondsActual: 120,
      executionQuality: ExecutionQuality.excellent,
      notes: 'drop final limpo',
      dropSets: const [
        DropSetEntry(weightKg: 60.0, repsCompleted: 8),
        DropSetEntry(weightKg: 45.0, repsCompleted: 10),
      ],
      completedAt: DateTime(2026, 11, 26, 10, 15, 30),
    );

    test(
        'online restore preserves original id, completedAt, RPE/RIR, setType and dropSets',
        () async {
      late Map<String, dynamic> capturedPayload;
      when(() => mockDataSource.insertLoggedSet(any())).thenAnswer((inv) async {
        capturedPayload = Map<String, dynamic>.from(
          inv.positionalArguments.first as Map,
        );
        return LoggedSetModel.fromDomain(originalDropSet);
      });

      final result = await repository.restoreLoggedSet(originalDropSet);

      expect(result.isSuccess, isTrue);
      final restored = (result as Success<LoggedSet, Failure>).value;
      expect(restored.id, 'set-drop-1');
      expect(restored.completedAt, DateTime(2026, 11, 26, 10, 15, 30));
      expect(restored.rpeActual, 8.5);
      expect(restored.rirActual, 1);
      expect(restored.setType, SetType.dropSet);
      expect(restored.dropSets, originalDropSet.dropSets);

      expect(capturedPayload['id'], 'set-drop-1');
      expect(
        capturedPayload['completed_at'],
        DateTime(2026, 11, 26, 10, 15, 30).toIso8601String(),
      );
      expect(capturedPayload['rpe_actual'], 8.5);
      expect(capturedPayload['rir_actual'], 1);
      expect(capturedPayload['set_type'], 'drop_set');
      expect(capturedPayload['rest_seconds_actual'], 120);
      expect(capturedPayload['execution_quality'], 'excellent');
      expect(capturedPayload['notes'], 'drop final limpo');
      expect(capturedPayload['drop_sets'], [
        {'weight_kg': 60.0, 'reps_completed': 8},
        {'weight_kg': 45.0, 'reps_completed': 10},
      ]);
    });

    test(
        'offline delete + restore of synced set cancels pending deleteSet op with zero queue duplicates',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final local = SessionLocalDataSource(prefs);
      await local.saveSession(
        WorkoutSessionModel(
          id: 'session-1',
          userId: 'user-1',
          startedAt: DateTime(2026, 11, 26, 10, 0),
          status: 'in_progress',
          exercises: [
            SessionExerciseModel(
              id: 'se-1',
              sessionId: 'session-1',
              exerciseId: 'ex-1',
              sets: [LoggedSetModel.fromDomain(originalDropSet)],
            ),
          ],
        ),
      );

      final offlineRepo = SessionRepositoryImpl(
        mockDataSource,
        localDataSource: local,
        isOfflineMode: () => true,
      );

      final delResult = await offlineRepo.deleteLoggedSet(originalDropSet.id);
      expect(delResult.isSuccess, isTrue);
      expect(local.getSessionById('session-1')!.exercises.single.sets, isEmpty);
      expect(
        local.getPendingOps().map((o) => o.type).toList(),
        [PendingSessionOpType.deleteSet],
      );

      final restoreResult = await offlineRepo.restoreLoggedSet(originalDropSet);
      expect(restoreResult.isSuccess, isTrue);

      final cachedSets = local.getSessionById('session-1')!.exercises.single.sets;
      expect(cachedSets, hasLength(1));
      expect(cachedSets.single.id, originalDropSet.id);
      expect(cachedSets.single.completedAt, originalDropSet.completedAt);
      expect(cachedSets.single.rpeActual, 8.5);
      expect(cachedSets.single.rirActual, 1);
      expect(cachedSets.single.setType, 'drop_set');
      expect(cachedSets.single.dropSets, originalDropSet.dropSets);

      // Pending deleteSet was cancelled cleanly — zero ops left in outbox.
      expect(local.getPendingOps(), isEmpty);
      verifyNever(() => mockDataSource.deleteLoggedSet(any()));
      verifyNever(() => mockDataSource.insertLoggedSet(any()));
    });

    test(
        'offline logSet + delete + restore of unsynced set leaves single logSet op with original id and no deleteSet conflict',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final local = SessionLocalDataSource(prefs);
      await local.saveSession(
        WorkoutSessionModel(
          id: 'session-1',
          userId: 'user-1',
          startedAt: DateTime(2026, 11, 26, 10, 0),
          status: 'in_progress',
          exercises: const [
            SessionExerciseModel(
              id: 'se-1',
              sessionId: 'session-1',
              exerciseId: 'ex-1',
            ),
          ],
        ),
      );

      final offlineRepo = SessionRepositoryImpl(
        mockDataSource,
        localDataSource: local,
        isOfflineMode: () => true,
      );

      final logged = (await offlineRepo.logSet(
        sessionExerciseId: 'se-1',
        setNumber: 2,
        setType: SetType.dropSet,
        weightKg: 80.0,
        repsCompleted: 10,
        rirActual: 1,
        rpeActual: 8.5,
        dropSets: originalDropSet.dropSets,
      ) as Success<LoggedSet, Failure>)
          .value;

      await offlineRepo.deleteLoggedSet(logged.id);
      expect(local.getPendingOps(), isEmpty);

      final restoreResult = await offlineRepo.restoreLoggedSet(logged);
      expect(restoreResult.isSuccess, isTrue);

      final ops = local.getPendingOps();
      expect(ops, hasLength(1));
      expect(ops.single.type, PendingSessionOpType.logSet);
      expect(ops.single.payload['id'], logged.id);
      expect(
        ops.single.payload['completed_at'],
        logged.completedAt!.toIso8601String(),
      );
      expect(ops.single.payload['rpe_actual'], 8.5);
      expect(ops.single.payload['rir_actual'], 1);
      expect(ops.single.payload['set_type'], 'drop_set');
    });

    test(
        'restore during in-flight deleteSet sync enqueues logSet with same id and syncs after delete finishes',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final local = SessionLocalDataSource(prefs);
      await local.saveSession(
        WorkoutSessionModel(
          id: 'session-1',
          userId: 'user-1',
          startedAt: DateTime(2026, 11, 26, 10, 0),
          status: 'in_progress',
          exercises: [
            SessionExerciseModel(
              id: 'se-1',
              sessionId: 'session-1',
              exerciseId: 'ex-1',
              sets: [LoggedSetModel.fromDomain(originalDropSet)],
            ),
          ],
        ),
      );

      var offline = true;
      final repo = SessionRepositoryImpl(
        mockDataSource,
        localDataSource: local,
        isOfflineMode: () => offline,
      );

      await repo.deleteLoggedSet(originalDropSet.id);
      expect(
        local.getPendingOps().map((o) => o.type).toList(),
        [PendingSessionOpType.deleteSet],
      );

      final callOrder = <String>[];
      final deleteCompleter = Completer<void>();
      when(() => mockDataSource.deleteLoggedSet(originalDropSet.id))
          .thenAnswer((_) async {
        callOrder.add('delete:${originalDropSet.id}');
        await deleteCompleter.future;
      });
      when(() => mockDataSource.insertLoggedSet(any())).thenAnswer((inv) async {
        final payload = inv.positionalArguments.first as Map;
        callOrder.add('insert:${payload['id']}');
        return LoggedSetModel.fromDomain(originalDropSet);
      });

      // Sync starts while user is back online and deleteSet becomes in-flight.
      offline = false;
      final syncFuture = repo.syncPendingOperations();
      await Future<void>.delayed(Duration.zero);

      expect(local.isDeleteInFlight(originalDropSet.id), isTrue);
      expect(callOrder, ['delete:set-drop-1']);

      // User taps Desfazer while deleteSet is still in-flight!
      final restoreResult = await repo.restoreLoggedSet(originalDropSet);
      expect(restoreResult.isSuccess, isTrue);

      // Local cache is restored immediately and logSet (same id) is queued after deleteSet.
      expect(
        local.getSessionById('session-1')!.exercises.single.sets.single.id,
        originalDropSet.id,
      );
      final pendingTypes = local.getPendingOps().map((o) => o.type).toList();
      expect(
        pendingTypes,
        [PendingSessionOpType.deleteSet, PendingSessionOpType.logSet],
      );
      expect(local.getPendingOps().last.payload['id'], originalDropSet.id);
      expect(callOrder, ['delete:set-drop-1']);

      // Complete in-flight deleteSet -> worker automatically drains restored logSet next.
      deleteCompleter.complete();
      final synced = await syncFuture;

      expect(synced, isTrue);
      expect(callOrder, ['delete:set-drop-1', 'insert:set-drop-1']);
      expect(local.getPendingOps(), isEmpty);
      expect(
        local.getSessionById('session-1')!.exercises.single.sets.single.id,
        originalDropSet.id,
      );
    });

    test(
        'restore when deleteSet was already removed from outbox enqueues logSet with original id and metadata',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final local = SessionLocalDataSource(prefs);
      await local.saveSession(
        WorkoutSessionModel(
          id: 'session-1',
          userId: 'user-1',
          startedAt: DateTime(2026, 11, 26, 10, 0),
          status: 'in_progress',
          exercises: const [
            SessionExerciseModel(
              id: 'se-1',
              sessionId: 'session-1',
              exerciseId: 'ex-1',
            ),
          ],
        ),
      );

      final offlineRepo = SessionRepositoryImpl(
        mockDataSource,
        localDataSource: local,
        isOfflineMode: () => true,
      );

      // Outbox is already empty (e.g. deleteSet was already popped and sent).
      expect(local.getPendingOps(), isEmpty);

      final restoreResult = await offlineRepo.restoreLoggedSet(originalDropSet);
      expect(restoreResult.isSuccess, isTrue);

      final ops = local.getPendingOps();
      expect(ops, hasLength(1));
      expect(ops.single.type, PendingSessionOpType.logSet);
      expect(ops.single.payload['id'], originalDropSet.id);
      expect(
        ops.single.payload['completed_at'],
        originalDropSet.completedAt!.toIso8601String(),
      );
      expect(ops.single.payload['rpe_actual'], 8.5);
      expect(ops.single.payload['drop_sets'], hasLength(2));
    });
  });
}
