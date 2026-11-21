import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';

enum WeightTrend {
  gaining,
  losing,
  maintaining,
  unknown,
}

/// Pure Domain Entity representing aggregated weight statistics and moving averages.
class WeightStats {
  const WeightStats({
    this.latestEntry,
    this.average7Days,
    this.average14Days,
    this.average30Days,
    this.trend = WeightTrend.unknown,
    this.deltaVsPreviousWeekKg,
  });

  final WeightEntry? latestEntry;
  final double? average7Days;
  final double? average14Days;
  final double? average30Days;
  final WeightTrend trend;
  final double? deltaVsPreviousWeekKg;

  double? get currentWeightKg => latestEntry?.weightKg;

  String get trendLabel {
    switch (trend) {
      case WeightTrend.gaining:
        return 'Em alta ↗';
      case WeightTrend.losing:
        return 'Em queda ↘';
      case WeightTrend.maintaining:
        return 'Estável →';
      case WeightTrend.unknown:
        return 'Dados insuficientes';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeightStats &&
        other.latestEntry == latestEntry &&
        other.average7Days == average7Days &&
        other.average14Days == average14Days &&
        other.average30Days == average30Days &&
        other.trend == trend &&
        other.deltaVsPreviousWeekKg == deltaVsPreviousWeekKg;
  }

  @override
  int get hashCode => Object.hash(
        latestEntry,
        average7Days,
        average14Days,
        average30Days,
        trend,
        deltaVsPreviousWeekKg,
      );
}
