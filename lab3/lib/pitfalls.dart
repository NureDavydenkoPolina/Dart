/// Навмисні помилки асинхронного коду для демонстрації. Рядки з `ignore`
/// гасять лінти, які в цих місцях спрацьовують свідомо.
library;

import 'dart:async';

import 'async_repository.dart';
import 'lesson.dart';

/// Розмір сховища після виклику `save` без `await` і з `await`.
typedef ForgottenAwaitResult = ({int withoutAwait, int withAwait});

/// Показує, що змінюється, якщо забути `await` перед `save`.
Future<ForgottenAwaitResult> demoForgottenAwait(Lesson lesson) async {
  final forgotten = AsyncRepository<Lesson>(
    delay: const Duration(milliseconds: 50),
  );
  forgotten.save(lesson); // ignore: unawaited_futures
  final withoutAwait = forgotten.length;

  final correct = AsyncRepository<Lesson>(
    delay: const Duration(milliseconds: 50),
  );
  await correct.save(lesson);
  return (withoutAwait: withoutAwait, withAwait: correct.length);
}

/// Показує, що `try/catch` навколо виклику без `await` не ловить помилку.
///
/// Помилка потрапляє в обробник зони, а не в `catch`.
Future<String> demoUncaughtError(AsyncRepository<Lesson> repo) {
  final outcome = Completer<String>();
  runZonedGuarded(
    () {
      try {
        repo.require('missing'); // ignore: unawaited_futures, discarded_futures
      } on RepositoryException {
        outcome.complete('try/catch спіймав помилку');
      }
    },
    (error, stack) {
      outcome.complete(
        'try/catch не спіймав, помилка в обробнику зони: $error',
      );
    },
  );
  return outcome.future;
}
