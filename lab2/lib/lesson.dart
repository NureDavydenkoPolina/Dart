/// Заняття розкладу: версія з класичним конструктором (для порівняння).
library;

import 'package:lab2/entity.dart';
import 'package:lab2/lesson_type.dart';
import 'package:lab2/time_utils.dart';
import 'package:lab2/weekday.dart';

/// Роздільник полів у рядку CSV.
const String fieldSeparator = ';';

/// Кількість полів у правильному рядку.
const int fieldCount = 7;

/// Тривалість одного заняття (пари) у хвилинах.
const int lessonDurationMinutes = 90;

/// Найраніший допустимий початок заняття (08:00) у хвилинах від півночі.
const int earliestStartMinutes = 8 * minutesInHour;

/// Найпізніший допустимий початок заняття (19:00) у хвилинах від півночі.
const int latestStartMinutes = 19 * minutesInHour;

/// Заняття: дисципліна, викладач, тип, день, початок, аудиторія, дата запису.
///
/// Об’єкт незмінний: усі поля `final`. Початок зберігається в хвилинах
/// від півночі.
class Lesson extends Entity with Printable {
  /// Створює заняття.
  const Lesson(
    this.subject,
    this.teacher,
    this.type,
    this.day,
    this.startMinutes,
    this.room,
    this.addedOn,
  );

  final String subject;

  final String teacher;

  final LessonType type;

  final Weekday day;

  final int startMinutes;

  final String room;

  final DateTime addedOn;

  static final Map<String, Lesson> _cache = {};

  /// Розбирає рядок CSV у заняття.
  ///
  /// Кидає [FormatException], якщо рядок пошкоджений.
  factory Lesson.fromCsv(String line) {
    final fields = line.split(fieldSeparator).map((f) => f.trim()).toList();
    if (fields.length != fieldCount) {
      throw FormatException(
        'очікувалось $fieldCount полів, знайдено ${fields.length}',
      );
    }
    final [subject, teacher, typeText, dayText, timeText, room, dateText] =
        fields;
    if (subject.isEmpty || teacher.isEmpty || room.isEmpty) {
      throw const FormatException('порожнє обов’язкове поле');
    }
    final day = Weekday.tryParse(dayText);
    if (day == null) {
      throw FormatException('невідомий день «$dayText»');
    }
    final start = parseClock(timeText);
    if (start == null) {
      throw FormatException('час «$timeText» не схожий на ГГ:ХХ');
    }
    final addedOn = DateTime.tryParse(dateText);
    // tryParse переносить надлишок (2026-13-45 стає 2027-02-14),
    // тому порівнюємо відформатовану дату з вхідним рядком.
    if (addedOn == null || addedOn.asIsoDate != dateText) {
      throw FormatException('некоректна дата «$dateText»');
    }
    return Lesson(
      subject,
      teacher,
      LessonType.parse(typeText),
      day,
      start,
      room,
      addedOn,
    );
  }

  /// Те саме, що [Lesson.fromCsv], але для однакового рядка повертає
  /// вже створений об’єкт.
  factory Lesson.cached(String line) =>
      _cache.putIfAbsent(line.trim(), () => Lesson.fromCsv(line));

  @override
  String get id => '${day.name}-${startMinutes.asClock}-$room';

  /// Тривалість заняття в хвилинах.
  int get durationMinutes => lessonDurationMinutes;

  /// Час закінчення в хвилинах від півночі.
  int get endMinutes => startMinutes + durationMinutes;

  /// Проміжок часу у форматі `ГГ:ХХ–ГГ:ХХ`.
  String get timeRange => '${startMinutes.asClock}–${endMinutes.asClock}';

  /// Перевіряє значення й повертає список порушень.
  ///
  /// Порожній список означає, що заняття коректне. Дата [now] потрібна,
  /// щоб відсікти дати з майбутнього.
  List<String> validate({required DateTime now}) => [
    if (startMinutes < earliestStartMinutes ||
        startMinutes > latestStartMinutes)
      'початок ${startMinutes.asClock} поза межами '
          '${earliestStartMinutes.asClock}–${latestStartMinutes.asClock}',
    if (addedOn.isAfter(now)) 'дата запису ${addedOn.asIsoDate} у майбутньому',
  ];

  /// Вік запису в днях відносно [now].
  int ageInDays({required DateTime now}) => now.difference(addedOn).inDays;

  @override
  bool operator ==(Object other) =>
      other is Lesson &&
      other.subject == subject &&
      other.teacher == teacher &&
      other.type == type &&
      other.day == day &&
      other.startMinutes == startMinutes &&
      other.room == room &&
      other.addedOn == addedOn;

  @override
  int get hashCode =>
      Object.hash(subject, teacher, type, day, startMinutes, room, addedOn);

  @override
  String toString() =>
      '${day.label} $timeRange · ${type.label} · $subject · $room';
}
