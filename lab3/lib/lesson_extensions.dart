/// Методи розширення для колекцій занять.
library;

import 'lesson.dart';
import 'lesson_type.dart';
import 'weekday.dart';

/// Запити до будь-якої послідовності занять.
extension LessonQueries on Iterable<Lesson> {
  /// Заняття, що відбуваються в день [day].
  Iterable<Lesson> onDay(Weekday day) => where((lesson) => lesson.day == day);

  /// Заняття типу [T], наприклад `lessons.ofType<Lecture>()`.
  Iterable<Lesson> ofType<T extends LessonType>() =>
      where((lesson) => lesson.type is T);

  /// Сумарна тривалість занять у хвилинах.
  int get totalMinutes =>
      fold(0, (sum, lesson) => sum + lesson.durationMinutes);

  /// Сумарний показник навантаження: сума коефіцієнтів типів занять.
  double get workloadScore =>
      fold(0.0, (sum, lesson) => sum + lesson.type.workload);

  /// Копія списку, відсортована за днем тижня, а потім за часом початку.
  ///
  /// Якщо [ascending] дорівнює `false`, порядок зворотний.
  List<Lesson> sortedBySchedule({bool ascending = true}) {
    final sorted = toList();
    sorted.sort((a, b) {
      final dayOrder = a.day.index.compareTo(b.day.index);
      final result = dayOrder != 0
          ? dayOrder
          : a.startMinutes.compareTo(b.startMinutes);
      return ascending ? result : -result;
    });
    return sorted;
  }
}
