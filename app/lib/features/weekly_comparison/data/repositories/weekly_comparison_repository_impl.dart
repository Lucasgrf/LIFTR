import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';
import 'package:personal_fitness_os/features/weekly_comparison/data/datasources/weekly_comparison_local_datasource.dart';
import 'package:personal_fitness_os/features/weekly_comparison/data/datasources/weekly_comparison_remote_datasource.dart';
import 'package:personal_fitness_os/features/weekly_comparison/data/models/cardio_log_model.dart';
import 'package:personal_fitness_os/features/weekly_comparison/data/models/weekly_snapshot_model.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/cardio_log.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/repositories/weekly_comparison_repository.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/services/weekly_snapshot_aggregator.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_local_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:uuid/uuid.dart';

class WeeklyComparisonRepositoryImpl implements WeeklyComparisonRepository {
  WeeklyComparisonRepositoryImpl({
    required HistoryRepository historyRepository,
    required WeeklyComparisonRemoteDataSource remoteDataSource,
    WeeklyComparisonLocalDataSource? localDataSource,
    SessionLocalDataSource? localSessionDataSource,
  })  : _historyRepository = historyRepository,
        _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _localSessionDataSource = localSessionDataSource;

  final HistoryRepository _historyRepository;
  final WeeklyComparisonRemoteDataSource _remoteDataSource;
  final WeeklyComparisonLocalDataSource? _localDataSource;
  final SessionLocalDataSource? _localSessionDataSource;

  static const _uuid = Uuid();

  Future<List<WorkoutSession>> _loadSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final sessions = <WorkoutSession>[];
    final seenIds = <String>{};

    try {
      final result = await _historyRepository.getSessionsInRange(
        start: start,
        end: end,
      );
      result.fold(
        (remoteList) {
          for (final s in remoteList) {
            if (seenIds.add(s.id)) sessions.add(s);
          }
        },
        (_) {},
      );
    } catch (_) {}

    final local = _localSessionDataSource;
    if (local != null) {
      for (final model in local.getAllCachedSessions()) {
        if (model.status != 'completed') continue;
        final domain = model.toDomain();
        final ts = domain.completedAt ?? domain.startedAt;
        if (ts.isBefore(start) || ts.isAfter(end)) continue;
        if (seenIds.add(domain.id)) {
          sessions.add(domain);
        }
      }
    }

