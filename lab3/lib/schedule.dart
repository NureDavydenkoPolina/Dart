/// Завантаження й агрегація розкладу з об’єктами [Lesson].
library;

import 'lesson.dart';
import 'lesson_extensions.dart';
import 'time_utils.dart';
import 'weekday.dart';

/// Статистика за один день: кількість занять і сумарна тривалість.
typedef DayStats = ({int count, int minutes});

/// Результат завантаження: коректні заняття та список проблем.
typedef LoadResult = ({List<Lesson> lessons, List<String> problems});

/// Розбирає й перевіряє всі [lines].
///
/// Некоректні рядки не зупиняють роботу: їх опис потрапляє в `problems`.
LoadResult loadLessons(List<String> lines, {required DateTime now}) {
  final lessons = <Lesson>[];
  final problems = <String>[];
  for (final (index, line) in lines.indexed) {
    try {
      final lesson = Lesson.cached(line);
      final violations = lesson.validate(now: now);
      if (violations.isEmpty) {
        lessons.add(lesson);
      } else {
        problems.add('рядок ${index + 1}: ${violations.join(', ')}');
      }
    } on FormatException catch (error) {
      problems.add('рядок ${index + 1}: ${error.message}');
    }
  }
  return (lessons: lessons, problems: problems);
}

/// Групує [lessons] за днем тижня.
Map<Weekday, List<Lesson>> groupByDay(Iterable<Lesson> lessons) {
  final groups = <Weekday, List<Lesson>>{};
  for (final lesson in lessons) {
    groups.putIfAbsent(lesson.day, () => <Lesson>[]).add(lesson);
  }
  return groups;
}

/// Рахує статистику за [lessons] одним записом.
DayStats dayStats(Iterable<Lesson> lessons) =>
    (count: lessons.length, minutes: lessons.totalMinutes);

/// Найраніший і найпізніший початок серед [lessons].
///
/// Повертає `null` для порожньої колекції.
({int earliest, int latest})? startRange(Iterable<Lesson> lessons) {
  if (lessons.isEmpty) return null;
  final starts = lessons.map((lesson) => lesson.startMinutes);
  return (
    earliest: starts.reduce((a, b) => a < b ? a : b),
    latest: starts.reduce((a, b) => a > b ? a : b),
  );
}

/// Словесна оцінка навантаження за статистикою дня.
///
/// Друга гілка має охоронець `when`: вона спрацьовує, лише якщо занять
/// не менше трьох.
String describeLoad(DayStats stats) => switch (stats) {
  (count: 0, minutes: _) => 'вільний день',
  (count: final count, minutes: _) when count >= 3 => 'насичений день',
  _ => 'легкий день',
};

/// Формує текстовий звіт за списком [lessons].
///
/// У звіт потрапляє [topCount] перших занять за розкладом. Якщо
/// [ascending] дорівнює `false`, порядок зворотний. Поля заняття
/// розділяються рядком [separator].
String buildReport(
  List<Lesson> lessons, {
  int topCount = 5,
  bool ascending = true,
  String separator = ' | ',
}) {
  final top = lessons.sortedBySchedule(ascending: ascending).take(topCount);
  final groups = groupByDay(lessons);
  final days = Weekday.values.where(groups.containsKey);

  final buffer = StringBuffer()
    ..writeln('Усього занять: ${lessons.length}')
    ..writeln('Перші $topCount за розкладом:')
    ..writeAll(
      top.map(
        (lesson) => [
          lesson.day.label,
          lesson.timeRange,
          lesson.subject,
          lesson.type.label,
          lesson.room,
        ].join(separator),
      ),
      '\n',
    )
    ..writeln()
    ..writeln('Навантаження за днями:')
    ..writeAll(
      days.map((day) {
        final stats = dayStats(groups[day] ?? const <Lesson>[]);
        return '${day.label}: ${stats.count} зан., '
            '${(stats.minutes / minutesInHour).toStringAsFixed(1)} год '
            '(${describeLoad(stats)})';
      }),
      '\n',
    );
  return buffer.toString();
}
