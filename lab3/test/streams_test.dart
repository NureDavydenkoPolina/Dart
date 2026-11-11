import 'package:lab3/heavy.dart';
import 'package:lab3/lab3_data.dart';
import 'package:lab3/lesson.dart';
import 'package:lab3/schedule_bus.dart';
import 'package:lab3/streams.dart';
import 'package:test/test.dart';

final first = Lesson.fromCsv(rawSchedule[0]);
final second = Lesson.fromCsv(rawSchedule[2]);
final third = Lesson.fromCsv(rawSchedule[4]);

void main() {
  group('ScheduleBus', () {
    test('події до підписки не губляться й зберігають порядок', () async {
      final bus = ScheduleBus()
        ..publish(LessonAdded(first))
        ..publish(LessonRemoved(first.id))
        ..publish(LessonAdded(second));

      await expectLater(
        bus.events.take(3),
        emitsInOrder([
          isA<LessonAdded>(),
          isA<LessonRemoved>(),
          isA<LessonAdded>(),
          emitsDone,
        ]),
      );
      await bus.close();
    });

    test('друга підписка на одноразовий потік кидає StateError', () async {
      final bus = ScheduleBus();
      final subscription = bus.events.listen((_) {});

      expect(() => bus.events.listen((_) {}), throwsStateError);

      await subscription.cancel();
      await bus.close();
    });

    test('широкомовний потік має двох слухачів', () async {
      final bus = ScheduleBus.broadcast();
      final one = <ScheduleEvent>[];
      final two = <ScheduleEvent>[];
      final firstSubscription = bus.events.listen(one.add);
      final secondSubscription = bus.events.listen(two.add);

      bus.publish(LessonAdded(first));
      await Future<void>.delayed(Duration.zero);

      expect(one, hasLength(1));
      expect(two, hasLength(1));
      await firstSubscription.cancel();
      await secondSubscription.cancel();
      await bus.close();
    });
  });

  group('потоки', () {
    test('streamWithError: значення, помилка, значення', () async {
      await expectLater(
        streamWithError([1], StateError('збій'), [3]),
        emitsInOrder([1, emitsError(isA<StateError>()), 3, emitsDone]),
      );
    });

    test('async* ліниво: тіло не виконується без підписки', () async {
      var started = false;
      final stream = emitLessons(
        [first, second],
        interval: Duration.zero,
        onStart: () => started = true,
      );

      expect(started, isFalse);
      final received = await stream.toList();

      expect(started, isTrue);
      expect(received, [first, second]);
    });

    test('listen з cancelOnError: false читає після помилки', () async {
      final log = await consumeWithListen(
        streamWithError(['a'], StateError('збій'), ['c']),
      );

      expect(log.last, 'отримано c');
    });

    test('await for зупиняється на першій помилці', () async {
      final log = await consumeWithAwaitFor(
        streamWithError(['a'], StateError('збій'), ['c']),
      );

      expect(log, hasLength(2));
      expect(log, isNot(contains('отримано c')));
    });

    test('конвеєр addedSubjects відбирає лише додавання', () async {
      final events = Stream<ScheduleEvent>.fromIterable([
        LessonAdded(first),
        LessonRemoved(first.id),
        LessonAdded(second),
        LessonAdded(third),
      ]);

      await expectLater(
        addedSubjects(events),
        emitsInOrder([first.subject, second.subject, emitsDone]),
      );
    });
  });

  group('ізолят', () {
    test('sumOfPrimesBelow(10) дорівнює 17', () {
      expect(sumOfPrimesBelow(10), 17);
    });

    test('Isolate.run дає той самий результат', () async {
      final measurement = await measureInIsolate(100);

      expect(measurement.result, sumOfPrimesBelow(100));
    });

    test('глобальна змінна в ізоляті не змінюється в головному', () async {
      final counter = await mutateGlobalInIsolate();

      expect(counter.inside, 1);
      expect(counter.outside, 0);
    });
  });
}
