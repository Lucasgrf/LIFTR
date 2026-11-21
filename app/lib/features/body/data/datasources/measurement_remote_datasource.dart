import 'package:personal_fitness_os/features/body/data/models/body_measurement_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MeasurementRemoteDataSource {
  Future<List<BodyMeasurementModel>> fetchMeasurements({int limit = 50});
  Future<BodyMeasurementModel?> fetchLatestMeasurement();
  Future<BodyMeasurementModel> insertMeasurement(BodyMeasurementModel model);
  Future<void> deleteMeasurement(String id);
}

class SupabaseMeasurementRemoteDataSource implements MeasurementRemoteDataSource {
  const SupabaseMeasurementRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<BodyMeasurementModel>> fetchMeasurements({int limit = 50}) async {
    final response = await _client
        .from('body_measurements')
        .select()
        .order('measured_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => BodyMeasurementModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BodyMeasurementModel?> fetchLatestMeasurement() async {
    final response = await _client
        .from('body_measurements')
        .select()
        .order('measured_at', ascending: false)
        .limit(1);

    final list = response as List;
    if (list.isEmpty) return null;
    return BodyMeasurementModel.fromJson(list.first as Map<String, dynamic>);
  }

  @override
  Future<BodyMeasurementModel> insertMeasurement(BodyMeasurementModel model) async {
    final data = model.toJson();
    if (data['id'] == '' || data['id'] == null) {
      data.remove('id');
    }

    final response = await _client
        .from('body_measurements')
        .insert(data)
        .select()
        .single();

    return BodyMeasurementModel.fromJson(response);
  }

  @override
  Future<void> deleteMeasurement(String id) async {
    await _client.from('body_measurements').delete().eq('id', id);
  }
}
