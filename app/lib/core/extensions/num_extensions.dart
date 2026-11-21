import 'package:intl/intl.dart';

extension NumExtensions on num {
  String toWeight() {
    if (this == toInt()) {
      return '${toInt()} kg';
    }
    return '${toStringAsFixed(1)} kg';
  }

  String toReps() {
    return '${toInt()} rep';
  }

  String toPercentage() {
    return '${toInt()}%';
  }

  String toCalories() {
    final formatter = NumberFormat('#,##0', 'pt_BR');
    return '${formatter.format(this)} kcal';
  }

  String toMeasurement() {
    return '${toStringAsFixed(1)} cm';
  }
}
