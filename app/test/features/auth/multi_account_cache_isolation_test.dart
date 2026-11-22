import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/workout_queue_provider.dart';
import 'package:personal_fitness_os/features/weekly_comparison/data/models/cardio_log_model.dart';
import 'package:personal_fitness_os/features/weekly_comparison/data/models/weekly_snapshot_model.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/workout_session_model.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/routing/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Multi-Account Cache Isolation (User A -> User B switch)', () {
    test(
        'switching activeUserIdProvider isolates settings, sessions, weekly snapshots, cardio logs and workout queue per user',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // 1. Sign in as User A (luuccaassssss@gmail.com)
      container.read(activeUserIdProvider.notifier).state = 'user-a-uuid';

      container.read(userSettingsProvider.notifier).updateProfileIdentity(
            displayName: 'Lucas Ferreira',
            avatarUrl: 'https://example.com/user-a.jpg',
            avatarStoragePath: 'user-a/avatar.jpg',
          );
      container.read(userSettingsProvider.notifier).updateBodyData(
            weightKg: 84.5,
            heightCm: 182,
            age: 26,
          );

      final localSessionA = container.read(sessionLocalDataSourceProvider)!;
      await localSessionA.saveSession(
        WorkoutSessionModel(
          id: 'sess-a1',
          userId: 'user-a-uuid',
          workoutName: 'Lower A Pesado',
          startedAt: DateTime(2026, 11, 21, 18),
          completedAt: DateTime(2026, 11, 21, 19),
          durationSeconds: 3600,
          status: 'completed',
        ),
      );

      final localWeeklyA =
          container.read(weeklyComparisonLocalDataSourceProvider)!;
      await localWeeklyA.saveCardioLog(
        CardioLogModel(
          id: 'cardio-a1',
          userId: 'user-a-uuid',
          modality: 'Esteira',
          durationSeconds: 1500,
          performedAt: DateTime(2026, 11, 21, 19, 30),
        ),
      );
      await localWeeklyA.saveWeeklySnapshot(
        WeeklySnapshotModel(
          weekStart: DateTime(2026, 11, 16),
          weekEnd: DateTime(2026, 11, 22),
          userId: 'user-a-uuid',
          workoutsCompleted: 4,
          cardioDurationSeconds: 3600,
          workingSetsCount: 48,
          totalVolumeKg: 14200,
        ),
      );

      expect(
        container.read(userSettingsProvider).displayName,
        'Lucas Ferreira',
      );
      expect(
        container.read(userSettingsProvider).avatarUrl,
        'https://example.com/user-a.jpg',
      );
      expect(
        localSessionA.getLastCompletedSession()?.workoutName,
        'Lower A Pesado',
      );
      expect(localWeeklyA.getAllCardioLogs(), hasLength(1));
      expect(localWeeklyA.getRecentWeeklySnapshots(), hasLength(1));

      // 2. Switch to User B (lucasgabrielrf.contato@gmail.com)
      container.read(activeUserIdProvider.notifier).state = 'user-b-uuid';

      final settingsB = container.read(userSettingsProvider);
      expect(settingsB.displayName, isNull);
      expect(settingsB.avatarUrl, isNull);
      expect(settingsB.avatarStoragePath, isNull);
      expect(settingsB.weightKg, 78.4); // default, not User A's 84.5

      final localSessionB = container.read(sessionLocalDataSourceProvider)!;
      expect(localSessionB.getAllCachedSessions(), isEmpty);
      expect(localSessionB.getLastCompletedSession(), isNull);
      expect(localSessionB.getActiveSession(), isNull);
      expect(localSessionB.pendingCount, 0);

      final localWeeklyB =
          container.read(weeklyComparisonLocalDataSourceProvider)!;
      expect(localWeeklyB.getAllCardioLogs(), isEmpty);
      expect(localWeeklyB.getRecentWeeklySnapshots(), isEmpty);

      expect(container.read(workoutQueueProvider), isEmpty);

      // 3. Switch back to User A -> User A's data is preserved
      container.read(activeUserIdProvider.notifier).state = 'user-a-uuid';
      expect(
        container.read(userSettingsProvider).displayName,
        'Lucas Ferreira',
      );
      expect(container.read(userSettingsProvider).weightKg, 84.5);
      expect(
        container
            .read(sessionLocalDataSourceProvider)!
            .getLastCompletedSession()
            ?.workoutName,
        'Lower A Pesado',
      );
      expect(
        container
            .read(weeklyComparisonLocalDataSourceProvider)!
            .getRecentWeeklySnapshots(),
        hasLength(1),
      );
    });
  });
}
