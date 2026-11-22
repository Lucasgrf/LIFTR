import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_local_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_remote_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/repositories/session_repository_impl.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/abandon_workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/add_exercise_to_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/delete_logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/finish_workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/get_active_workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/get_workout_session_by_id.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/log_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/start_workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/swap_session_exercise.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Data Source & Repository Providers ---

final sessionRemoteDataSourceProvider = Provider<SessionRemoteDataSource>((ref) {
  return SupabaseSessionRemoteDataSource(Supabase.instance.client);
});

final sessionLocalDataSourceProvider = Provider<SessionLocalDataSource?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs == null) return null;
  return SessionLocalDataSource(prefs);
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final remoteDataSource = ref.watch(sessionRemoteDataSourceProvider);
  final localDataSource = ref.watch(sessionLocalDataSourceProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return SessionRepositoryImpl(
    remoteDataSource,
    localDataSource: localDataSource,
    networkInfo: networkInfo,
    isOfflineMode: () => ref.read(isOfflineModeProvider),
    onConnectivityFallback: (offline) {
      Future.microtask(() {
        ref.read(runtimeOfflineDetectedProvider.notifier).state = offline;
      });
    },
    onPendingCountChanged: (count) {
      Future.microtask(() {
        ref.read(pendingSyncCountProvider.notifier).state = count;
      });
    },
  );
});

/// Watches connectivity and simulated offline changes to flush queued offline
/// workout operations automatically when connectivity returns.
final sessionAutoSyncProvider = Provider<void>((ref) {
  final local = ref.watch(sessionLocalDataSourceProvider);
  if (local != null) {
    Future.microtask(() {
      ref.read(pendingSyncCountProvider.notifier).state = local.pendingCount;
    });
  }

  void triggerSyncIfReady() {
    final repo = ref.read(sessionRepositoryProvider);
    final isOnline = ref.read(isOnlineStreamProvider).asData?.value ?? true;
    final simulated = ref.read(simulatedOfflineProvider);
    if (isOnline && !simulated && repo is SessionRepositoryImpl) {
      unawaited(repo.syncPendingOperations());
    }
  }

  ref.listen<AsyncValue<bool>>(isOnlineStreamProvider, (previous, next) {
    final online = next.asData?.value;
    if (online == true) {
      ref.read(runtimeOfflineDetectedProvider.notifier).state = false;
      triggerSyncIfReady();
    }
  });

  ref.listen<bool>(simulatedOfflineProvider, (previous, next) {
    if (!next) {
      triggerSyncIfReady();
    }
  });
});

// --- Use Case Providers ---

final startWorkoutSessionUseCaseProvider = Provider<StartWorkoutSessionUseCase>((ref) {
  return StartWorkoutSessionUseCase(ref.watch(sessionRepositoryProvider));
});

final getActiveWorkoutSessionUseCaseProvider =
    Provider<GetActiveWorkoutSessionUseCase>((ref) {
  return GetActiveWorkoutSessionUseCase(ref.watch(sessionRepositoryProvider));
});

final getWorkoutSessionByIdUseCaseProvider =
    Provider<GetWorkoutSessionByIdUseCase>((ref) {
  return GetWorkoutSessionByIdUseCase(ref.watch(sessionRepositoryProvider));
});

final logSetUseCaseProvider = Provider<LogSetUseCase>((ref) {
  return LogSetUseCase(ref.watch(sessionRepositoryProvider));
});

final deleteLoggedSetUseCaseProvider = Provider<DeleteLoggedSetUseCase>((ref) {
  return DeleteLoggedSetUseCase(ref.watch(sessionRepositoryProvider));
});

final addExerciseToSessionUseCaseProvider =
    Provider<AddExerciseToSessionUseCase>((ref) {
  return AddExerciseToSessionUseCase(ref.watch(sessionRepositoryProvider));
});

final swapSessionExerciseUseCaseProvider =
    Provider<SwapSessionExerciseUseCase>((ref) {
  return SwapSessionExerciseUseCase(ref.watch(sessionRepositoryProvider));
});

final finishWorkoutSessionUseCaseProvider =
    Provider<FinishWorkoutSessionUseCase>((ref) {
  return FinishWorkoutSessionUseCase(ref.watch(sessionRepositoryProvider));
});

final abandonWorkoutSessionUseCaseProvider =
    Provider<AbandonWorkoutSessionUseCase>((ref) {
  return AbandonWorkoutSessionUseCase(ref.watch(sessionRepositoryProvider));
});

// --- Rest Timer State & Notifier ---

enum RestTimerStatus {
  idle,
  running,
  paused,
  completed,
  dismissed,
}

class RestTimerState {
  const RestTimerState({
    this.status = RestTimerStatus.idle,
    this.remainingSeconds = 0,
    this.totalSeconds = 0,
    this.exerciseName,
    this.setNumber,
  });

  final RestTimerStatus status;
  final int remainingSeconds;
  final int totalSeconds;
  final String? exerciseName;
  final int? setNumber;

