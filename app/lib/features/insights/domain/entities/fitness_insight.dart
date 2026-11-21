import 'package:flutter/foundation.dart';

enum InsightCategory {
  volume,
  fatigue,
  plateau,
  nutrition,
  consistency,
}

enum InsightSeverity {
  info,
  success,
  warning,
  alert,
}

/// Pure Domain Entity representing an automated, deterministic training or nutrition insight.
@immutable
class FitnessInsight {
  const FitnessInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    this.actionLabel,
    this.actionRoute,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final InsightCategory category;
  final InsightSeverity severity;
  final String? actionLabel;
  final String? actionRoute;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FitnessInsight &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.severity == severity;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        category,
        severity,
      );
}
