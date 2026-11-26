import 'dart:convert';
import 'dart:io';

import 'package:personal_fitness_os/core/constants/supabase_config.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/features/training/domain/entities/ai_generated_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/ai_workout_request.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AiWorkoutErrorCode {
  keyNotConfigured,
  functionNotDeployed,
  unauthorized,
  network,
  invalidResponse,
  unknown,
}

class AiWorkoutException implements Exception {
  const AiWorkoutException({
    required this.code,
    required this.message,
  });

  final AiWorkoutErrorCode code;
  final String message;

  @override
  String toString() => message;
}

abstract class AiWorkoutRemoteDataSource {
  Future<GeneratedTrainingPlan> generatePlan(AiWorkoutRequest request);
}

class SupabaseAiWorkoutRemoteDataSource implements AiWorkoutRemoteDataSource {
  const SupabaseAiWorkoutRemoteDataSource([this._client]);

  final SupabaseClient? _client;

  SupabaseClient _resolveClient() {
    final client = _client;
    if (client != null) return client;
    if (!SupabaseConfig.isConfigured) {
      throw const AiWorkoutException(
        code: AiWorkoutErrorCode.network,
        message:
            'Conexão com o Supabase não configurada neste ambiente. Conecte sua conta para usar o gerador com IA.',
      );
    }
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw const AiWorkoutException(
        code: AiWorkoutErrorCode.network,
        message: 'Serviço do Supabase ainda não inicializado.',
      );
    }
  }

  @override
  Future<GeneratedTrainingPlan> generatePlan(AiWorkoutRequest request) async {
    final client = _resolveClient();

    try {
      final response = await client.functions.invoke(
        'generate-workout-plan',
        body: request.toJson(),
      );

      final rawData = response.data;
      final Map<String, dynamic> dataMap;
      if (rawData is Map<String, dynamic>) {
        dataMap = rawData;
      } else if (rawData is Map) {
        dataMap = Map<String, dynamic>.from(rawData);
      } else if (rawData is String && rawData.trim().isNotEmpty) {
        final decoded = jsonDecode(rawData);
        if (decoded is! Map) {
          throw const AiWorkoutException(
            code: AiWorkoutErrorCode.invalidResponse,
            message: 'A IA retornou uma resposta em formato inesperado.',
          );
        }
        dataMap = Map<String, dynamic>.from(decoded);
      } else {
        throw const AiWorkoutException(
          code: AiWorkoutErrorCode.invalidResponse,
          message: 'Resposta vazia recebida do gerador de treinos.',
        );
      }

      final planMap = dataMap['plan'];
      if (planMap is! Map) {
        throw const AiWorkoutException(
          code: AiWorkoutErrorCode.invalidResponse,
          message: 'O plano gerado não pôde ser interpretado.',
        );
      }

      final plan = GeneratedTrainingPlan.fromJson(
        Map<String, dynamic>.from(planMap),
      );
      if (plan.workouts.isEmpty) {
        throw const AiWorkoutException(
          code: AiWorkoutErrorCode.invalidResponse,
          message: 'A IA não retornou sessões válidas. Tente gerar novamente.',
        );
      }
      return plan;
    } on AiWorkoutException {
      rethrow;
    } on FunctionException catch (e) {
      throw _mapFunctionException(e);
    } on SocketException {
      throw const AiWorkoutException(
        code: AiWorkoutErrorCode.network,
        message:
            'Sem conexão com a internet. Verifique sua rede e tente novamente.',
      );
    } catch (e) {
      throw AiWorkoutException(
        code: AiWorkoutErrorCode.unknown,
        message: userFacingMessage(e),
      );
    }
  }

  AiWorkoutException _mapFunctionException(FunctionException e) {
    String? errorCode;
    String? serverMessage;
    final details = e.details;
    if (details is Map) {
      errorCode = details['error']?.toString();
      serverMessage = details['message']?.toString();
    } else if (details is String && details.trim().startsWith('{')) {
      try {
        final parsed = jsonDecode(details);
        if (parsed is Map) {
          errorCode = parsed['error']?.toString();
          serverMessage = parsed['message']?.toString();
        }
      } catch (_) {}
    }

    if (e.status == 503 || errorCode == 'GEMINI_KEY_NOT_CONFIGURED') {
      return const AiWorkoutException(
        code: AiWorkoutErrorCode.keyNotConfigured,
        message:
            'A chave GEMINI_API_KEY ainda não foi configurada no Supabase (secrets da Edge Function). Configure a chave para liberar a geração com o Gemini.',
      );
    }

    if (e.status == 404) {
      return const AiWorkoutException(
        code: AiWorkoutErrorCode.functionNotDeployed,
        message:
            'A Edge Function "generate-workout-plan" ainda não foi publicada no Supabase. Faça o deploy da função para usar o gerador com IA.',
      );
    }

    if (e.status == 401 || errorCode == 'UNAUTHORIZED') {
      return const AiWorkoutException(
        code: AiWorkoutErrorCode.unauthorized,
        message:
            'Sua sessão expirou ou você não está autenticado. Entre na sua conta novamente.',
      );
    }

    return AiWorkoutException(
      code: AiWorkoutErrorCode.unknown,
      message: serverMessage?.trim().isNotEmpty == true
          ? serverMessage!
          : 'Erro ao consultar o Gemini (HTTP ${e.status}). Tente novamente.',
    );
  }
}
