import 'package:intl/intl.dart';

extension DateExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  DateTime get startOfDay => DateTime(year, month, day);
  
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
  
  DateTime get startOfWeek {
    final daysToSubtract = weekday - 1;
    return subtract(Duration(days: daysToSubtract)).startOfDay;
  }
  
  DateTime get endOfWeek {
    final daysToAdd = 7 - weekday;
    return add(Duration(days: daysToAdd)).endOfDay;
  }

  String formatShort() {
    return DateFormat('dd/MM', 'pt_BR').format(this);
  }

  String formatMedium() {
    return DateFormat('dd MMM yyyy', 'pt_BR').format(this);
  }

  String formatFull() {
    return DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(this);
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  int daysAgo() {
    final now = DateTime.now().startOfDay;
    final date = startOfDay;
    return now.difference(date).inDays;
  }

  int daysFromNow() {
    final now = DateTime.now().startOfDay;
    final date = startOfDay;
    return date.difference(now).inDays;
  }
}
