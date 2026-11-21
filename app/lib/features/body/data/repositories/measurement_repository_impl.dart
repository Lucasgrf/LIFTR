import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/data/datasources/measurement_remote_datasource.dart';
import 'package:personal_fitness_os/features/body/data/models/body_measurement_model.dart';
import 'package:personal_fitness_os/features/body/domain/entities/body_measurement.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/measurement_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MeasurementRepositoryImpl implements MeasurementRepository {
  const MeasurementRepositoryImpl(this._remoteDataSource);

  final MeasurementRemoteDataSource _remoteDataSource;

  Future<Result<T, Failure>> _guard<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      return Success(result);
    } on AuthException catch (e, st) {
      return Err(AuthFailure(e.message, st));
    } on PostgrestException catch (e, st) {
      return Err(ServerFailure(e.message, st));
    } catch (e, st) {
      return Err(UnexpectedFailure(e.toString(), st));
    }
  }

  @override
  Future<Result<List<BodyMeasurement>, Failure>> getMeasurements({
    int limit = 50,
  }) {
    return _guard(() async {
      final models = await _remoteDataSource.fetchMeasurements(limit: limit);
      return models.map((m) => m.toDomain()).toList();
    });
  }

  @override
  Future<Result<BodyMeasurement?, Failure>> getLatestMeasurement() {
    return _guard(() async {
      final model = await _remoteDataSource.fetchLatestMeasurement();
      return model?.toDomain();
    });
  }

  @override
  Future<Result<BodyMeasurement, Failure>> logMeasurement(
    BodyMeasurement measurement,
  ) {
    return _guard(() async {
      final model = BodyMeasurementModel.fromDomain(measurement);
      final inserted = await _remoteDataSource.insertMeasurement(model);
      return inserted.toDomain();
    });
  }

  @override
  Future<Result<void, Failure>> deleteMeasurement(String id) {
    return _guard(() async {
      await _remoteDataSource.deleteMeasurement(id);
    });
  }
}
