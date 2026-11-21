import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/history/domain/entities/history_event_type.dart';
import 'package:personal_fitness_os/features/history/domain/entities/timeline_event.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';

class GetUnifiedTimelineUseCase {
  const GetUnifiedTimelineUseCase(this._repository);

  final HistoryRepository _repository;

  Future<Result<List<TimelineEvent>, Failure>> execute({
    HistoryEventType? type,
    DateTime? start,
    DateTime? end,
    int limit = 50,
  }) {
    if (limit <= 0) {
      return Future.value(
        const Err(ValidationFailure('Limite de eventos deve ser maior que zero.')),
      );
    }
    return _repository.getUnifiedTimeline(
      type: type,
      start: start,
      end: end,
      limit: limit,
    );
  }
}
