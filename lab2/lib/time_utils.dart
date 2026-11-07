/// Допоміжні засоби для часу доби та дат.
library;

/// Кількість хвилин в одній годині.
const int minutesInHour = 60;

final RegExp _clockPattern = RegExp(r'^(?<hour>\d{1,2}):(?<minute>\d{2})$');

/// Перетворює [text] у форматі `ГГ:ХХ` на хвилини від півночі.
///
/// Повертає `null`, якщо формат або діапазон неправильні.
int? parseClock(String text) {
  final match = _clockPattern.firstMatch(text);
  if (match == null) return null;
  final hour = int.tryParse(match.namedGroup('hour') ?? '');
  final minute = int.tryParse(match.namedGroup('minute') ?? '');
  if (hour == null || minute == null) return null;
  if (hour > 23 || minute > 59) return null;
  return hour * minutesInHour + minute;
}

/// Форматування хвилин від півночі.
extension ClockString on int {
  /// Час у форматі `ГГ:ХХ`.
  String get asClock {
    final hours = (this ~/ minutesInHour).toString().padLeft(2, '0');
    final rest = (this % minutesInHour).toString().padLeft(2, '0');
    return '$hours:$rest';
  }
}

/// Форматування дат.
extension IsoDate on DateTime {
  /// Дата у форматі `РРРР-ММ-ДД`.
  String get asIsoDate => toIso8601String().split('T').first;
}
