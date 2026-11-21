import 'dart:convert';

import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';

/// DTO for `logged_sets` table in Supabase.
class LoggedSetModel {
  const LoggedSetModel({
    required this.id,
    required this.sessionExerciseId,
    required this.setNumber,
    this.setType = 'working',
    required this.weightKg,
    required this.repsCompleted,
    this.rirActual,
    this.rpeActual,
    this.restSecondsActual,
    this.executionQuality,
    this.isWarmup = false,
    this.notes,
    this.dropSets = const [],
    this.completedAt,
  });

  static const String dropMarkerPrefix = '__DROPS__:';

  final String id;
  final String sessionExerciseId;
  final int setNumber;
  final String setType;
  final double weightKg;
  final int repsCompleted;
  final int? rirActual;
  final double? rpeActual;
  final int? restSecondsActual;
  final String? executionQuality;
  final bool isWarmup;
  final String? notes;
  final List<DropSetEntry> dropSets;
  final DateTime? completedAt;

  static ({String? cleanNotes, List<DropSetEntry> drops}) extractDropsFromNotes(
    String? rawNotes,
  ) {
    if (rawNotes == null || rawNotes.isEmpty) {
      return (cleanNotes: rawNotes, drops: const []);
    }
    final markerIdx = rawNotes.indexOf(dropMarkerPrefix);
    if (markerIdx == -1) {
      return (cleanNotes: rawNotes, drops: const []);
    }
    final before = rawNotes.substring(0, markerIdx).trimRight();
    final afterMarker = rawNotes.substring(markerIdx + dropMarkerPrefix.length);
    final newlineIdx = afterMarker.indexOf('\n');
    final jsonPart =
        (newlineIdx == -1 ? afterMarker : afterMarker.substring(0, newlineIdx))
            .trim();
    final trailing =
        newlineIdx == -1 ? '' : afterMarker.substring(newlineIdx + 1).trim();
    final combinedClean = [
      if (before.isNotEmpty) before,
      if (trailing.isNotEmpty) trailing,
    ].join('\n');

    try {
      final decoded = jsonDecode(jsonPart);
      if (decoded is List) {
        final drops = decoded
            .whereType<Map>()
            .map((e) => DropSetEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return (
          cleanNotes: combinedClean.isEmpty ? null : combinedClean,
          drops: drops,
        );
      }
    } catch (_) {}
    return (cleanNotes: rawNotes, drops: const []);
  }

  static String? attachDropsMarkerToNotes(
    String? cleanNotes,
    List<DropSetEntry> drops,
  ) {
    final trimmed = cleanNotes?.trim();
    if (drops.isEmpty) {
      return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    }
    final encoded = jsonEncode(drops.map((d) => d.toJson()).toList());
    if (trimmed == null || trimmed.isEmpty) {
      return '$dropMarkerPrefix$encoded';
    }
    return '$trimmed\n$dropMarkerPrefix$encoded';
  }

  static List<DropSetEntry> _parseDropSets(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => DropSetEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  factory LoggedSetModel.fromJson(Map<String, dynamic> json) {
    final columnDrops = _parseDropSets(json['drop_sets']);
    final notesParsed = extractDropsFromNotes(json['notes'] as String?);
    final resolvedDrops =
        columnDrops.isNotEmpty ? columnDrops : notesParsed.drops;

    return LoggedSetModel(
      id: json['id'] as String,
      sessionExerciseId: json['session_exercise_id'] as String,
      setNumber: json['set_number'] as int? ?? 1,
      setType: json['set_type'] as String? ?? 'working',
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      repsCompleted: json['reps_completed'] as int? ?? 0,
      rirActual: json['rir_actual'] as int?,
      rpeActual: (json['rpe_actual'] as num?)?.toDouble(),
      restSecondsActual: json['rest_seconds_actual'] as int?,
      executionQuality: json['execution_quality'] as String?,
      isWarmup: json['is_warmup'] as bool? ?? false,
      notes: notesParsed.cleanNotes,
      dropSets: resolvedDrops,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_exercise_id': sessionExerciseId,
      'set_number': setNumber,
      'set_type': setType,
      'weight_kg': weightKg,
      'reps_completed': repsCompleted,
      if (rirActual != null) 'rir_actual': rirActual,
      if (rpeActual != null) 'rpe_actual': rpeActual,
      if (restSecondsActual != null) 'rest_seconds_actual': restSecondsActual,
      if (executionQuality != null) 'execution_quality': executionQuality,
      'is_warmup': isWarmup,
      if (notes != null) 'notes': notes,
      if (dropSets.isNotEmpty)
        'drop_sets': dropSets.map((d) => d.toJson()).toList(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    };
  }

  static SetType parseSetType(String raw) {
    switch (raw.toLowerCase()) {
      case 'mobility':
        return SetType.mobility;
      case 'warmup':
        return SetType.warmup;
      case 'ramp_up':
      case 'rampup':
        return SetType.rampUp;
      case 'working':
        return SetType.working;
      case 'drop_set':
      case 'dropset':
        return SetType.dropSet;
      case 'myo_rep':
      case 'myorep':
        return SetType.myoRep;
      default:
        return SetType.working;
    }
  }

  static String setTypeToString(SetType type) {
    switch (type) {
      case SetType.mobility:
        return 'mobility';
      case SetType.warmup:
        return 'warmup';
      case SetType.rampUp:
        return 'ramp_up';
      case SetType.working:
        return 'working';
      case SetType.dropSet:
        return 'drop_set';
      case SetType.myoRep:
        return 'myo_rep';
    }
  }

  static ExecutionQuality? parseExecutionQuality(String? raw) {
    if (raw == null) return null;
    switch (raw.toLowerCase()) {
      case 'poor':
        return ExecutionQuality.poor;
      case 'fair':
      case 'acceptable':
        return ExecutionQuality.fair;
      case 'good':
        return ExecutionQuality.good;
      case 'excellent':
      case 'perfect':
        return ExecutionQuality.excellent;
      default:
        return null;
    }
  }

  static String? executionQualityToString(ExecutionQuality? quality) {
    if (quality == null) return null;
    return quality.name;
  }

  LoggedSet toDomain() {
    return LoggedSet(
      id: id,
      sessionExerciseId: sessionExerciseId,
      setNumber: setNumber,
      setType: parseSetType(setType),
      weightKg: weightKg,
      repsCompleted: repsCompleted,
      rirActual: rirActual,
      rpeActual: rpeActual,
      restSecondsActual: restSecondsActual,
      executionQuality: parseExecutionQuality(executionQuality),
      isWarmup: isWarmup,
      notes: notes,
      dropSets: dropSets,
      completedAt: completedAt,
    );
  }

  factory LoggedSetModel.fromDomain(LoggedSet entity) {
    return LoggedSetModel(
      id: entity.id,
      sessionExerciseId: entity.sessionExerciseId,
      setNumber: entity.setNumber,
      setType: setTypeToString(entity.setType),
      weightKg: entity.weightKg,
      repsCompleted: entity.repsCompleted,
      rirActual: entity.rirActual,
      rpeActual: entity.rpeActual,
      restSecondsActual: entity.restSecondsActual,
      executionQuality: executionQualityToString(entity.executionQuality),
      isWarmup: entity.isWarmup,
      notes: entity.notes,
      dropSets: entity.dropSets,
      completedAt: entity.completedAt,
    );
  }

  LoggedSetModel copyWith({
    String? id,
    String? sessionExerciseId,
    int? setNumber,
    String? setType,
    double? weightKg,
    int? repsCompleted,
    int? rirActual,
    double? rpeActual,
    int? restSecondsActual,
    String? executionQuality,
    bool? isWarmup,
    String? notes,
    List<DropSetEntry>? dropSets,
    DateTime? completedAt,
  }) {
    return LoggedSetModel(
      id: id ?? this.id,
      sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
      setNumber: setNumber ?? this.setNumber,
      setType: setType ?? this.setType,
      weightKg: weightKg ?? this.weightKg,
      repsCompleted: repsCompleted ?? this.repsCompleted,
      rirActual: rirActual ?? this.rirActual,
      rpeActual: rpeActual ?? this.rpeActual,
      restSecondsActual: restSecondsActual ?? this.restSecondsActual,
      executionQuality: executionQuality ?? this.executionQuality,
      isWarmup: isWarmup ?? this.isWarmup,
      notes: notes ?? this.notes,
      dropSets: dropSets ?? this.dropSets,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
