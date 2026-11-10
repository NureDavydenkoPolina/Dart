/// Дні навчального тижня.
library;

/// День навчального тижня з українською назвою.
enum Weekday {
  /// Понеділок.
  monday('понеділок'),

  /// Вівторок.
  tuesday('вівторок'),

  /// Середа.
  wednesday('середа'),

  /// Четвер.
  thursday('четвер'),

  /// П’ятниця.
  friday('п’ятниця');

  /// Створює день із назвою [label].
  const Weekday(this.label);

  /// Назва дня українською.
  final String label;

  /// Чи йде цей день у тижні раніше за [other].
  bool isBefore(Weekday other) => index < other.index;

  /// Шукає день за назвою. Повертає `null`, якщо такого дня немає.
  static Weekday? tryParse(String text) =>
      values.where((day) => day.label == text).firstOrNull;
}
