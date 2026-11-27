import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/widgets/charts/chart_models.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';

/// Maps feature [ExerciseHistoryRecord] entries to domain-agnostic [ChartSeries]
/// (`Carga máx` + `1RM est`) for rendering by core chart widgets.
List<ChartSeries> mapExerciseHistoryToLoadSeries(
  List<ExerciseHistoryRecord> records, {
  required Color loadColor,
  required Color e1rmColor,
}) {
  if (records.isEmpty) return const [];

  final ordered = [...records]..sort((a, b) => a.date.compareTo(b.date));

  String formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  return [
    ChartSeries(
      id: 'max_load',
      label: 'Carga máx',
      color: loadColor,
      showArea: true,
      points: ordered
          .map(
            (r) => ChartPoint(
              date: r.date,
              value: r.topWeightKg,
              label: formatDate(r.date),
              secondaryValue: r.topReps.toDouble(),
            ),
          )
          .toList(growable: false),
    ),
    ChartSeries(
      id: 'e1rm',
      label: '1RM est',
      color: e1rmColor,
      isDashed: true,
      points: ordered
          .map(
            (r) => ChartPoint(
              date: r.date,
              value: r.bestEstimated1Rm,
              label: formatDate(r.date),
              secondaryValue: r.topReps.toDouble(),
            ),
          )
          .toList(growable: false),
    ),
  ];
}
