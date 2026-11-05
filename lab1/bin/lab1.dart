import 'dart:io';

import 'package:lab1/lab1.dart';
import 'package:lab1/lab1_data.dart';

void printSection(String title) {
  stdout.writeln('\n=== $title ===');
}

void main() {
  final now = DateTime.now();
  final loaded = loadLessons(rawSchedule, now: now);
  final lessons = loaded.lessons;

  printSection('Проблемні рядки');
  stdout.writeln(loaded.problems.join('\n'));
  stdout.writeln('Коректних занять: ${lessons.length} з ${rawSchedule.length}');

  printSection('Конвеєр 1: фільтрація (понеділок)');
  final monday = lessons.where(byDay('понеділок')).toList();
  stdout.writeln(sortBySchedule(monday).map(describeLesson).join('\n'));

  printSection('Конвеєр 2: перетворення (лекції як рядки)');
  final lectures = lessons.where(byType('лекція')).map(describeLesson);
  stdout.writeln(lectures.join('\n'));

  printSection('Конвеєр 3: згортання');
  final lectureMinutes = totalMinutes(lessons.where(byType('лекція')));
  stdout.writeln('Годин лекцій на тиждень: ${formatHours(lectureMinutes)}');
  stdout.writeln('Годин усього: ${formatHours(totalMinutes(lessons))}');
  final range = startRange(lessons);
  if (range != null) {
    stdout.writeln(
      'Початок занять: від ${formatTime(range.earliest)} '
      'до ${formatTime(range.latest)}',
    );
  }
  stdout.writeln('За типами: ${countByType(lessons)}');

  printSection('Сортування за дисципліною (за спаданням)');
  final bySubject = sortBySubject(lessons, ascending: false).take(3);
  stdout.writeln(bySubject.map(describeLesson).join('\n'));

  printSection('Звіт');
  stdout.writeln(buildReport(lessons, topCount: 4));
  stdout.writeln('\nЗвіт у зворотному порядку:');
  stdout.writeln(
    buildReport(lessons, topCount: 3, ascending: false, separator: ' · '),
  );

  printSection('Регулярний вираз: маскування викладачів');
  stdout.writeln(
    lessons.take(3).map((lesson) => maskTeacher(lesson.teacher)).join('\n'),
  );

  printSection('Вік записів у днях');
  stdout.writeln(
    lessons
        .take(3)
        .map(
          (lesson) => '${lesson.subject}: ${ageInDays(lesson, now: now)} дн.',
        )
        .join('\n'),
  );

  printSection('Пошук за аудиторією');
  final found = findByRoom(lessons, 'Л-204');
  stdout.writeln(found == null ? 'Не знайдено' : describeLesson(found));
}
