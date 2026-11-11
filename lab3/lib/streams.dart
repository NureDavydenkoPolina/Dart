/// Допоміжні потоки: генератор, потік із помилкою, способи споживання.
library;

// Тут потоки збираються зі скінченних Future без async, тому правило
// discarded_futures вимкнено для цього файлу.
// ignore_for_file: discarded_futures

import 'dart:async';

import 'lesson.dart';
import 'schedule_bus.dart';

/// Видає [lessons] по одному з інтервалом [interval].
///
/// Це генератор `async*`. Якщо передано [onStart], його викликають на початку
/// тіла, тобто лише тоді, коли хтось підписався на потік.
Stream<Lesson> emitLessons(
  Iterable<Lesson> lessons, {
  Duration interval = const Duration(milliseconds: 100),
  void Function()? onStart,
}) async* {
  onStart?.call();
  for (final lesson in lessons) {
    await Future<void>.delayed(interval);
    yield lesson;
  }
}

/// Потік: усі [before], потім помилка [error], потім усі [after].
Stream<T> streamWithError<T>(List<T> before, Object error, List<T> after) {
  return Stream<T>.fromFutures([
    for (final item in before) Future<T>.value(item),
    Future<T>.error(error),
    for (final item in after) Future<T>.value(item),
  ]);
}

/// Назви дисциплін із перших [limit] подій додавання заняття.
///
/// Конвеєр: `where` відбирає події, `map` перетворює, `take` обмежує.
Stream<String> addedSubjects(Stream<ScheduleEvent> events, {int limit = 2}) {
  return events
      .where((event) => event is LessonAdded)
      .cast<LessonAdded>()
      .map((event) => event.lesson.subject)
      .take(limit);
}

/// Споживає [stream] через `await for`. Перша помилка перериває цикл.
Future<List<String>> consumeWithAwaitFor<T>(Stream<T> stream) async {
  final log = <String>[];
  try {
    await for (final item in stream) {
      log.add('отримано $item');
    }
  } on Object catch (error) {
    log.add('помилка $error, цикл перервано');
  }
  return log;
}

/// Споживає [stream] через `listen` з `cancelOnError: false`.
///
/// Підписку збережено й скасовано явно.
Future<List<String>> consumeWithListen<T>(Stream<T> stream) async {
  final log = <String>[];
  final done = Completer<void>();
  final subscription = stream.listen(
    (item) => log.add('отримано $item'),
    onError: (Object error) => log.add('помилка $error, підписка триває'),
    onDone: done.complete,
    cancelOnError: false,
  );
  await done.future;
  await subscription.cancel();
  return log;
}
