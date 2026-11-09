/// Розбір, перевірка та агрегація розкладу занять групи.
///
/// Класи тут не використовуються. Дані подано записами (records),
/// а обробку виконано функціями.
library;

import 'dart:math' show max, min;

/// Дні тижня у порядку розкладу.
const List<String> weekdays = [
  'понеділок',
  'вівторок',
  'середа',
  'четвер',
  'п’ятниця',
];

/// Допустимі типи занять.
const List<String> lessonTypes = ['лекція', 'практика', 'лабораторна'];

/// Роздільник полів у вхідному рядку.
const String fieldSeparator = ';';

/// Кількість полів у правильному рядку.
const int fieldCount = 7;

/// Тривалість одного заняття (пари) у хвилинах.
const int lessonDurationMinutes = 90;

/// Кількість хвилин в одній годині.
const int minutesInHour = 60;

/// Найраніший допустимий початок заняття (08:00) у хвилинах від півночі.
const int earliestStartMinutes = 8 * minutesInHour;

/// Найпізніший допустимий початок заняття (19:00) у хвилинах від півночі.
const int latestStartMinutes = 19 * minutesInHour;

/// Заняття: дисципліна, викладач, тип, день, початок, аудиторія, дата запису.
///
/// Початок і тривалість зберігаються в хвилинах.
typedef Lesson = ({
  String subject,
  String teacher,
  String type,
  String day,
  int startMinutes,
  int durationMinutes,
  String room,
  DateTime addedOn,
});

/// Результат розбору рядка: або заняття, або опис помилки.
typedef ParseResult = ({Lesson? lesson, String? error});

/// Результат завантаження: коректні заняття та список проблем.
typedef LoadResult = ({List<Lesson> lessons, List<String> problems});

/// Статистика за один день: кількість занять і сумарна тривалість.
typedef DayStats = ({int count, int totalMinutes});

/// Формат часу `ГГ:ХХ` з іменованими групами.
final RegExp timePattern = RegExp(r'^(?<hour>\d{1,2}):(?<minute>\d{2})$');

/// Прізвище викладача: перша літера й решта літер.
///
/// Шаблон прив’язаний до початку рядка, тому збіг може бути лише один.
final RegExp teacherPattern = RegExp(
  r'^(?<first>\p{L})(?<rest>\p{L}+)',
  unicode: true,
);

/// Перетворює час [text] у форматі `ГГ:ХХ` на хвилини від півночі.
///
/// Повертає `null`, якщо формат або діапазон неправильні.
int? parseTime(String text) {
  final match = timePattern.firstMatch(text);
  if (match == null) return null;
  final hour = int.tryParse(match.namedGroup('hour') ?? '');
  final minute = int.tryParse(match.namedGroup('minute') ?? '');
  if (hour == null || minute == null) return null;
  if (hour > 23 || minute > 59) return null;
  return hour * minutesInHour + minute;
}

/// Розбирає рядок [line] у заняття.
///
/// Якщо рядок пошкоджений, у результаті буде `error` замість `lesson`.
ParseResult parseLine(String line) {
  final fields = line.split(fieldSeparator).map((f) => f.trim()).toList();
  if (fields.length != fieldCount) {
    return (
      lesson: null,
      error: 'очікувалось $fieldCount полів, знайдено ${fields.length}',
    );
  }
  final [subject, teacher, type, day, timeText, room, dateText] = fields;
  if (subject.isEmpty || teacher.isEmpty || room.isEmpty) {
    return (lesson: null, error: 'порожнє обов’язкове поле');
  }
  final startMinutes = parseTime(timeText);
  if (startMinutes == null) {
    return (lesson: null, error: 'час «$timeText» не схожий на ГГ:ХХ');
  }
  final addedOn = DateTime.tryParse(dateText);
  if (addedOn == null || formatDate(addedOn) != dateText) {
    return (lesson: null, error: 'некоректна дата «$dateText»');
  }
  return (
    lesson: (
      subject: subject,
      teacher: teacher,
      type: type,
      day: day,
      startMinutes: startMinutes,
      durationMinutes: lessonDurationMinutes,
      room: room,
      addedOn: addedOn,
    ),
    error: null,
  );
}

