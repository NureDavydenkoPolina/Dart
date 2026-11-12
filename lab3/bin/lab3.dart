import 'dart:io';

import 'package:lab3/async_repository.dart';
import 'package:lab3/error_handling.dart';
import 'package:lab3/heavy.dart';
import 'package:lab3/lab3_data.dart';
import 'package:lab3/lesson.dart';
import 'package:lab3/pitfalls.dart';
import 'package:lab3/schedule.dart';
import 'package:lab3/schedule_bus.dart';
import 'package:lab3/streams.dart';
import 'package:lab3/timing.dart';

/// Виводить заголовок розділу.
void printSection(String title) {
  stdout.writeln('\n=== $title ===');
}

/// Кількість мілісекунд у [duration] як текст.
String ms(Duration duration) => '${duration.inMilliseconds} мс';

Future<void> main() async {
  final loaded = loadLessons(rawSchedule, now: DateTime.now());
  final lessons = loaded.lessons;
  final first = lessons[0];
  final second = lessons[2];
  final third = lessons[4];

  printSection('Сховище: save, load, delete');
  final repo = AsyncRepository<Lesson>(
    delay: const Duration(milliseconds: 100),
  );
  for (final lesson in [first, second, third]) {
    await repo.save(lesson);
  }
  stdout.writeln('Збережено: ${repo.length}');
  stdout.writeln('load: ${await repo.load(first.id)}');
  stdout.writeln(
    'delete: ${await repo.delete(first.id)}, лишилось ${repo.length}',
  );

  printSection('Забутий await');
  final forgotten = await demoForgottenAwait(first);
  stdout.writeln(
    'Розмір без await: ${forgotten.withoutAwait}, з await: ${forgotten.withAwait}',
  );

  printSection('Послідовно й одночасно (3 операції по 500 мс)');
  final slow = AsyncRepository<Lesson>(delay: const Duration(milliseconds: 500))
    ..seed([first, second, third]);
  final timing = await compareTiming(slow, [first.id, second.id, third.id]);
  stdout.writeln('Послідовно: ${ms(timing.sequential)}');
  stdout.writeln('Одночасно: ${ms(timing.parallel)}');

  printSection('Помилка в групі: Future.wait і .wait');
  final ids = [first.id, 'missing', third.id];
  final failing = AsyncRepository<Lesson>(
    delay: const Duration(milliseconds: 100),
  )..seed([first, second, third]);
  stdout.writeln(await loadWithFutureWait(failing, ids));
  stdout.writeln(await loadWithWaitExtension(failing, ids));

  printSection('Неспіймана помилка');
  stdout.writeln(await demoUncaughtError(failing));

  printSection('Генератор async* і await for');
  final stream = emitLessons(
    [first, second, third],
    interval: const Duration(milliseconds: 100),
    onStart: () => stdout.writeln('  (тіло генератора стартувало)'),
  );
  stdout.writeln('Потік створено, підписки ще немає');
  await Future<void>.delayed(const Duration(milliseconds: 300));
  stdout.writeln('Підписуємось через await for');
  await for (final lesson in stream) {
    stdout.writeln('  ${lesson.subject}');
  }

  printSection('StreamController: події до підписки');
  final bus = ScheduleBus();
  bus
    ..publish(LessonAdded(first))
    ..publish(LessonRemoved(first.id))
    ..publish(LessonAdded(second));
  final subscription = bus.events.listen(
    (event) => stdout.writeln('  подія: $event'),
  );
  await Future<void>.delayed(const Duration(milliseconds: 50));
  await subscription.cancel();
  stdout.writeln('Підписку скасовано');
  await bus.close();

  printSection('Помилка посеред потоку');
  stdout.writeln('await for:');
  for (final line in await consumeWithAwaitFor(
    streamWithError(['a', 'b'], StateError('збій'), ['c']),
  )) {
    stdout.writeln('  $line');
  }
  stdout.writeln('listen(cancelOnError: false):');
  for (final line in await consumeWithListen(
    streamWithError(['a', 'b'], StateError('збій'), ['c']),
  )) {
    stdout.writeln('  $line');
  }

  printSection('Одноразовий і широкомовний потік');
  final single = ScheduleBus();
  final listener = single.events.listen((_) {});
  try {
    single.events.listen((_) {});
  } on StateError catch (error) {
    stdout.writeln('Одноразовий потік: ${error.message}');
  }
  await listener.cancel();
  await single.close();
  final broadcast = ScheduleBus.broadcast();
  final firstListener = broadcast.events.listen((_) {});
  final secondListener = broadcast.events.listen((_) {});
  stdout.writeln('Широкомовний потік: два слухачі без помилки');
  await firstListener.cancel();
  await secondListener.cancel();
  await broadcast.close();

  printSection('Конвеєр потоку: where, map, take');
  final pipelineBus = ScheduleBus();
  final subjects = addedSubjects(pipelineBus.events).toList();
  pipelineBus
    ..publish(LessonAdded(first))
    ..publish(LessonRemoved(first.id))
    ..publish(LessonAdded(second))
    ..publish(LessonAdded(third));
  stdout.writeln('Перші дві назви: ${await subjects}');
  await pipelineBus.close();

  printSection('Ізолят: сума простих чисел менших за 2 000 000');
  const limit = 2000000;
  final onMain = await measureOnMainIsolate(limit);
  stdout.writeln(
    'У головному ізоляті: ${ms(onMain.elapsed)}, тиків таймера: ${onMain.ticks}',
  );
  final inIsolate = await measureInIsolate(limit);
  stdout.writeln(
    'В Isolate.run: ${ms(inIsolate.elapsed)}, тиків таймера: ${inIsolate.ticks}',
  );
  stdout.writeln('Результати збігаються: ${onMain.result == inIsolate.result}');

  printSection('Глобальна змінна в ізоляті');
  final counter = await mutateGlobalInIsolate();
  stdout.writeln(
    'Усередині ізолята: ${counter.inside}, зовні: ${counter.outside}',
  );
}
