import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/training/data/datasources/ai_workout_remote_datasource.dart';
import 'package:personal_fitness_os/features/training/domain/services/plan_persister_service.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';

final aiWorkoutRemoteDataSourceProvider =
    Provider<AiWorkoutRemoteDataSource>((ref) {
  return const SupabaseAiWorkoutRemoteDataSource();
});

final planPersisterServiceProvider = Provider<PlanPersisterService>((ref) {
  return PlanPersisterService(
    trainingRepository: ref.watch(trainingRepositoryProvider),
    exerciseRepository: ref.watch(exerciseRepositoryProvider),
  );
});