/// Перевіряє значення заняття [lesson] і повертає список порушень.
///
/// Порожній список означає, що заняття коректне. Дата [now] потрібна,
/// щоб відсікти дати з майбутнього.
List<String> validateLesson(Lesson lesson, {required DateTime now}) {
  final start = lesson.startMinutes;
  return [
    if (!weekdays.contains(lesson.day)) 'невідомий день «${lesson.day}»',
    if (!lessonTypes.contains(lesson.type)) 'невідомий тип «${lesson.type}»',
    if (start < earliestStartMinutes || start > latestStartMinutes)
      'початок ${formatTime(start)} поза межами '
          '${formatTime(earliestStartMinutes)}–'
          '${formatTime(latestStartMinutes)}',
    if (lesson.addedOn.isAfter(now))
      'дата запису ${formatDate(lesson.addedOn)} у майбутньому',
  ];
}

/// Розбирає й перевіряє всі [lines].
///
/// Некоректні рядки не зупиняють роботу: їх опис потрапляє в `problems`.
LoadResult loadLessons(List<String> lines, {required DateTime now}) {
  final parsed = lines.indexed
      .map((entry) => (number: entry.$1 + 1, result: parseLine(entry.$2)))
      .toList();

  final parseProblems = [
    for (final item in parsed)
      if (item.result.error case final error?) 'рядок ${item.number}: $error',
  ];

  final validated = [
    for (final item in parsed)
      if (item.result.lesson case final lesson?)
        (
          number: item.number,
          lesson: lesson,
          violations: validateLesson(lesson, now: now),
        ),
  ];

  final validationProblems = [
    for (final item in validated)
      if (item.violations.isNotEmpty)
        'рядок ${item.number}: ${item.violations.join(', ')}',
  ];

  final lessons = validated
      .where((item) => item.violations.isEmpty)
      .map((item) => item.lesson)
      .toList();

  return (
    lessons: lessons,
    problems: [...parseProblems, ...validationProblems],
  );
}

/// Повертає предикат: заняття відбувається в день [day].
///
/// Замикання захоплює параметр [day].
bool Function(Lesson) byDay(String day) =>
    (lesson) => lesson.day == day;

/// Повертає предикат: заняття має тип [type].
///
/// Замикання захоплює параметр [type].
bool Function(Lesson) byType(String type) =>
    (lesson) => lesson.type == type;

/// Створює лічильник, який при кожному виклику дає наступне число.
///
/// Замикання захоплює змінну `count` і змінює її між викликами.
int Function() makeCounter() {
  var count = 0;
  return () => ++count;
}

/// Сумарна тривалість занять [lessons] у хвилинах.
int totalMinutes(Iterable<Lesson> lessons) => lessons
    .map((lesson) => lesson.durationMinutes)
    .fold(0, (sum, value) => sum + value);

/// Найраніший і найпізніший початок серед [lessons].
///
/// Повертає `null` для порожньої колекції.
({int earliest, int latest})? startRange(Iterable<Lesson> lessons) {
  if (lessons.isEmpty) return null;
  final starts = lessons.map((lesson) => lesson.startMinutes);
  return (earliest: starts.reduce(min), latest: starts.reduce(max));
}

/// Групує [lessons] за днем тижня.
Map<String, List<Lesson>> groupByDay(Iterable<Lesson> lessons) {
  return lessons.fold<Map<String, List<Lesson>>>({}, (groups, lesson) {
    groups.putIfAbsent(lesson.day, () => <Lesson>[]).add(lesson);
    return groups;
  });
}

/// Рахує кількість і тривалість занять у кожній групі [groups].
Map<String, DayStats> statsByDay(Map<String, List<Lesson>> groups) {
  return groups.map(
    (day, items) =>
        MapEntry(day, (count: items.length, totalMinutes: totalMinutes(items))),
  );
}

