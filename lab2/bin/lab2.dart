import 'dart:io';

import 'package:lab2/entity.dart';
import 'package:lab2/lab2_data.dart';
import 'package:lab2/lesson.dart';
import 'package:lab2/lesson_extensions.dart';
import 'package:lab2/lesson_type.dart';
import 'package:lab2/room.dart';
import 'package:lab2/schedule.dart';
import 'package:lab2/time_utils.dart';
import 'package:lab2/weekday.dart';

/// Виводить заголовок розділу.
void printSection(String title) {
  stdout.writeln('\n=== $title ===');
}

void main() {
  final now = DateTime.now();
  final (lessons: lessons, problems: problems) = loadLessons(
    rawSchedule,
    now: now,
  );

  printSection('Проблемні рядки');
  stdout.writeln(problems.join('\n'));
  stdout.writeln('Коректних занять: ${lessons.length} з ${rawSchedule.length}');

  printSection('Конструктори: fromCsv і cached');
  final first = Lesson.fromCsv(rawSchedule.first);
  stdout.writeln(first);
  stdout.writeln(
    'cached повертає той самий об’єкт: '
    '${identical(Lesson.cached(rawSchedule.first), Lesson.cached(rawSchedule.first))}',
  );

  printSection('Рівність за значенням');
  final copies = {Lesson.fromCsv(rawSchedule.first), first};
  stdout.writeln('Розмір Set з двох однакових занять: ${copies.length}');

  printSection('Запечатана ієрархія і switch');
  for (final type in const <LessonType>[Lecture(), Practice(), Laboratory()]) {
    stdout.writeln(
      '${type.label}: навантаження ${type.workload}, '
      'самопідготовка ${homeworkMinutes(type)} хв',
    );
  }

  printSection('Домішка Printable');
  stdout.writeln(first.describe());
  stdout.writeln(const Room('Ж-301').describe());

  printSection('Методи розширення');
  final monday = lessons.onDay(Weekday.monday).sortedBySchedule();
  stdout.writeln('Понеділок: ${monday.length} зан., ${monday.totalMinutes} хв');
  stdout.writeln('Лекцій: ${lessons.ofType<Lecture>().length}');
  stdout.writeln('Показник навантаження: ${lessons.workloadScore}');
  stdout.writeln('Перший початок: ${lessons.first.startMinutes.asClock}');

  printSection('Узагальнене сховище');
  final lessonRepo = Repository<Lesson>()..addAll(lessons);
  stdout.writeln(lessonRepo.findById('monday-08:30-Ж-301'));
  stdout.writeln('Не знайдено: ${lessonRepo.findById('sunday-00:00-X')}');
  final roomRepo = Repository<Room>()
    ..addAll(lessons.map((lesson) => Room(lesson.room)));
  stdout.writeln('Аудиторій: ${roomRepo.length}');
  stdout.writeln(
    'У корпусі Ж: ${roomRepo.where((room) => room.building == 'Ж').length}',
  );

  printSection('Перелічення Weekday');
  stdout.writeln(Weekday.values.map((day) => day.label).join(', '));
  stdout.writeln(
    'вівторок раніше за четвер: ${Weekday.tuesday.isBefore(Weekday.thursday)}',
  );

  printSection('Записи та зіставлення зі зразком');
  if (startRange(lessons) case (earliest: final from, latest: final to)) {
    stdout.writeln('Початок занять: від ${from.asClock} до ${to.asClock}');
  }
  stdout.writeln(describeLoad((count: 0, minutes: 0)));
  stdout.writeln(describeLoad((count: 2, minutes: 180)));
  stdout.writeln(describeLoad((count: 3, minutes: 270)));

  printSection('Звіт');
  stdout.writeln(buildReport(lessons, topCount: 4));
  stdout.writeln('\nЗвіт у зворотному порядку:');
  stdout.writeln(
    buildReport(lessons, topCount: 3, ascending: false, separator: ' · '),
  );

  printSection('Вік записів у днях');
  stdout.writeln(
    lessons
        .take(3)
        .map((lesson) => '${lesson.subject}: ${lesson.ageInDays(now: now)} дн.')
        .join('\n'),
  );
}