    return sessions;
  }

  Future<List<CardioLog>> _loadCardioInRange(
    DateTime start,
    DateTime end,
  ) async {
    final local = _localDataSource;
    final map = <String, CardioLog>{};

    try {
      final remote = await _remoteDataSource.fetchCardioLogsInRange(
        start: start,
        end: end,
      );
      for (final m in remote) {
        map[m.id] = m.toDomain();
      }
      if (local != null && remote.isNotEmpty) {
        await local.saveAllCardioLogsInRange(
          start: start,
          end: end,
          remoteLogs: remote,
        );
      }
    } catch (_) {}

    if (local != null) {
      for (final m in local.getCardioLogsInRange(start: start, end: end)) {
        map.putIfAbsent(m.id, m.toDomain);
      }
    }

    final list = map.values.toList()
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return list;
  }

  Future<void> _bestEffortPersistSnapshot(WeeklySnapshot snapshot) async {
    final local = _localDataSource;
    if (local != null && snapshot.hasActivity) {
      await local.saveWeeklySnapshot(WeeklySnapshotModel.fromDomain(snapshot));
    }
    if (!snapshot.hasActivity) return;
    try {
      await _remoteDataSource.upsertWeeklySnapshot(
        WeeklySnapshotModel.fromDomain(snapshot),
      );
    } catch (_) {}
  }

  @override
  Future<Result<WeeklyComparisonData, Failure>> getWeeklyComparison({
    DateTime? referenceDate,
    int historyWeeks = 8,
  }) async {
    try {
      final refDate = referenceDate ?? DateTime.now();
      final currentStart = isoWeekStart(refDate);
      final currentEnd = isoWeekEnd(currentStart);
      final prevStart = currentStart.subtract(const Duration(days: 7));

      final sessions = await _loadSessionsInRange(prevStart, currentEnd);
      final cardioLogs = await _loadCardioInRange(prevStart, currentEnd);

      final currentSnap = WeeklySnapshotAggregator.aggregateWeek(
        weekStart: currentStart,
        sessions: sessions,
        standaloneCardio: cardioLogs,
      );
      final prevSnapRaw = WeeklySnapshotAggregator.aggregateWeek(
        weekStart: prevStart,
        sessions: sessions,
        standaloneCardio: cardioLogs,
      );

      await _bestEffortPersistSnapshot(currentSnap);
      await _bestEffortPersistSnapshot(prevSnapRaw);

      final historyByKey = <String, WeeklySnapshot>{};
      final local = _localDataSource;
      if (local != null) {
        for (final m in local.getRecentWeeklySnapshots()) {
          historyByKey[isoDateKey(m.weekStart)] = m.toDomain();
        }
      }

      try {
        final remoteHistory = await _remoteDataSource.fetchRecentWeeklySnapshots(
          limit: historyWeeks + 2,
        );
        if (local != null && remoteHistory.isNotEmpty) {
          await local.saveWeeklySnapshots(remoteHistory);
        }
        for (final m in remoteHistory) {
          final dom = m.toDomain();
          final key = isoDateKey(dom.weekStart);
          if (dom.hasActivity || !historyByKey.containsKey(key)) {
            historyByKey[key] = dom;
          }
        }
      } catch (_) {}

      if (currentSnap.hasActivity) {
        historyByKey[isoDateKey(currentStart)] = currentSnap;
      }
      if (prevSnapRaw.hasActivity) {
        historyByKey[isoDateKey(prevStart)] = prevSnapRaw;
      }

      final prevKey = isoDateKey(prevStart);
      final historyPrev = historyByKey[prevKey];
      final WeeklySnapshot? resolvedPreviousWeek = prevSnapRaw.hasActivity
          ? prevSnapRaw
          : (historyPrev != null && historyPrev.hasActivity
              ? historyPrev
              : null);

      final dailyBreakdown = WeeklySnapshotAggregator.buildDailyCardioBreakdown(
        weekStart: currentStart,
        sessions: sessions,
        standaloneCardio: cardioLogs,
      );

      final currentStandalone = cardioLogs
          .where(
            (c) =>
                !c.performedAt.isBefore(currentStart) &&
                !c.performedAt.isAfter(currentEnd),
          )
          .toList()
        ..sort((a, b) => b.performedAt.compareTo(a.performedAt));

      final recentHistory = historyByKey.values
          .where((w) => w.hasActivity)
          .toList()
        ..sort((a, b) => b.weekStart.compareTo(a.weekStart));

      return Success(
        WeeklyComparisonData(
          currentWeek: currentSnap,
          previousWeek: resolvedPreviousWeek,
          currentWeekDailyCardio: dailyBreakdown,
          currentWeekStandaloneCardio: currentStandalone,
          recentWeeksHistory: recentHistory.take(historyWeeks).toList(),
        ),
      );
    } catch (e, stack) {
      return Err(
        UnexpectedFailure('Erro ao carregar comparação semanal: $e', stack),
      );
    }
  }

  @override
  Future<Result<CardioLog, Failure>> logStandaloneCardio({
    required String modality,
    required int durationSeconds,
    DateTime? performedAt,
    String? notes,
  }) async {
    if (durationSeconds <= 0) {
      return const Err(
        ValidationFailure('Informe uma duração maior que zero minutos.'),
      );
    }

    final ts = performedAt ?? DateTime.now();
    final trimmedModality =
        modality.trim().isEmpty ? 'Cardio' : modality.trim();
    final trimmedNotes =
        (notes == null || notes.trim().isEmpty) ? null : notes.trim();
    final local = _localDataSource;

    final localFallback = CardioLogModel(
      id: _uuid.v4(),
      userId: 'local_user',
      modality: trimmedModality,
      durationSeconds: durationSeconds,
      performedAt: ts,
      notes: trimmedNotes,
      createdAt: DateTime.now(),
    );

    CardioLogModel savedModel = localFallback;
    try {
      final remote = await _remoteDataSource.insertCardioLog({
        'id': localFallback.id,
        'modality': trimmedModality,
        'duration_seconds': durationSeconds,
        'performed_at': ts.toIso8601String(),
        if (trimmedNotes != null) 'notes': trimmedNotes,
      });
      savedModel = remote;
      await local?.saveCardioLog(remote);
    } catch (e) {
      if (local != null) {
        await local.saveCardioLog(localFallback);
      } else if (!SupabaseWeeklyComparisonRemoteDataSource.isMissingTableError(
        e,
      )) {
        return Err(
          UnexpectedFailure('Erro ao salvar cardio: $e'),
        );
      }
    }

    await syncWeekSnapshot(ts);
    return Success(savedModel.toDomain());
  }

  @override
  Future<Result<void, Failure>> deleteStandaloneCardio(String id) async {
    try {
      await _remoteDataSource.deleteCardioLog(id);
    } catch (_) {}
    await _localDataSource?.deleteCardioLog(id);
    await syncWeekSnapshot(DateTime.now());
    return const Success(null);
  }

  @override
  Future<Result<WeeklySnapshot, Failure>> syncWeekSnapshot(
    DateTime referenceDate,
  ) async {
    try {
      final start = isoWeekStart(referenceDate);
      final end = isoWeekEnd(start);
      final sessions = await _loadSessionsInRange(start, end);
      final cardio = await _loadCardioInRange(start, end);
      final snapshot = WeeklySnapshotAggregator.aggregateWeek(
        weekStart: start,
        sessions: sessions,
        standaloneCardio: cardio,
      );
      await _bestEffortPersistSnapshot(snapshot);
      return Success(snapshot);
    } catch (e, stack) {
      return Err(
        UnexpectedFailure('Erro ao sincronizar resumo semanal: $e', stack),
      );
    }
  }
}