  bool get isRunning => status == RestTimerStatus.running;
  bool get isPaused => status == RestTimerStatus.paused;
  bool get isCompleted => status == RestTimerStatus.completed;
  bool get isVisible =>
      status == RestTimerStatus.running ||
      status == RestTimerStatus.paused ||
      status == RestTimerStatus.completed;

  double get progress =>
      totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0.0;

  String get formattedRemaining {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  RestTimerState copyWith({
    RestTimerStatus? status,
    int? remainingSeconds,
    int? totalSeconds,
    String? exerciseName,
    int? setNumber,
  }) {
    return RestTimerState(
      status: status ?? this.status,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      exerciseName: exerciseName ?? this.exerciseName,
      setNumber: setNumber ?? this.setNumber,
    );
  }
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  RestTimerNotifier() : super(const RestTimerState());

  Timer? _timer;
  Timer? _autoDismissTimer;

  void start(
    int seconds, {
    String? exerciseName,
    int? setNumber,
  }) {
    final effectiveSeconds =
        seconds > 0 ? seconds : AppConstants.defaultRestSeconds;
    _timer?.cancel();
    _autoDismissTimer?.cancel();
    state = RestTimerState(
      status: RestTimerStatus.running,
      remainingSeconds: effectiveSeconds,
      totalSeconds: effectiveSeconds,
      exerciseName: exerciseName,
      setNumber: setNumber,
    );
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _complete();
      }
    });
  }

  void _complete() {
    _timer?.cancel();
    _timer = null;
    _autoDismissTimer?.cancel();
    state = state.copyWith(
      status: RestTimerStatus.completed,
      remainingSeconds: 0,
    );
    _autoDismissTimer = Timer(const Duration(seconds: 4), stop);
  }

  void pause() {
    if (!state.isRunning) return;
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(status: RestTimerStatus.paused);
  }

  void resume() {
    if (!state.isPaused) return;
    state = state.copyWith(status: RestTimerStatus.running);
    _startTicker();
  }

  void togglePauseResume() {
    if (state.isRunning) {
      pause();
    } else if (state.isPaused) {
      resume();
    }
  }

  void addSeconds(int seconds) {
    if (!state.isRunning && !state.isPaused) return;
    final newRemaining = (state.remainingSeconds + seconds).clamp(1, 600).toInt();
    final newTotal = (state.totalSeconds + seconds)
        .clamp(math.max(1, newRemaining), 600)
        .toInt();
    state = state.copyWith(
      remainingSeconds: newRemaining,
      totalSeconds: newTotal,
    );
  }

  void dismissCompleted() {
    _timer?.cancel();
    _timer = null;
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    state = const RestTimerState(status: RestTimerStatus.dismissed);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    state = const RestTimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoDismissTimer?.cancel();
    super.dispose();
  }
}

final restTimerNotifierProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});

// --- Active Live Session Detail State ---

final liveSessionDetailProvider = FutureProvider.autoDispose
    .family<WorkoutSession, String>((ref, sessionId) async {
  final useCase = ref.watch(getWorkoutSessionByIdUseCaseProvider);
  final result = await useCase.execute(sessionId);

  return result.fold(
    (session) => session,
    (failure) => throw Exception(failure.message),
  );
});

/// Resolves the most recent working max weight per `exerciseId` from completed
/// sessions prior to [currentSessionId], used for automatic Execution Score / RPE.
final sessionPreviousWeightsProvider = FutureProvider.autoDispose
    .family<Map<String, double>, String>((ref, currentSessionId) async {
  final sessions = <WorkoutSession>[];

  try {
    final historyRepo = ref.watch(historyRepositoryProvider);
    final result = await historyRepo.getCompletedSessions(limit: 25);
    result.fold(
      sessions.addAll,
      (_) {},
    );
  } catch (_) {}

  try {
    final local = ref.watch(sessionLocalDataSourceProvider);
    if (local != null) {
      final cached = local
          .getAllCachedSessions()
          .where((s) => s.status == 'completed')
          .map((m) => m.toDomain());
      final seenIds = sessions.map((s) => s.id).toSet();
      for (final s in cached) {
        if (seenIds.add(s.id)) {
          sessions.add(s);
        }
      }
    }
  } catch (_) {}

  final completed = sessions
      .where((s) => s.id != currentSessionId && s.isCompleted)
      .toList()
    ..sort((a, b) {
      final aDate = a.completedAt ?? a.startedAt;
      final bDate = b.completedAt ?? b.startedAt;
      return bDate.compareTo(aDate);
    });

  final weightsByExercise = <String, double>{};
  for (final session in completed) {
    for (final se in session.exercises) {
      if (se.isCardio || weightsByExercise.containsKey(se.exerciseId)) {
        continue;
      }
      final workingWeights = se.sets
          .where((s) => s.isWorkingSet && s.weightKg > 0)
          .map((s) => s.weightKg);
      if (workingWeights.isEmpty) continue;
      final maxWeight = workingWeights.reduce(math.max);
      if (maxWeight > 0) {
        weightsByExercise[se.exerciseId] = maxWeight;
      }
    }
  }
  return weightsByExercise;
});
