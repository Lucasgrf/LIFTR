import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/nutrition/data/datasources/nutrition_remote_datasource.dart';
import 'package:personal_fitness_os/features/nutrition/data/repositories/nutrition_repository_impl.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';

final nutritionRemoteDataSourceProvider =
    Provider<NutritionRemoteDataSource>((ref) {
  return SupabaseNutritionRemoteDataSource(ref.watch(supabaseClientProvider));
});

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepositoryImpl(ref.watch(nutritionRemoteDataSourceProvider));
});
