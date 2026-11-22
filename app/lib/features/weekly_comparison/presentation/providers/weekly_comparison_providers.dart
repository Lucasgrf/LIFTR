import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/constants/supabase_config.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/weekly_comparison/data/datasources/weekly_comparison_local_datasource.dart';
import 'package:personal_fitness_os/features/weekly_comparison/data/datasources/weekly_comparison_remote_datasource.dart';
import 'package:personal_fitness_os/features/weekly_comparison/data/models/cardio_log_model.dart';
import 'package:personal_fitness_os/features/weekly_comparison/data/models/weekly_snapshot_model.dart';
import 'package:personal_fitness_os/features/weekly_comparison/data/repositories/weekly_comparison_repository_impl.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/repositories/weekly_comparison_repository.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _NoopWeeklyComparisonRemoteDataSource
    implements WeeklyComparisonRemoteDataSource {
  const _NoopWeeklyComparisonRemoteDataSource();

  @override
  Future<void> deleteCardioLog(String id) async {}

  @override
  Future<List<CardioLogModel>> fetchCardioLogsInRange({
    required DateTime start,
    required DateTime end,
  }) async =>
      const [];

  @override
  Future<List<WeeklySnapshotModel>> fetchRecentWeeklySnapshots({
    int limit = 12,
  }) async =>
      const [];

  @override
  Future<CardioLogModel> insertCardioLog(Map<String, dynamic> data) async {
    return CardioLogModel(
      id: data['id'] as String? ?? 'local-cardio',
      userId: 'local_user',
      modality: data['modality'] as String? ?? 'Cardio',
      durationSeconds: (data['duration_seconds'] as num?)?.toInt() ?? 0,
      performedAt: data['performed_at'] != null
          ? DateTime.parse(data['performed_at'] as String)
          : DateTime.now(),
      notes: data['notes'] as String?,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<WeeklySnapshotModel?> upsertWeeklySnapshot(
    WeeklySnapshotModel snapshot,
  ) async =>
      null;
}

final weeklyComparisonRemoteDataSourceProvider =
    Provider<WeeklyComparisonRemoteDataSource>((ref) {
  if (!SupabaseConfig.isConfigured) {
    return const _NoopWeeklyComparisonRemoteDataSource();
  }
  try {
    return SupabaseWeeklyComparisonRemoteDataSource(Supabase.instance.client);
  } catch (_) {
    return const _NoopWeeklyComparisonRemoteDataSource();
  }
});

final weeklyComparisonLocalDataSourceProvider =
    Provider<WeeklyComparisonLocalDataSource?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs == null) return null;
  final userId = ref.watch(activeUserIdProvider);
  return WeeklyComparisonLocalDataSource(prefs, userId: userId);
});

final weeklyComparisonRepositoryProvider =
    Provider<WeeklyComparisonRepository>((ref) {
  ref.watch(activeUserIdProvider);
  return WeeklyComparisonRepositoryImpl(
    historyRepository: ref.watch(historyRepositoryProvider),
    remoteDataSource: ref.watch(weeklyComparisonRemoteDataSourceProvider),
    localDataSource: ref.watch(weeklyComparisonLocalDataSourceProvider),
    localSessionDataSource: ref.watch(sessionLocalDataSourceProvider),
  );
});

/// 0 = current week, -1 = previous week, etc.
final weeklyComparisonOffsetProvider =
    StateProvider.autoDispose<int>((ref) => 0);

final weeklyComparisonProvider =
    FutureProvider.autoDispose<WeeklyComparisonData>((ref) async {
  ref.watch(activeUserIdProvider);
  final offset = ref.watch(weeklyComparisonOffsetProvider);
  final referenceDate =
      DateTime.now().add(Duration(days: offset * 7));
  final repo = ref.watch(weeklyComparisonRepositoryProvider);
  final result = await repo.getWeeklyComparison(referenceDate: referenceDate);

  return result.fold(
    (data) => data,
    (failure) => throw Exception(failure.message),
  );
});

/// Always fetches current week vs previous week for compact summaries on Home &
/// Progresso without throwing when running in isolated widget tests.
final currentWeekSummaryProvider =
    FutureProvider.autoDispose<WeeklyComparisonData>((ref) async {
  ref.watch(activeUserIdProvider);
  final now = DateTime.now();
  final weekStart = isoWeekStart(now);
  try {
    final repo = ref.watch(weeklyComparisonRepositoryProvider);
    final result = await repo.getWeeklyComparison(referenceDate: now);
    return result.fold(
      (data) => data,
      (_) => WeeklyComparisonData(
        currentWeek: WeeklySnapshot(
          weekStart: weekStart,
          weekEnd: isoWeekEnd(weekStart),
        ),
      ),
    );
  } catch (_) {
    return WeeklyComparisonData(
      currentWeek: WeeklySnapshot(
        weekStart: weekStart,
        weekEnd: isoWeekEnd(weekStart),
      ),
    );
  }
});
