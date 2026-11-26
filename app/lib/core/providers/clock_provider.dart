import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable clock callback used by time-sensitive UI widgets so tests and
/// golden snapshots can freeze the current timestamp without touching runtime
/// behavior in production.
final appClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
