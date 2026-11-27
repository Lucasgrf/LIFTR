import 'package:flutter/material.dart';

/// A single domain-agnostic data point plotted in a LIFTR chart.
@immutable
class ChartPoint {
  const ChartPoint({
    required this.date,
    required this.value,
    this.label,
    this.secondaryValue,
  });

  final DateTime date;
  final double value;
  final String? label;
  final double? secondaryValue;
}

/// A domain-agnostic plotted series rendered by core chart widgets.
@immutable
class ChartSeries {
  const ChartSeries({
    required this.id,
    required this.label,
    required this.points,
    required this.color,
    this.isDashed = false,
    this.unit = 'kg',
    this.showArea = false,
  });

  final String id;
  final String label;
  final List<ChartPoint> points;
  final Color color;
  final bool isDashed;
  final String unit;
  final bool showArea;
}
