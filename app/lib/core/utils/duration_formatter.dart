const List<String> _ptBrShortMonths = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

/// Formats a duration in seconds into concise minutes or hours + minutes
/// (`0 min`, `45 min`, `1h`, `1h 15m`).
String formatCardioSeconds(int totalSeconds) {
  if (totalSeconds <= 0) return '0 min';
  final totalMinutes = (totalSeconds / 60).round();
  if (totalMinutes <= 0) return '0 min';
  if (totalMinutes < 60) return '$totalMinutes min';
  final hours = totalMinutes ~/ 60;
  final mins = totalMinutes % 60;
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}

/// Formats a signed duration delta in seconds (`Igual`, `+15 min`, `-10 min`, `+1h 15m`).
String formatCardioDeltaSeconds(int deltaSeconds) {
  final deltaMinutes = (deltaSeconds / 60).round();
  if (deltaMinutes == 0) return 'Igual';
  final prefix = deltaMinutes > 0 ? '+' : '-';
  return '$prefix${formatCardioSeconds(deltaMinutes.abs() * 60)}';
}

/// Returns Monday 00:00:00.000 of the ISO week containing [dt].
DateTime isoWeekStart(DateTime dt) {
  final date = DateTime(dt.year, dt.month, dt.day);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}

/// Returns Sunday 23:59:59.999 of the ISO week starting at [weekStart].
DateTime isoWeekEnd(DateTime weekStart) {
  return DateTime(
    weekStart.year,
    weekStart.month,
    weekStart.day + 6,
    23,
    59,
    59,
    999,
  );
}

/// Returns `YYYY-MM-DD` for the calendar date of [dt].
String isoDateKey(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Formats a Monday–Sunday week interval in PT-BR (`16–22 nov` or `30 nov–6 dez`).
String formatWeekRange(DateTime weekStart) {
  final start = isoWeekStart(weekStart);
  final end = DateTime(start.year, start.month, start.day + 6);
  final startMonth = _ptBrShortMonths[start.month - 1];
  final endMonth = _ptBrShortMonths[end.month - 1];
  if (start.month == end.month) {
    return '${start.day}–${end.day} $endMonth';
  }
  return '${start.day} $startMonth–${end.day} $endMonth';
}
