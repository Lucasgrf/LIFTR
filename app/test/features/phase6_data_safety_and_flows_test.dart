import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/offline_banner_widget.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_stats.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/screens/exercise_list_screen.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/muscle_filter_chips.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/screens/history_screen.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_exercises_view.dart';
import 'package:personal_fitness_os/features/insights/presentation/providers/insight_providers.dart';
import 'package:personal_fitness_os/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:personal_fitness_os/features/profile/presentation/providers/profile_providers.dart';
import 'package:personal_fitness_os/features/profile/presentation/screens/profile_screen.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/add_exercise_to_workout_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/configure_sets_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/training_list_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/switch_program_sheet.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/cardio_log.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/repositories/weekly_comparison_repository.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/screens/weekly_comparison_screen.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/widgets/log_cardio_modal.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/swap_exercise_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeWeeklyRepo implements WeeklyComparisonRepository {
  _FakeWeeklyRepo(this.data);

  WeeklyComparisonData data;
  Result<void, Failure> deleteResult = const Success(null);
  final List<String> deletedIds = [];

  @override
  Future<Result<WeeklyComparisonData, Failure>> getWeeklyComparison({
    DateTime? referenceDate,
    int historyWeeks = 8,
  }) async => Success(data);

  @override
  Future<Result<CardioLog, Failure>> logStandaloneCardio({
    required String modality,
    required int durationSeconds,
    DateTime? performedAt,
    String? notes,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void, Failure>> deleteStandaloneCardio(String id) async {
    deletedIds.add(id);
    return deleteResult;
  }

  @override
  Future<Result<WeeklySnapshot, Failure>> syncWeekSnapshot(
    DateTime referenceDate,
  ) async => throw UnimplementedError();
}

class _FakeProfileRemote implements ProfileRemoteDataSource {
  bool shouldThrowOnRemove = false;
  int removeCalls = 0;

  @override
  Future<UserProfileData?> fetchProfile() async => null;

  @override
  Future<void> removeAvatar(String? storagePath) async {
    removeCalls++;
    if (shouldThrowOnRemove) {
      throw Exception('Falha simulada ao remover avatar');
    }
  }

  @override
  Future<void> saveProfile({
    String? displayName,
    String? biologicalSex,
    int? age,
    int? heightCm,
    double? weightKg,
    double? bodyFatPercent,
    String? goal,
    String? experience,
    String? activityLevel,
  }) async {}

  @override
  Future<({String avatarUrl, String storagePath})> uploadAvatar(
    String filePath, {
    String? previousStoragePath,
  }) async => throw UnimplementedError();
}

class _FakeTrainingRepo implements TrainingRepository {
  int createPlanCalls = 0;
  bool? lastCreateIsActive;
  String? lastCreatedPlanName;
  int addWorkoutCalls = 0;
  int setActiveCalls = 0;
  String? lastActivatedPlanId;
  int deletePlanCalls = 0;
  final List<String> deletedPlanIds = [];
  bool failSecondWorkout = false;
  bool failSetActive = false;
  bool failDeletePlan = false;

  @override
  Future<Result<TrainingPlan, Failure>> createTrainingPlan({
    required String name,
    String? description,
    bool isActive = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    createPlanCalls++;
    lastCreateIsActive = isActive;
    lastCreatedPlanName = name;
    return Success(
      TrainingPlan(
        id: 'plan-created',
        userId: 'u-1',
        name: name,
        description: description,
        isActive: isActive,
      ),
    );
  }

  @override
  Future<Result<Workout, Failure>> addWorkoutToPlan({
    required String trainingPlanId,
    required String name,
    int? dayOfWeek,
    int sortOrder = 0,
    String? notes,
    int? estimatedDurationMinutes,
  }) async {
    addWorkoutCalls++;
    if (failSecondWorkout && addWorkoutCalls == 2) {
      return const Err(ServerFailure('Erro simulado ao adicionar sessão'));
    }
    return Success(
      Workout(
        id: 'w-$addWorkoutCalls',
        trainingPlanId: trainingPlanId,
        name: name,
        sortOrder: sortOrder,
      ),
    );
  }

  @override
  Future<Result<List<TrainingPlan>, Failure>> getTrainingPlans() async =>
      const Success([]);

  @override
  Future<Result<TrainingPlan?, Failure>> getActiveTrainingPlan() async =>
      const Success(null);

  @override
  Future<Result<TrainingPlan, Failure>> getTrainingPlanById(String id) async =>
      throw UnimplementedError();

  @override
  Future<Result<TrainingPlan, Failure>> setActiveTrainingPlan(
    String planId,
  ) async {
    setActiveCalls++;
    lastActivatedPlanId = planId;
    if (failSetActive) {
      return const Err(ServerFailure('Erro simulado ao ativar plano'));
    }
    return Success(
      TrainingPlan(
        id: planId,
        userId: 'u-1',
        name: lastCreatedPlanName ?? 'AB (Superior / Inferior)',
        isActive: true,
      ),
    );
  }

  @override
  Future<Result<WorkoutExercise, Failure>> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
    int sortOrder = 0,
    String? notes,
    List<SetTemplate>? initialSetTemplates,
  }) async => throw UnimplementedError();

  @override
  Future<Result<List<SetTemplate>, Failure>> configureSetTemplates({
    required String workoutExerciseId,
    required List<SetTemplate> setTemplates,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void, Failure>> reorderWorkoutExercises({
    required String workoutId,
    required List<String> orderedWorkoutExerciseIds,
  }) async => const Success(null);

  @override
  Future<Result<void, Failure>> reorderPlanWorkouts({
    required String trainingPlanId,
    required List<String> orderedWorkoutIds,
  }) async => const Success(null);

  @override
  Future<Result<void, Failure>> deleteTrainingPlan(String planId) async {
    deletePlanCalls++;
    deletedPlanIds.add(planId);
    if (failDeletePlan) {
      return const Err(ServerFailure('Erro simulado no rollback'));
    }
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> deleteWorkout(String workoutId) async =>
      const Success(null);

  @override
  Future<Result<void, Failure>> deleteWorkoutExercise(
    String workoutExerciseId,
  ) async => const Success(null);
}

class _MutableTrainingPlansNotifier extends TrainingPlansNotifier {
  _MutableTrainingPlansNotifier(super.ref, this.value);

  AsyncValue<List<TrainingPlan>> value;
  int refreshCalls = 0;

  @override
  Future<void> loadPlans() async {
    state = value;
  }

  @override
  Future<Failure?> refresh() async {
    refreshCalls++;
    if (value.hasError && state.hasValue) {
      final err = value.error;
      return err is Failure ? err : UnexpectedFailure('$err', value.stackTrace);
    }
    state = value;
    if (value.hasError) {
      final err = value.error;
      return err is Failure ? err : UnexpectedFailure('$err', value.stackTrace);
    }
    return null;
  }
}

class _MutableExerciseListNotifier extends ExerciseListNotifier {
  _MutableExerciseListNotifier(super.ref, this.value);

  AsyncValue<List<Exercise>> value;
  int refreshCalls = 0;

  @override
  Future<void> loadExercises() async {
    state = value;
  }

  @override
  Future<Failure?> refresh() async {
    refreshCalls++;
    if (value.hasError && state.hasValue) {
      final err = value.error;
      return err is Failure ? err : UnexpectedFailure('$err', value.stackTrace);
    }
    state = value;
    if (value.hasError) {
      final err = value.error;
      return err is Failure ? err : UnexpectedFailure('$err', value.stackTrace);
    }
    return null;
  }
}

void main() {
  final fixedNow = DateTime(2026, 5, 14, 18, 30);

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  final cardioLog = CardioLog(
    id: 'c-1',
    userId: 'u-1',
    modality: 'Corrida',
    durationSeconds: 1500,
    performedAt: fixedNow,
  );

  final populatedWeek = WeeklyComparisonData(
    currentWeek: WeeklySnapshot(
      weekStart: DateTime(2026, 5, 11),
      weekEnd: DateTime(2026, 5, 17),
      workoutsCompleted: 3,
      workingSetsCount: 40,
      totalVolumeKg: 10000,
      cardioDurationSeconds: 1500,
    ),
    currentWeekDailyCardio: [
      DailyCardioBreakdown(day: DateTime(2026, 5, 14), standaloneSeconds: 1500),
    ],
    currentWeekStandaloneCardio: [cardioLog],
  );

  const sampleExercise = Exercise(
    id: 'ex-1',
    name: 'Supino Reto Barra',
    primaryMuscleGroup: 'chest',
    equipment: 'barbell',
  );

  const sampleWorkout = Workout(
    id: 'w-1',
    trainingPlanId: 'plan-1',
    name: 'Treino A',
    sortOrder: 0,
    exercises: [
      WorkoutExercise(
        id: 'we-1',
        workoutId: 'w-1',
        exerciseId: 'ex-1',
        exercise: sampleExercise,
        setTemplates: [
          SetTemplate(
            id: 'st-1',
            workoutExerciseId: 'we-1',
            setNumber: 1,
            targetRepsMin: 8,
            targetRepsMax: 12,
          ),
          SetTemplate(
            id: 'st-2',
            workoutExerciseId: 'we-1',
            setNumber: 2,
            targetRepsMin: 8,
            targetRepsMax: 12,
          ),
        ],
      ),
    ],
  );

  group('Phase 6 — UX-03 Data Loss Protection', () {
    testWidgets(
      'WeeklyComparisonScreen guards cardio deletion, checks Result, and exposes bottom Registrar cardio CTA',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repo = _FakeWeeklyRepo(populatedWeek)
          ..deleteResult = const Err(ServerFailure('Erro ao remover'));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              weeklyComparisonRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const WeeklyComparisonScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        void requestDelete() {
          final deleteIcon = find.byIcon(Icons.delete_outline_rounded);
          tester
              .widget<IconButton>(
                find
                    .ancestor(of: deleteIcon, matching: find.byType(IconButton))
                    .first,
              )
              .onPressed!
              .call();
        }

        // Bottom CTA replaces AppBar action
        expect(find.text('Registrar cardio'), findsOneWidget);
        expect(find.text('Cardio'), findsNothing);

        // Cancel confirmation skips repository call
        requestDelete();
        await tester.pumpAndSettle();
        expect(find.text('Remover cardio?'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(repo.deletedIds, isEmpty);

        // Confirm with Err shows error SnackBar and NOT success message
        requestDelete();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remover'));
        await tester.pumpAndSettle();
        expect(repo.deletedIds, ['c-1']);
        expect(find.text('Cardio removido.'), findsNothing);
        expect(find.byType(SnackBar), findsOneWidget);

        // Confirm with Success shows success SnackBar
        repo.deleteResult = const Success(null);
        requestDelete();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remover'));
        await tester.pumpAndSettle();
        expect(find.text('Cardio removido.'), findsOneWidget);

        // Bottom CTA opens LogCardioModal
        await tester.tap(find.text('Registrar cardio'));
        await tester.pumpAndSettle();
        expect(find.byType(LogCardioModal), findsOneWidget);
      },
    );

    testWidgets(
      'ProfileScreen confirms avatar removal, awaits Future, and rolls back on error',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final remote = _FakeProfileRemote()..shouldThrowOnRemove = true;

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            profileRemoteDataSourceProvider.overrideWithValue(remote),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(userSettingsProvider.notifier)
            .updateProfileIdentity(
              avatarUrl: 'local/avatar.png',
              avatarStoragePath: 'u-1/avatar.png',
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const ProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        Future<void> openRemoveMenu() async {
          await tester.tap(find.bySemanticsLabel('Alterar foto de perfil'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Remover foto'));
          await tester.pumpAndSettle();
        }

        // Cancel skips remote removal
        await openRemoveMenu();
        expect(find.text('Remover foto de perfil?'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(remote.removeCalls, 0);
        expect(
          container.read(userSettingsProvider).avatarUrl,
          'local/avatar.png',
        );

        // Failure rolls back avatar and never shows success copy
        await openRemoveMenu();
        await tester.tap(find.text('Remover'));
        await tester.pumpAndSettle();
        expect(remote.removeCalls, 1);
        expect(
          container.read(userSettingsProvider).avatarUrl,
          'local/avatar.png',
        );
        expect(find.text('Foto removida.'), findsNothing);
        expect(find.byType(SnackBar), findsOneWidget);

        // Success clears avatar and shows confirmation
        remote.shouldThrowOnRemove = false;
        await openRemoveMenu();
        await tester.tap(find.text('Remover'));
        await tester.pumpAndSettle();
        expect(remote.removeCalls, 2);
        expect(container.read(userSettingsProvider).avatarUrl, isNull);
        expect(find.text('Foto removida.'), findsOneWidget);
      },
    );

    test(
      'removeAvatarOrdered clears auth before deleting storage and aborts storage delete on auth error',
      () async {
        final callOrder = <String>[];
        await SupabaseProfileRemoteDataSource.removeAvatarOrdered(
          storagePath: 'u-1/avatar.png',
          clearAuthMetadata: () async => callOrder.add('auth'),
          clearProfileTable: () async => callOrder.add('profile'),
          removeFromStorage: (path) async => callOrder.add('storage:$path'),
        );
        expect(callOrder, ['auth', 'profile', 'storage:u-1/avatar.png']);

        var storageCalled = false;
        await expectLater(
          SupabaseProfileRemoteDataSource.removeAvatarOrdered(
            storagePath: 'u-1/avatar.png',
            clearAuthMetadata: () async => throw Exception('auth failure'),
            clearProfileTable: () async {},
            removeFromStorage: (_) async => storageCalled = true,
          ),
          throwsException,
        );
        expect(storageCalled, isFalse);
      },
    );

    test(
      'removeAvatarOrdered logs storage removal errors without throwing or rolling back auth',
      () async {
        final previousLogger = appErrorLogger;
        addTearDown(() => appErrorLogger = previousLogger);

        final logged = <({Object error, String? context})>[];
        appErrorLogger = (error, {stackTrace, context}) {
          logged.add((error: error, context: context));
        };

        var authCleared = false;
        await SupabaseProfileRemoteDataSource.removeAvatarOrdered(
          storagePath: 'u-1/avatar.png',
          clearAuthMetadata: () async => authCleared = true,
          clearProfileTable: () async {},
          removeFromStorage: (_) async => throw Exception('storage error'),
        );

        expect(authCleared, isTrue);
        expect(logged, hasLength(1));
        expect(
          logged.single.context,
          'ProfileRemoteDataSource.removeAvatar.storage',
        );
        expect(logged.single.error.toString(), contains('storage error'));
      },
    );

    test(
      'resolveAvatarMetadata uses auth metadata only so failed user_profiles clear cannot resurrect deleted photo',
      () async {
        final previousLogger = appErrorLogger;
        addTearDown(() => appErrorLogger = previousLogger);
        appErrorLogger = (_, {stackTrace, context}) {};

        final authMeta = <String, dynamic>{
          'avatar_url': 'https://example.com/avatar.jpg',
          'avatar_storage_path': 'u-1/avatar.jpg',
        };
        final userProfilesMirror = <String, dynamic>{
          'avatar_url': 'https://example.com/avatar.jpg',
          'avatar_storage_path': 'u-1/avatar.jpg',
        };

        await SupabaseProfileRemoteDataSource.removeAvatarOrdered(
          storagePath: 'u-1/avatar.jpg',
          clearAuthMetadata: () async {
            authMeta['avatar_url'] = null;
            authMeta['avatar_storage_path'] = null;
          },
          clearProfileTable: () async => throw Exception('mirror offline'),
          removeFromStorage: (_) async {},
        );

        // Even with stale mirror values still present, UI source returns null.
        expect(userProfilesMirror['avatar_url'], isNotNull);
        final resolved = SupabaseProfileRemoteDataSource.resolveAvatarMetadata(
          authMeta,
        );
        expect(resolved.avatarUrl, isNull);
        expect(resolved.storagePath, isNull);
      },
    );

    test(
      'saveProfileOrdered logs upsert errors with stackTrace via appErrorLogger without throwing',
      () async {
        final previousLogger = appErrorLogger;
        addTearDown(() => appErrorLogger = previousLogger);

        final logged =
            <({Object error, StackTrace? stackTrace, String? context})>[];
        appErrorLogger = (error, {stackTrace, context}) {
          logged.add((error: error, stackTrace: stackTrace, context: context));
        };

        var authUpdated = false;
        await SupabaseProfileRemoteDataSource.saveProfileOrdered(
          updateAuthDisplayName: () async => authUpdated = true,
          upsertProfileRow: () async =>
              throw Exception('PGRST204: Could not find the height_cm column'),
        );

        expect(authUpdated, isTrue);
        expect(logged, hasLength(1));
        expect(
          logged.single.context,
          'ProfileRemoteDataSource.saveProfile.upsert',
        );
        expect(logged.single.error.toString(), contains('height_cm'));
        expect(logged.single.stackTrace, isNotNull);
      },
    );

    test(
      'buildSaveProfilePayload matches production user_profiles columns and omits null optional fields',
      () {
        const expectedProductionColumns = <String>{
          'id',
          'display_name',
          'biological_sex',
          'age',
          'height_cm',
          'weight_kg',
          'body_fat_percent',
          'goal',
          'experience',
          'activity_level',
          'updated_at',
        };
        final fixedTime = DateTime.utc(2026, 11, 27, 6, 0, 0);

        final fullPayload =
            SupabaseProfileRemoteDataSource.buildSaveProfilePayload(
              userId: 'user-123',
              displayName: 'Lucas',
              biologicalSex: 'male',
              age: 28,
              heightCm: 178,
              weightKg: 78.4,
              bodyFatPercent: 14.5,
              goal: 'bulking',
              experience: 'intermediate',
              activityLevel: 'moderatelyActive',
              updatedAt: fixedTime,
            );
        expect(fullPayload.keys.toSet(), expectedProductionColumns);
        expect(fullPayload['height_cm'], 178);
        expect(fullPayload['updated_at'], fixedTime.toIso8601String());

        final partialPayload =
            SupabaseProfileRemoteDataSource.buildSaveProfilePayload(
              userId: 'user-123',
              heightCm: 178,
              weightKg: 78.4,
              updatedAt: fixedTime,
            );
        expect(partialPayload.containsKey('display_name'), isFalse);
        expect(partialPayload.keys.toSet(), {
          'id',
          'height_cm',
          'weight_kg',
          'updated_at',
        });
      },
    );

    testWidgets(
      'ConfigureSetsScreen offers functional Desfazer SnackBar after removing a set',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              workoutDetailProvider((
                planId: 'plan-1',
                workoutId: 'w-1',
              )).overrideWith((_) async => sampleWorkout),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const ConfigureSetsScreen(
                planId: 'plan-1',
                workoutId: 'w-1',
                workoutExerciseId: 'we-1',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Série 1'), findsOneWidget);
        expect(find.text('Série 2'), findsOneWidget);

        await tester.tap(find.byTooltip('Remover série').first);
        await tester.pumpAndSettle();

        expect(find.text('Série 1 removida'), findsOneWidget);
        expect(find.text('Desfazer'), findsOneWidget);
        expect(find.text('Série 2'), findsNothing);

        await tester.tap(find.text('Desfazer'));
        await tester.pumpAndSettle();

        expect(find.text('Série 1'), findsOneWidget);
        expect(find.text('Série 2'), findsOneWidget);
      },
    );

    testWidgets(
      'SwitchProgramSheet confirms before creating preset and rolls back on partial addWorkout failure without activating',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repo = _FakeTrainingRepo()..failSecondWorkout = true;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              trainingRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () =>
                        SwitchProgramSheet.show(ctx, plans: const []),
                    child: const Text('Trocar'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Trocar'));
        await tester.pumpAndSettle();

        final presetFinder = find.text('AB (Superior / Inferior)');
        await tester.dragUntilVisible(
          presetFinder,
          find.byType(ListView),
          const Offset(0, -250),
        );
        await tester.pumpAndSettle();
        await tester.tap(presetFinder);
        await tester.pumpAndSettle();

        expect(
          find.text('Criar e ativar "AB (Superior / Inferior)"?'),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(repo.createPlanCalls, 0);

        await tester.tap(presetFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Criar e ativar'));
        await tester.pumpAndSettle();

        expect(repo.createPlanCalls, 1);
        expect(repo.lastCreateIsActive, isFalse);
        expect(repo.addWorkoutCalls, 2);
        expect(repo.setActiveCalls, 0);
        expect(repo.deletePlanCalls, 1);
        expect(repo.deletedPlanIds, ['plan-created']);
        expect(find.byType(SwitchProgramSheet), findsOneWidget);
        expect(
          find.text('Programa "AB (Superior / Inferior)" criado e ativado!'),
          findsNothing,
        );
        expect(
          find.textContaining('Não foi possível criar o programa'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'SwitchProgramSheet activates preset plan only after all workouts succeed',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repo = _FakeTrainingRepo();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              trainingRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () =>
                        SwitchProgramSheet.show(ctx, plans: const []),
                    child: const Text('Trocar'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Trocar'));
        await tester.pumpAndSettle();

        final presetFinder = find.text('AB (Superior / Inferior)');
        await tester.dragUntilVisible(
          presetFinder,
          find.byType(ListView),
          const Offset(0, -250),
        );
        await tester.pumpAndSettle();
        await tester.tap(presetFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Criar e ativar'));
        await tester.pumpAndSettle();

        expect(repo.createPlanCalls, 1);
        expect(repo.lastCreateIsActive, isFalse);
        expect(repo.addWorkoutCalls, 2);
        expect(repo.setActiveCalls, 1);
        expect(repo.lastActivatedPlanId, 'plan-created');
        expect(repo.deletePlanCalls, 0);
        expect(find.byType(SwitchProgramSheet), findsNothing);
        expect(
          find.text('Programa "AB (Superior / Inferior)" criado e ativado!'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'SwitchProgramSheet logs planId via appErrorLogger when rollback deleteTrainingPlan fails',
      (tester) async {
        final previousLogger = appErrorLogger;
        addTearDown(() => appErrorLogger = previousLogger);
        final logged = <({Object error, String? context})>[];
        appErrorLogger = (error, {stackTrace, context}) {
          logged.add((error: error, context: context));
        };

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repo = _FakeTrainingRepo()
          ..failSecondWorkout = true
          ..failDeletePlan = true;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              trainingRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () =>
                        SwitchProgramSheet.show(ctx, plans: const []),
                    child: const Text('Trocar'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Trocar'));
        await tester.pumpAndSettle();

        final presetFinder = find.text('AB (Superior / Inferior)');
        await tester.dragUntilVisible(
          presetFinder,
          find.byType(ListView),
          const Offset(0, -250),
        );
        await tester.pumpAndSettle();
        await tester.tap(presetFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Criar e ativar'));
        await tester.pumpAndSettle();

        expect(repo.deletePlanCalls, 1);
        expect(repo.setActiveCalls, 0);
        expect(find.byType(SwitchProgramSheet), findsOneWidget);
        expect(
          find.textContaining('Não foi possível criar o programa'),
          findsOneWidget,
        );
        expect(
          logged.any(
            (e) =>
                e.context == 'SwitchProgramSheet.rollback(planId=plan-created)',
          ),
          isTrue,
        );
      },
    );
  });

  group('Phase 6 — UX-06 Pull-to-refresh, Filters, Search & Banner', () {
    testWidgets(
      'HistoryScreen awaits refresh future and error/empty screens expose RefreshIndicator + AlwaysScrollableScrollPhysics',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        var fetchCount = 0;
        final secondFetch = Completer<List<WorkoutSession>>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              appClockProvider.overrideWithValue(() => fixedNow),
              currentWeekSummaryProvider.overrideWith(
                (_) async => populatedWeek,
              ),
              historyListProvider.overrideWith((_) {
                fetchCount++;
                if (fetchCount == 1) return Future.value(const []);
                return secondFetch.future;
              }),
              weightHistoryProvider.overrideWith(
                (_) async => const <WeightEntry>[],
              ),
              weightStatsProvider.overrideWith(
                (_) async => const WeightStats(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const HistoryScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final refreshState = tester.state<RefreshIndicatorState>(
          find.byType(RefreshIndicator),
        );
        var refreshDone = false;
        unawaited(refreshState.show().then((_) => refreshDone = true));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(refreshDone, isFalse);

        secondFetch.complete(const []);
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
        expect(refreshDone, isTrue);

        // DashboardScreen error state
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentWeekSummaryProvider.overrideWith(
                (_) async => populatedWeek,
              ),
              dashboardDataProvider.overrideWith(
                (_) => Future<DashboardData>.error(Exception('fail')),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const DashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RefreshIndicator), findsOneWidget);
        expect(
          tester.widget<ListView>(find.byType(ListView)).physics,
          isA<AlwaysScrollableScrollPhysics>(),
        );

        // TrainingListScreen empty & error states
        late _MutableTrainingPlansNotifier plansNotifier;
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              trainingPlansStateProvider.overrideWith((ref) {
                plansNotifier = _MutableTrainingPlansNotifier(
                  ref,
                  const AsyncValue.data([]),
                );
                return plansNotifier;
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const TrainingListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RefreshIndicator), findsOneWidget);
        expect(
          tester.widget<ListView>(find.byType(ListView)).physics,
          isA<AlwaysScrollableScrollPhysics>(),
        );

        plansNotifier.state = AsyncValue.error(
          Exception('fail'),
          StackTrace.current,
        );
        await tester.pumpAndSettle();
        expect(find.byType(RefreshIndicator), findsOneWidget);

        // WeeklyComparisonScreen error state
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              weeklyComparisonProvider.overrideWith(
                (_) => Future<WeeklyComparisonData>.error(Exception('fail')),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const WeeklyComparisonScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RefreshIndicator), findsOneWidget);

        // ExerciseListScreen empty & error states
        late _MutableExerciseListNotifier exNotifier;
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              exerciseListStateProvider.overrideWith((ref) {
                exNotifier = _MutableExerciseListNotifier(
                  ref,
                  const AsyncValue.data([]),
                );
                return exNotifier;
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const ExerciseListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RefreshIndicator), findsOneWidget);

        exNotifier.state = AsyncValue.error(
          Exception('fail'),
          StackTrace.current,
        );
        await tester.pumpAndSettle();
        expect(find.byType(RefreshIndicator), findsOneWidget);
      },
    );

    test(
      'Ombros and muscle filters match only primaryMuscleGroup and exclude secondary-only exercises',
      () {
        const shoulderMain = Exercise(
          id: '1',
          name: 'Desenvolvimento',
          primaryMuscleGroup: 'shoulders',
        );
        const antDelt = Exercise(
          id: '2',
          name: 'Elevação Frontal',
          primaryMuscleGroup: 'anterior_deltoid',
        );
        const latDelt = Exercise(
          id: '3',
          name: 'Elevação Lateral',
          primaryMuscleGroup: 'lateral_deltoid',
        );
        const postDelt = Exercise(
          id: '4',
          name: 'Crucifixo Inverso',
          primaryMuscleGroup: 'posterior_deltoid',
        );
        const secondaryDelt = Exercise(
          id: '5',
          name: 'Supino Inclinado',
          primaryMuscleGroup: 'chest',
          secondaryMuscles: ['lateral_deltoid', 'triceps'],
        );
        const legs = Exercise(
          id: '6',
          name: 'Agachamento',
          primaryMuscleGroup: 'quadriceps',
        );

        final ombrosOption = MuscleFilterChips.muscleOptions.firstWhere(
          (o) => o['label'] == 'Ombros',
        );
        expect(ombrosOption['key'], 'shoulders');

        final shoulderMatched = filterExercises(const [
          shoulderMain,
          antDelt,
          latDelt,
          postDelt,
          secondaryDelt,
          legs,
        ], selectedMuscle: 'shoulders');
        expect(shoulderMatched.map((e) => e.id).toList(), ['1', '2', '3', '4']);

        final tricepsMatched = filterExercises(const [
          secondaryDelt,
          legs,
        ], selectedMuscle: 'triceps');
        expect(tricepsMatched, isEmpty);
      },
    );

    testWidgets(
      'Search state is isolated across ExerciseListScreen & AddExerciseToWorkoutScreen and Limpar busca works everywhere',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        const exercises = [
          Exercise(id: 'e1', name: 'Supino Reto', primaryMuscleGroup: 'chest'),
          Exercise(
            id: 'e2',
            name: 'Elevação Lateral',
            primaryMuscleGroup: 'lateral_deltoid',
          ),
          Exercise(
            id: 'e3',
            name: 'Crucifixo Inverso',
            primaryMuscleGroup: 'posterior_deltoid',
          ),
          Exercise(
            id: 'e4',
            name: 'Desenvolvimento',
            primaryMuscleGroup: 'shoulders',
          ),
          Exercise(
            id: 'e5',
            name: 'Remada Curvada',
            primaryMuscleGroup: 'back',
          ),
          Exercise(
            id: 'e6',
            name: 'Rosca Direta',
            primaryMuscleGroup: 'biceps',
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appClockProvider.overrideWithValue(() => fixedNow),
            exerciseListStateProvider.overrideWith(
              (ref) => _MutableExerciseListNotifier(
                ref,
                const AsyncValue.data(exercises),
              ),
            ),
            historyListProvider.overrideWith(
              (_) async => [
                WorkoutSession(
                  id: 's1',
                  userId: 'u-1',
                  startedAt: fixedNow,
                  status: SessionStatus.completed,
                  exercises: [
                    for (var i = 0; i < exercises.length; i++)
                      SessionExercise(
                        id: 'se-$i',
                        sessionId: 's1',
                        exerciseId: exercises[i].id,
                        exercise: exercises[i],
                        sets: [
                          LoggedSet(
                            id: 'ls-$i',
                            sessionExerciseId: 'se-$i',
                            setNumber: 1,
                            weightKg: 40,
                            repsCompleted: 10,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ],
        );
        addTearDown(container.dispose);

        // 1. ExerciseListScreen search + Ombros + Limpar busca
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const ExerciseListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'inexistente');
        await tester.pumpAndSettle();
        expect(find.byTooltip('Limpar busca'), findsOneWidget);
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        tester
            .widget<IconButton>(
              find
                  .ancestor(
                    of: find.byIcon(Icons.clear_rounded),
                    matching: find.byType(IconButton),
                  )
                  .first,
            )
            .onPressed!
            .call();
        await tester.pumpAndSettle();
        expect(find.text('Supino Reto'), findsOneWidget);

        // Search in ExerciseListScreen must NOT leak to AddExerciseToWorkoutScreen
        await tester.enterText(find.byType(TextField), 'Supino');
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const AddExerciseToWorkoutScreen(
                planId: 'plan-1',
                workoutId: 'w-1',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Elevação Lateral'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'nada-aqui');
        await tester.pumpAndSettle();
        expect(find.text('Limpar busca'), findsOneWidget);
        await tester.tap(find.text('Limpar busca'));
        await tester.pumpAndSettle();
        expect(find.text('Elevação Lateral'), findsOneWidget);

        // 2. SwapExerciseSheet Limpar busca
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: Scaffold(
                body: SwapExerciseSheet(
                  currentExercise: exercises.first,
                  onSelect: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'inexistente');
        await tester.pumpAndSettle();
        expect(find.text('Limpar busca'), findsOneWidget);
        await tester.tap(find.text('Limpar busca'));
        await tester.pumpAndSettle();
        expect(find.text('Elevação Lateral'), findsOneWidget);

        // 3. ProgressExercisesView uses status filters instead of text search
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const Scaffold(
                body: SingleChildScrollView(child: ProgressExercisesView()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Todos'), findsOneWidget);
        expect(find.textContaining('Subindo'), findsOneWidget);
        expect(find.text('Supino Reto'), findsOneWidget);
      },
    );

    testWidgets(
      'DashboardScreen preserves cached data and shows offline SnackBar when pull-to-refresh fails',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        var fetchCount = 0;
        const cachedWorkout = Workout(
          id: 'w-cached',
          trainingPlanId: 'p-cached',
          name: 'Push A Offline',
          sortOrder: 0,
        );
        const cachedPlan = TrainingPlan(
          id: 'p-cached',
          userId: 'u-1',
          name: 'Push Pull Legs',
          isActive: true,
          workouts: [cachedWorkout],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              appClockProvider.overrideWithValue(() => fixedNow),
              isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
              currentWeekSummaryProvider.overrideWith(
                (_) async => populatedWeek,
              ),
              fitnessInsightsProvider.overrideWith((_) async => const []),
              dashboardDataProvider.overrideWith((_) async {
                fetchCount++;
                if (fetchCount == 1) {
                  return const DashboardData(
                    activePlan: cachedPlan,
                    todayWorkout: cachedWorkout,
                  );
                }
                if (fetchCount == 2) {
                  throw const NetworkFailure('Sem internet');
                }
                throw const ServerFailure('500 internal');
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const DashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Push A Offline'), findsOneWidget);

        unawaited(
          tester
              .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
              .show(),
        );
        await tester.pumpAndSettle();

        expect(fetchCount, 2);
        expect(find.byType(ErrorStateWidget), findsNothing);
        expect(find.text('Push A Offline'), findsOneWidget);
        expect(
          find.text(
            '${userFacingMessage(const NetworkFailure('Sem internet'))} Mostrando dados salvos.',
          ),
          findsOneWidget,
        );

        ScaffoldMessenger.of(
          tester.element(find.byType(DashboardScreen)),
        ).clearSnackBars();
        unawaited(
          tester
              .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
              .show(),
        );
        await tester.pumpAndSettle();

        expect(fetchCount, 3);
        expect(find.byType(ErrorStateWidget), findsNothing);
        expect(find.text('Push A Offline'), findsOneWidget);
        expect(
          find.text(
            '${userFacingMessage(const ServerFailure('500 internal'))} Mostrando dados salvos.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TrainingListScreen preserves cached plans and shows offline SnackBar when pull-to-refresh fails',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        const cachedPlan = TrainingPlan(
          id: 'p-1',
          userId: 'u-1',
          name: 'Programa Cached',
          isActive: true,
          workouts: [
            Workout(
              id: 'w-1',
              trainingPlanId: 'p-1',
              name: 'Upper A Salvo',
              sortOrder: 0,
            ),
          ],
        );
        late _MutableTrainingPlansNotifier plansNotifier;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              appClockProvider.overrideWithValue(() => fixedNow),
              isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
              trainingPlansStateProvider.overrideWith((ref) {
                plansNotifier = _MutableTrainingPlansNotifier(
                  ref,
                  const AsyncValue.data([cachedPlan]),
                );
                return plansNotifier;
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const TrainingListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Upper A Salvo'), findsOneWidget);

        plansNotifier.value = AsyncValue.error(
          const NetworkFailure('Sem conexão'),
          StackTrace.current,
        );
        unawaited(
          tester
              .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
              .show(),
        );
        await tester.pumpAndSettle();

        expect(plansNotifier.refreshCalls, 1);
        expect(find.byType(ErrorStateWidget), findsNothing);
        expect(find.text('Upper A Salvo'), findsOneWidget);
        expect(
          find.text(
            '${userFacingMessage(const NetworkFailure('Sem conexão'))} Mostrando dados salvos.',
          ),
          findsOneWidget,
        );

        ScaffoldMessenger.of(
          tester.element(find.byType(TrainingListScreen)),
        ).clearSnackBars();
        plansNotifier.value = AsyncValue.error(
          const ServerFailure('Erro 503'),
          StackTrace.current,
        );
        unawaited(
          tester
              .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
              .show(),
        );
        await tester.pumpAndSettle();

        expect(plansNotifier.refreshCalls, 2);
        expect(find.byType(ErrorStateWidget), findsNothing);
        expect(find.text('Upper A Salvo'), findsOneWidget);
        expect(
          find.text(
            '${userFacingMessage(const ServerFailure('Erro 503'))} Mostrando dados salvos.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'OfflineBannerWidget removes redundant 48dp left spacer while preserving 48x48 dismiss target',
      (tester) async {
        var dismissed = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: OfflineBannerWidget(onDismiss: () => dismissed = true),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final bannerFinder = find.byType(OfflineBannerWidget);
        final spacer48Boxes = find.descendant(
          of: bannerFinder,
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == 48 && w.height == null,
          ),
        );
        expect(spacer48Boxes, findsNothing);

        final closeFinder = find.byIcon(Icons.close_rounded);
        final closeInkWell = find.ancestor(
          of: closeFinder,
          matching: find.byType(InkWell),
        );
        final closeSize = tester.getSize(closeInkWell);
        expect(closeSize.width, greaterThanOrEqualTo(48));
        expect(closeSize.height, greaterThanOrEqualTo(48));

        await tester.tap(closeInkWell);
        expect(dismissed, isTrue);
      },
    );
  });
}
