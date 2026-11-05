library;

import 'dart:math' show max, min;

const List<String> weekdays = [
  'понеділок',
  'вівторок',
  'середа',
  'четвер',
  'п’ятниця',
];

const List<String> lessonTypes = ['лекція', 'практика', 'лабораторна'];

const String fieldSeparator = ';';

const int fieldCount = 7;

const int lessonDurationMinutes = 90;

const int minutesInHour = 60;

const int earliestStartMinutes = 8 * minutesInHour;

const int latestStartMinutes = 19 * minutesInHour;

typedef Lesson = ({
  String subject,
  String teacher,
  String type,
  String day,
  int startMinutes,
  String room,
  DateTime addedOn,
});

typedef ParseResult = ({Lesson? lesson, String? error});

typedef LoadResult = ({List<Lesson> lessons, List<String> problems});

typedef DayStats = ({int count, int totalMinutes});

final RegExp timePattern = RegExp(r'^(?<hour>\d{1,2}):(?<minute>\d{2})$');

final RegExp teacherPattern = RegExp(
  r'^(?<first>\p{L})(?<rest>\p{L}+)',
  unicode: true,
);

int? parseTime(String text) {
  final match = timePattern.firstMatch(text);
  if (match == null) return null;
  final hour = int.tryParse(match.namedGroup('hour') ?? '');
  final minute = int.tryParse(match.namedGroup('minute') ?? '');
  if (hour == null || minute == null) return null;
  if (hour > 23 || minute > 59) return null;
  return hour * minutesInHour + minute;
}

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
  if (addedOn == null) {
    return (lesson: null, error: 'некоректна дата «$dateText»');
  }
  return (
    lesson: (
      subject: subject,
      teacher: teacher,
      type: type,
      day: day,
      startMinutes: startMinutes,
      room: room,
      addedOn: addedOn,
    ),
    error: null,
  );
}

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

bool Function(Lesson) byDay(String day) =>
    (lesson) => lesson.day == day;

bool Function(Lesson) byType(String type) =>
    (lesson) => lesson.type == type;

int Function() makeCounter() {
  var count = 0;
  return () => ++count;
}

int durationOf(Lesson lesson) => lessonDurationMinutes;

int totalMinutes(Iterable<Lesson> lessons) =>
    lessons.map(durationOf).fold(0, (sum, value) => sum + value);

({int earliest, int latest})? startRange(Iterable<Lesson> lessons) {
  if (lessons.isEmpty) return null;
  final starts = lessons.map((lesson) => lesson.startMinutes);
  return (earliest: starts.reduce(min), latest: starts.reduce(max));
}

Map<String, List<Lesson>> groupByDay(Iterable<Lesson> lessons) {
  return lessons.fold<Map<String, List<Lesson>>>({}, (groups, lesson) {
    groups.putIfAbsent(lesson.day, () => <Lesson>[]).add(lesson);
    return groups;
  });
}

Map<String, DayStats> statsByDay(Map<String, List<Lesson>> groups) {
  return groups.map(
    (day, items) =>
        MapEntry(day, (count: items.length, totalMinutes: totalMinutes(items))),
  );
}

Map<String, int> countByType(Iterable<Lesson> lessons) {
  return lessons.fold<Map<String, int>>({}, (counts, lesson) {
    counts.update(lesson.type, (value) => value + 1, ifAbsent: () => 1);
    return counts;
  });
}

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

Lesson? findByRoom(Iterable<Lesson> lessons, String room) {
  return lessons.where((lesson) => lesson.room == room).firstOrNull;
}

String formatTime(int minutes) {
  final hours = (minutes ~/ minutesInHour).toString().padLeft(2, '0');
  final rest = (minutes % minutesInHour).toString().padLeft(2, '0');
  return '$hours:$rest';
}

String formatDate(DateTime date) => date.toIso8601String().split('T').first;

String formatHours(int minutes) => (minutes / minutesInHour).toStringAsFixed(1);

String describeLesson(Lesson lesson, {String separator = ' | '}) {
  return [
    lesson.day,
    formatTime(lesson.startMinutes),
    lesson.subject,
    lesson.type,
    lesson.room,
  ].join(separator);
}

String maskTeacher(String teacher) {
  return teacher.replaceAllMapped(teacherPattern, (match) {
    if (match is! RegExpMatch) return match[0] ?? '';
    final first = match.namedGroup('first') ?? '';
    final rest = match.namedGroup('rest') ?? '';
    return '$first${'*' * rest.length}';
  });
}

int ageInDays(Lesson lesson, {required DateTime now}) {
  final Duration age = now.difference(lesson.addedOn);
  return age.inDays;
}

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
