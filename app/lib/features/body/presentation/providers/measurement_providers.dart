import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/body/data/datasources/measurement_remote_datasource.dart';
import 'package:personal_fitness_os/features/body/data/repositories/measurement_repository_impl.dart';
import 'package:personal_fitness_os/features/body/domain/entities/body_measurement.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/measurement_repository.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/delete_measurement.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/get_latest_measurement.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/get_measurements.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/log_measurement.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Data Sources & Repositories ---

final measurementRemoteDataSourceProvider = Provider<MeasurementRemoteDataSource>((ref) {
  return SupabaseMeasurementRemoteDataSource(Supabase.instance.client);
});

final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  return MeasurementRepositoryImpl(ref.watch(measurementRemoteDataSourceProvider));
});

// --- Use Cases ---

final getMeasurementsUseCaseProvider = Provider<GetMeasurementsUseCase>((ref) {
  return GetMeasurementsUseCase(ref.watch(measurementRepositoryProvider));
});

final getLatestMeasurementUseCaseProvider = Provider<GetLatestMeasurementUseCase>((ref) {
  return GetLatestMeasurementUseCase(ref.watch(measurementRepositoryProvider));
});

final logMeasurementUseCaseProvider = Provider<LogMeasurementUseCase>((ref) {
  return LogMeasurementUseCase(ref.watch(measurementRepositoryProvider));
});

final deleteMeasurementUseCaseProvider = Provider<DeleteMeasurementUseCase>((ref) {
  return DeleteMeasurementUseCase(ref.watch(measurementRepositoryProvider));
});

// --- State Providers ---

final measurementsListProvider = FutureProvider.autoDispose<List<BodyMeasurement>>((ref) async {
  final useCase = ref.watch(getMeasurementsUseCaseProvider);
  final result = await useCase.execute();

  return result.fold(
    (list) => list,
    (failure) => throw Exception(failure.message),
  );
});

final latestMeasurementProvider = FutureProvider.autoDispose<BodyMeasurement?>((ref) async {
  final useCase = ref.watch(getLatestMeasurementUseCaseProvider);
  final result = await useCase.execute();

  return result.fold(
    (item) => item,
    (failure) => throw Exception(failure.message),
  );
});
