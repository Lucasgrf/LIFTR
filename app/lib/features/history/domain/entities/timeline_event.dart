import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/history/domain/entities/history_event_type.dart';

/// Pure Domain Entity representing any chronological event in the user's fitness timeline.
@immutable
class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.title,
    required this.subtitle,
    required this.referenceId,
    this.metadata = const {},
  });

  final String id;
  final HistoryEventType type;
  final DateTime timestamp;
  final String title;
  final String subtitle;
  final String referenceId;
  final Map<String, dynamic> metadata;

  TimelineEvent copyWith({
    String? id,
    HistoryEventType? type,
    DateTime? timestamp,
    String? title,
    String? subtitle,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      referenceId: referenceId ?? this.referenceId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimelineEvent &&
        other.id == id &&
        other.type == type &&
        other.timestamp == timestamp &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.referenceId == referenceId &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode => Object.hash(
        id,
        type,
        timestamp,
        title,
        subtitle,
        referenceId,
        Object.hashAll(metadata.entries),
      );
}
