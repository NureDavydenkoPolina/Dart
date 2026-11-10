import 'package:lab3/async_repository.dart';
import 'package:lab3/lab3_data.dart';
import 'package:lab3/lesson.dart';
import 'package:test/test.dart';

final first = Lesson.fromCsv(rawSchedule[0]);
final second = Lesson.fromCsv(rawSchedule[2]);
final third = Lesson.fromCsv(rawSchedule[4]);

void main() {
  group('AsyncRepository', () {
    late AsyncRepository<Lesson> repo;

    setUp(() {
      repo = AsyncRepository<Lesson>(
        delay: Duration.zero,
        streamInterval: Duration.zero,
      );
    });

    test('зберігає сутність і повертає її за id', () async {
      await repo.save(first);

      expect(await repo.load(first.id), first);
    });

    test('повертає null для невідомого id', () async {
      expect(await repo.load('missing'), isNull);
    });

    test('видаляє сутність', () async {
      repo.seed([first]);

      expect(await repo.delete(first.id), isTrue);
      expect(repo.length, 0);
    });

    test('require кидає RepositoryException для невідомого id', () async {
      await expectLater(
        repo.require('missing'),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('watchAll видає сутності в порядку додавання', () async {
      repo.seed([first, second, third]);

      await expectLater(
        repo.watchAll(),
        emitsInOrder([first, second, third, emitsDone]),
      );
    });
  });
}
