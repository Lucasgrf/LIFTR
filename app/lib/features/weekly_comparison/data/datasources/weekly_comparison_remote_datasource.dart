import 'package:personal_fitness_os/features/weekly_comparison/data/models/cardio_log_model.dart';
import 'package:personal_fitness_os/features/weekly_comparison/data/models/weekly_snapshot_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class WeeklyComparisonRemoteDataSource {
  Future<List<CardioLogModel>> fetchCardioLogsInRange({
    required DateTime start,
    required DateTime end,
  });

  Future<CardioLogModel> insertCardioLog(Map<String, dynamic> data);

  Future<void> deleteCardioLog(String id);

  Future<List<WeeklySnapshotModel>> fetchRecentWeeklySnapshots({int limit = 12});

  Future<WeeklySnapshotModel?> upsertWeeklySnapshot(WeeklySnapshotModel snapshot);
}

class SupabaseWeeklyComparisonRemoteDataSource
    implements WeeklyComparisonRemoteDataSource {
  SupabaseWeeklyComparisonRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  static bool isMissingTableError(Object error) {
    if (error is! PostgrestException) return false;
    final msg =
        '${error.code ?? ''} ${error.message} ${error.details ?? ''}'
            .toLowerCase();
    return msg.contains('pgrst205') ||
        msg.contains('42p01') ||
        msg.contains('could not find the table') ||
        msg.contains('does not exist');
  }

  @override
  Future<List<CardioLogModel>> fetchCardioLogsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return const [];

    try {
      final response = await _supabaseClient
          .from('cardio_logs')
          .select()
          .eq('user_id', user.id)
          .gte('performed_at', start.toIso8601String())
          .lte('performed_at', end.toIso8601String())
          .order('performed_at', ascending: false);

      return (response as List<dynamic>)
          .map((e) => CardioLogModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      if (isMissingTableError(e)) return const [];
      rethrow;
    }
  }

  @override
  Future<CardioLogModel> insertCardioLog(Map<String, dynamic> data) async {
    final user = _supabaseClient.auth.currentUser;
    final payload = {
      ...data,
      if (user != null) 'user_id': user.id,
    };
    final response = await _supabaseClient
        .from('cardio_logs')
        .insert(payload)
        .select()
        .single();
    return CardioLogModel.fromJson(response);
  }

  @override
  Future<void> deleteCardioLog(String id) async {
    try {
      await _supabaseClient.from('cardio_logs').delete().eq('id', id);
    } catch (e) {
      if (isMissingTableError(e)) return;
      rethrow;
    }
  }

  @override
  Future<List<WeeklySnapshotModel>> fetchRecentWeeklySnapshots({
    int limit = 12,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return const [];

    try {
      final response = await _supabaseClient
          .from('weekly_snapshots')
          .select()
          .eq('user_id', user.id)
          .order('week_start', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .map(
            (e) =>
                WeeklySnapshotModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (e) {
      if (isMissingTableError(e)) return const [];
      rethrow;
    }
  }

  @override
  Future<WeeklySnapshotModel?> upsertWeeklySnapshot(
    WeeklySnapshotModel snapshot,
  ) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabaseClient
          .from('weekly_snapshots')
          .upsert(
            snapshot.toUpsertJson(user.id),
            onConflict: 'user_id,week_start',
          )
          .select()
          .single();
      return WeeklySnapshotModel.fromJson(response);
    } catch (e) {
      if (isMissingTableError(e)) return null;
      rethrow;
    }
  }
}
