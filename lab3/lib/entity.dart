/// Базові типи моделі: сутність, домішка для виведення та сховище.
library;

/// Сутність, яка має власний ідентифікатор.
abstract class Entity {
  /// Створює сутність. Константний конструктор дозволяє нащадкам бути `const`.
  const Entity();

  /// Унікальний ідентифікатор сутності в межах її типу.
  String get id;
}

/// Домішка: додає сутності короткий підпис на основі [Entity.id].
///
/// Обмеження `on Entity` дає доступ до [id] усередині домішки й не дозволяє
/// підмішати її до класу, який не є сутністю.
mixin Printable on Entity {
  /// Короткий підпис у квадратних дужках.
  String get tag => '[$id]';

  /// Рядок для виведення: підпис і текстове подання об’єкта.
  String describe() => '$tag $this';
}

/// Сховище сутностей з пошуком за ідентифікатором.
///
/// Обмеження `T extends Entity` гарантує, що в кожного елемента є `id`.
class Repository<T extends Entity> {
  final Map<String, T> _items = {};

  /// Додає [item]. Сутність із таким самим `id` замінюється.
  void add(T item) => _items[item.id] = item;

  /// Додає всі [items].
  void addAll(Iterable<T> items) => items.forEach(add);

  /// Повертає сутність за [id] або `null`.
  T? findById(String id) => _items[id];

  /// Усі сутності, що задовольняють [test].
  Iterable<T> where(bool Function(T) test) => _items.values.where(test);

  /// Кількість сутностей у сховищі.
  int get length => _items.length;
}
