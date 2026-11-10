/// Асинхронне сховище сутностей: кожна операція повертає [Future] або [Stream].
library;

import 'entity.dart';

/// Помилка сховища, наприклад коли сутність не знайдено.
class RepositoryException implements Exception {
  /// Створює помилку з описом [message].
  const RepositoryException(this.message);

  /// Опис помилки.
  final String message;

  @override
  String toString() => 'RepositoryException: $message';
}

/// Асинхронне сховище сутностей з імітацією затримки джерела даних.
///
/// Затримки задаються параметрами, щоб у тестах їх можна було прибрати.
class AsyncRepository<T extends Entity> {
  /// Створює порожнє сховище.
  ///
  /// [delay] — затримка кожної операції, [streamInterval] — інтервал між
  /// елементами потоку [watchAll].
  AsyncRepository({
    this.delay = const Duration(milliseconds: 300),
    this.streamInterval = const Duration(milliseconds: 100),
  });

  /// Затримка однієї операції.
  final Duration delay;

  /// Інтервал між елементами потоку.
  final Duration streamInterval;

  final Map<String, T> _items = {};

  /// Кількість сутностей у сховищі. Синхронний гетер, без затримки.
  int get length => _items.length;

  /// Одразу кладе [items] у сховище без затримки. Потрібно для демонстрацій
  /// і тестів.
  void seed(Iterable<T> items) {
    for (final item in items) {
      _items[item.id] = item;
    }
  }

  /// Повертає сутність за [id] або `null`.
  Future<T?> load(String id) async {
    await Future<void>.delayed(delay);
    return _items[id];
  }

  /// Повертає сутність за [id] або кидає [RepositoryException].
  Future<T> require(String id) async {
    final item = await load(id);
    if (item == null) {
      throw RepositoryException('сутність «$id» не знайдено');
    }
    return item;
  }

  /// Зберігає [item]. Сутність із таким самим `id` замінюється.
  Future<void> save(T item) async {
    await Future<void>.delayed(delay);
    _items[item.id] = item;
  }

  /// Видаляє сутність за [id]. Повертає `true`, якщо вона була.
  Future<bool> delete(String id) async {
    await Future<void>.delayed(delay);
    return _items.remove(id) != null;
  }

  /// Видає сутності по одній з інтервалом [streamInterval].
  ///
  /// Це генератор `async*`: його тіло не виконується, доки ніхто не підписався.
  Stream<T> watchAll() async* {
    for (final item in _items.values.toList()) {
      await Future<void>.delayed(streamInterval);
      yield item;
    }
  }
}
