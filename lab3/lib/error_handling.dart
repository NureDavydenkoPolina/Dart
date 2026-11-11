/// Обробка помилки в групі одночасних операцій двома способами.
library;

import 'dart:async';

import 'async_repository.dart';
import 'lesson.dart';

/// Завантажує [ids] через `Future.wait` і описує, що відомо про помилку.
Future<String> loadWithFutureWait(
  AsyncRepository<Lesson> repo,
  List<String> ids,
) async {
  try {
    final loaded = await Future.wait([for (final id in ids) repo.require(id)]);
    return 'завантажено ${loaded.length}';
  } on RepositoryException catch (error) {
    return 'Future.wait: лише перша помилка («${error.message}»), '
        'часткових результатів немає';
  }
}

/// Завантажує [ids] через розширення `.wait` і описує, що відомо про помилку.
Future<String> loadWithWaitExtension(
  AsyncRepository<Lesson> repo,
  List<String> ids,
) async {
  try {
    final loaded = await [for (final id in ids) repo.require(id)].wait;
    return 'завантажено ${loaded.length}';
  } on ParallelWaitError<List<Lesson?>, List<AsyncError?>> catch (error) {
    final loaded = error.values.whereType<Lesson>().length;
    final failed = error.errors.whereType<AsyncError>().length;
    return '.wait: ParallelWaitError, завантажено $loaded, помилок $failed';
  }
}
