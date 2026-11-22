import 'dart:convert';
import 'dart:io';

import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/features/training/domain/entities/ai_generated_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';

/// Lossless compact codec for sharing training plans across separate LIFTR accounts.
///
/// Format: `LIFTR-PLAN-V1:<base64Url(gzip(utf8(json)))>`
class TrainingPlanShareCodec {
  const TrainingPlanShareCodec._();

  static const String prefix = 'LIFTR-PLAN-V1:';
  static final RegExp _tokenPattern =
      RegExp(r'LIFTR-PLAN-V1:([A-Za-z0-9\-_=]+)');

  /// Encodes a [TrainingPlan] into a compact `LIFTR-PLAN-V1:...` share code.
  static String encode(TrainingPlan plan) {
    final workoutsPayload = plan.workouts.map((workout) {
      final exercisesPayload = workout.exercises.map((we) {
        final ex = we.exercise;
        final isCardio = we.isCardio;

        int? cardioDurationMin;
        if (isCardio && we.setTemplates.isNotEmpty) {
          final rawNotes = we.setTemplates.first.notes ?? '';
          final match = RegExp(r'(\d+)').firstMatch(rawNotes);
          if (match != null) {
            cardioDurationMin = int.tryParse(match.group(1)!);
          }
        }

        final exactSets = we.setTemplates.map((st) {
          return GeneratedSetSpec(
            setType: st.setType,
            targetRepsMin: st.targetRepsMin,
            targetRepsMax: st.targetRepsMax,
            targetRirMin: st.targetRirMin,
            targetRirMax: st.targetRirMax,
            targetWeight: st.targetWeight,
            restSeconds: st.restSeconds,
            notes: st.notes,
          ).toJson();
        }).toList();

        final firstWorking =
            we.setTemplates.where((s) => s.isWorkingSet).firstOrNull ??
                we.setTemplates.firstOrNull;

        return <String, dynamic>{
          'id': we.exerciseId,
          'nm': ex?.name ?? 'Exercício',
          if (ex?.primaryMuscleGroup != null) 'mg': ex!.primaryMuscleGroup,
          if (ex?.equipment != null) 'eq': ex!.equipment,
          if (ex?.movementPattern != null) 'mp': ex!.movementPattern,
          if (isCardio) 'cd': true,
          'sc': we.setTemplates.isNotEmpty ? we.setTemplates.length : 3,
          if (firstWorking?.targetRepsMin != null)
            'rmin': firstWorking!.targetRepsMin,
          if (firstWorking?.targetRepsMax != null)
            'rmax': firstWorking!.targetRepsMax,
          if (cardioDurationMin != null) 'dmin': cardioDurationMin,
          if (firstWorking?.targetRirMin != null)
            'imin': firstWorking!.targetRirMin,
          if (firstWorking?.targetRirMax != null)
            'imax': firstWorking!.targetRirMax,
          'rest': firstWorking?.restSeconds ??
              (isCardio ? 0 : AppConstants.defaultRestSeconds),
          if (we.notes != null && we.notes!.isNotEmpty) 'nt': we.notes,
          if (exactSets.isNotEmpty) 'st': exactSets,
        };
      }).toList();

      return <String, dynamic>{
        'nm': workout.name,
        if (workout.dayOfWeek != null) 'dw': workout.dayOfWeek,
        if (workout.estimatedDurationMinutes != null)
          'dur': workout.estimatedDurationMinutes,
        if (workout.notes != null && workout.notes!.isNotEmpty)
          'nt': workout.notes,
        'ex': exercisesPayload,
      };
    }).toList();

    final root = <String, dynamic>{
      'v': 1,
      'n': plan.name,
      if (plan.description != null && plan.description!.isNotEmpty)
        'd': plan.description,
      'w': workoutsPayload,
    };

    final jsonBytes = utf8.encode(jsonEncode(root));
    final compressed = gzip.encode(jsonBytes);
    return '$prefix${base64UrlEncode(compressed)}';
  }

  /// Builds a WhatsApp-friendly PT-BR message containing the share code.
  static String buildShareMessage(TrainingPlan plan) {
    final code = encode(plan);
    final sessionsCount = plan.workouts.length;
    return 'Treino "${plan.name}" ($sessionsCount sessões) no LIFTR.\n'
        'Abra o app → Treino → Trocar programa → Importar treino por código e cole:\n\n'
        '$code';
  }

