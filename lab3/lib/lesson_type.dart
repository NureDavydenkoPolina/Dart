/// Ієрархія типів занять.
library;

/// Тип заняття. Запечатаний клас: усі підтипи відомі компілятору.
sealed class LessonType {
  /// Створює тип заняття.
  const LessonType();

  /// Розбирає назву типу.
  ///
  /// Кидає [FormatException] для невідомої назви.
  factory LessonType.parse(String text) => switch (text) {
    'лекція' => const Lecture(),
    'практика' => const Practice(),
    'лабораторна' => const Laboratory(),
    _ => throw FormatException('невідомий тип «$text»'),
  };

  /// Назва типу українською.
  String get label;

  /// Відносне навантаження на студента (лекція = 1).
  double get workload;

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => label;
}

/// Лекція.
final class Lecture extends LessonType {
  /// Створює лекцію.
  const Lecture();

  @override
  String get label => 'лекція';

  @override
  double get workload => 1;
}

/// Практичне заняття.
final class Practice extends LessonType {
  /// Створює практичне заняття.
  const Practice();

  @override
  String get label => 'практика';

  @override
  double get workload => 1.5;
}

/// Лабораторна робота.
final class Laboratory extends LessonType {
  /// Створює лабораторну роботу.
  const Laboratory();

  @override
  String get label => 'лабораторна';

  @override
  double get workload => 2;
}

/// Рекомендований час самопідготовки до заняття типу [type] у хвилинах.
///
/// Вираз `switch` не має гілки `default`: компілятор перевіряє, що враховано
/// всі підтипи запечатаного класу.
int homeworkMinutes(LessonType type) => switch (type) {
  Lecture() => 30,
  Practice() => 60,
  Laboratory() => 90,
};
