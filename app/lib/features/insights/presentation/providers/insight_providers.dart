import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/insights/domain/entities/fitness_insight.dart';
import 'package:personal_fitness_os/features/insights/domain/usecases/generate_insights.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/providers/nutrition_providers.dart';

final generateInsightsUseCaseProvider = Provider<GenerateInsightsUseCase>((ref) {
  return GenerateInsightsUseCase(
    historyRepository: ref.watch(historyRepositoryProvider),
    weightRepository: ref.watch(weightRepositoryProvider),
    nutritionRepository: ref.watch(nutritionRepositoryProvider),
  );
});

final fitnessInsightsProvider = FutureProvider.autoDispose<List<FitnessInsight>>((ref) async {
  final useCase = ref.watch(generateInsightsUseCaseProvider);
  final result = await useCase.execute();

  return result.fold(
    (insights) => insights,
    (failure) => throw Exception(failure.message),
  );
});