  /// Decodes a `LIFTR-PLAN-V1:...` code (or a full message containing it)
  /// into a [GeneratedTrainingPlan] ready for preview and persistence.
  static GeneratedTrainingPlan decode(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Cole um código de treino para importar.');
    }

    final match = _tokenPattern.firstMatch(trimmed);
    if (match == null) {
      throw const FormatException(
        'Código inválido. Ele deve começar com LIFTR-PLAN-V1:.',
      );
    }

    final encodedPart = match.group(1)!;
    Map<String, dynamic> decodedMap;
    try {
      final normalized = base64Url.normalize(encodedPart);
      final compressedBytes = base64Url.decode(normalized);
      final jsonBytes = gzip.decode(compressedBytes);
      final rawJson = jsonDecode(utf8.decode(jsonBytes));
      if (rawJson is! Map) {
        throw const FormatException('Estrutura do código inválida.');
      }
      decodedMap = Map<String, dynamic>.from(rawJson);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'Não foi possível ler o código. Verifique se ele foi copiado por completo.',
      );
    }

    final version = (decodedMap['v'] as num?)?.toInt() ?? 0;
    if (version != 1) {
      throw FormatException('Versão de código não suportada (v$version).');
    }

    final planName = (decodedMap['n'] as String? ?? '').trim();
    if (planName.isEmpty) {
      throw const FormatException('O código não contém o nome do programa.');
    }

    final rawWorkouts = decodedMap['w'] as List<dynamic>? ?? const [];
    if (rawWorkouts.isEmpty) {
      throw const FormatException(
        'O programa compartilhado não possui sessões de treino.',
      );
    }

    final workouts = rawWorkouts.map((wItem) {
      final wMap = Map<String, dynamic>.from(wItem as Map);
      final rawExercises = wMap['ex'] as List<dynamic>? ?? const [];

      final exercises = rawExercises.map((eItem) {
        final eMap = Map<String, dynamic>.from(eItem as Map);
        final rawSets = eMap['st'] as List<dynamic>?;
        final exactSets = rawSets
            ?.map(
              (sItem) => GeneratedSetSpec.fromJson(
                Map<String, dynamic>.from(sItem as Map),
              ),
            )
            .toList();

        final isCardio = (eMap['cd'] as bool?) ??
            eMap['mp'] == 'cardio' ||
            eMap['mg'] == 'cardio';

        return GeneratedExerciseSpec(
          exerciseId: eMap['id'] as String?,
          exerciseName: (eMap['nm'] as String? ?? 'Exercício').trim(),
          primaryMuscleGroup: eMap['mg'] as String?,
          equipment: eMap['eq'] as String?,
          movementPattern: eMap['mp'] as String?,
          isCardio: isCardio,
          setsCount:
              exactSets?.length ?? (eMap['sc'] as num?)?.toInt() ?? 3,
          targetRepsMin: (eMap['rmin'] as num?)?.toInt(),
          targetRepsMax: (eMap['rmax'] as num?)?.toInt(),
          targetDurationMinutes: (eMap['dmin'] as num?)?.toInt(),
          targetRirMin: (eMap['imin'] as num?)?.toInt(),
          targetRirMax: (eMap['imax'] as num?)?.toInt(),
          restSeconds: (eMap['rest'] as num?)?.toInt() ??
              (isCardio ? 0 : AppConstants.defaultRestSeconds),
          notes: eMap['nt'] as String?,
          exactSets: exactSets,
        );
      }).toList();

      return GeneratedWorkoutSpec(
        name: (wMap['nm'] as String? ?? 'Sessão').trim(),
        dayOfWeek: (wMap['dw'] as num?)?.toInt(),
        estimatedDurationMinutes: (wMap['dur'] as num?)?.toInt() ?? 55,
        notes: wMap['nt'] as String?,
        exercises: exercises,
      );
    }).toList();

    return GeneratedTrainingPlan(
      planName: planName,
      splitType: '${workouts.length} sessões',
      description: decodedMap['d'] as String?,
      rationale: 'Programa importado via código de compartilhamento LIFTR.',
      workouts: workouts,
    );
  }
}
