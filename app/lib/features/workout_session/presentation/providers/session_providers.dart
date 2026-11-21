import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_remote_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/repositories/session_repository_impl.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
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

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final dataSource = ref.watch(sessionRemoteDataSourceProvider);
  return SessionRepositoryImpl(dataSource);
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

class RestTimerState {
  const RestTimerState({
    this.isRunning = false,
    this.remainingSeconds = 0,
    this.totalSeconds = 0,
    this.exerciseName,
    this.setNumber,
  });

  final bool isRunning;
  final int remainingSeconds;
  final int totalSeconds;
  final String? exerciseName;
  final int? setNumber;

  double get progress =>
      totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0.0;

  String get formattedRemaining {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  RestTimerState copyWith({
    bool? isRunning,
    int? remainingSeconds,
    int? totalSeconds,
    String? exerciseName,
    int? setNumber,
  }) {
    return RestTimerState(
      isRunning: isRunning ?? this.isRunning,
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

  void start(
    int seconds, {
    String? exerciseName,
    int? setNumber,
  }) {
    _timer?.cancel();
    state = RestTimerState(
      isRunning: true,
      remainingSeconds: seconds,
      totalSeconds: seconds,
      exerciseName: exerciseName,
      setNumber: setNumber,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        stop();
      }
    });
  }

  void addSeconds(int seconds) {
    if (!state.isRunning) return;
    final newRemaining = (state.remainingSeconds + seconds).clamp(1, 600);
    final newTotal = (state.totalSeconds + seconds).clamp(1, 600);
    state = state.copyWith(
      remainingSeconds: newRemaining,
      totalSeconds: newTotal,
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    state = const RestTimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