/// Рахує заняття кожного типу.
Map<String, int> countByType(Iterable<Lesson> lessons) {
  return lessons.fold<Map<String, int>>({}, (counts, lesson) {
    counts.update(lesson.type, (value) => value + 1, ifAbsent: () => 1);
    return counts;
  });
}

/// Сортує [lessons] за днем тижня, а потім за часом початку.
///
/// Якщо [ascending] дорівнює `false`, порядок зворотний.
List<Lesson> sortBySchedule(Iterable<Lesson> lessons, {bool ascending = true}) {
  final sorted = lessons.toList();
  sorted.sort((a, b) {
    final dayOrder = weekdays.indexOf(a.day).compareTo(weekdays.indexOf(b.day));
    final result = dayOrder != 0
        ? dayOrder
        : a.startMinutes.compareTo(b.startMinutes);
    return ascending ? result : -result;
  });
  return sorted;
}

/// Сортує [lessons] за назвою дисципліни, а потім за часом початку.
///
/// Якщо [ascending] дорівнює `false`, порядок зворотний.
List<Lesson> sortBySubject(Iterable<Lesson> lessons, {bool ascending = true}) {
  final sorted = lessons.toList();
  sorted.sort((a, b) {
    final subjectOrder = a.subject.compareTo(b.subject);
    final result = subjectOrder != 0
        ? subjectOrder
        : a.startMinutes.compareTo(b.startMinutes);
    return ascending ? result : -result;
  });
  return sorted;
}

/// Шукає перше заняття в аудиторії [room].
///
/// Повертає `null`, якщо такого заняття немає.
Lesson? findByRoom(Iterable<Lesson> lessons, String room) {
  return lessons.where((lesson) => lesson.room == room).firstOrNull;
}

/// Форматує хвилини від півночі як `ГГ:ХХ`.
String formatTime(int minutes) {
  final hours = (minutes ~/ minutesInHour).toString().padLeft(2, '0');
  final rest = (minutes % minutesInHour).toString().padLeft(2, '0');
  return '$hours:$rest';
}

/// Форматує дату [date] як `РРРР-ММ-ДД`.
String formatDate(DateTime date) => date.toIso8601String().split('T').first;

/// Форматує хвилини [minutes] як години з одним знаком після коми.
String formatHours(int minutes) => (minutes / minutesInHour).toStringAsFixed(1);

/// Описує заняття [lesson] одним рядком із роздільником [separator].
String describeLesson(Lesson lesson, {String separator = ' | '}) {
  return [
    lesson.day,
    formatTime(lesson.startMinutes),
    lesson.subject,
    lesson.type,
    lesson.room,
  ].join(separator);
}

/// Маскує прізвище викладача: лишає першу літеру, решту замінює на `*`.
String maskTeacher(String teacher) {
  final match = teacherPattern.firstMatch(teacher);
  if (match == null) return teacher;
  final first = match.namedGroup('first') ?? '';
  final rest = match.namedGroup('rest') ?? '';
  final tail = teacher.substring(match.end);
  return '$first${'*' * rest.length}$tail';
}

/// Вік запису в днях відносно [now].
int ageInDays(Lesson lesson, {required DateTime now}) {
  final Duration age = now.difference(lesson.addedOn);
  return age.inDays;
}

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
  final nextNumber = makeCounter();
  final top = sortBySchedule(lessons, ascending: ascending).take(topCount);
  final stats = statsByDay(groupByDay(lessons)).entries.toList();
  stats.sort(
    (a, b) => weekdays.indexOf(a.key).compareTo(weekdays.indexOf(b.key)),
  );

  final buffer = StringBuffer()
    ..writeln('Усього занять: ${lessons.length}')
    ..writeln('Перші $topCount за розкладом:')
    ..writeAll(
      top.map(
        (lesson) =>
            '${nextNumber()}. ${describeLesson(lesson, separator: separator)}',
      ),
      '\n',
    )
    ..writeln()
    ..writeln('Навантаження за днями:')
    ..writeAll(
      stats.map(
        (entry) =>
            '${entry.key}: ${entry.value.count} зан., '
            '${formatHours(entry.value.totalMinutes)} год',
      ),
      '\n',
    );
  return buffer.toString();
}
