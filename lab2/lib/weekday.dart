/// Дні навчального тижня.
library;

/// День навчального тижня з українською назвою.
enum Weekday {
  monday('понеділок'),

  tuesday('вівторок'),

  wednesday('середа'),

  thursday('четвер'),

  friday('п’ятниця');

  const Weekday(this.label);

  final String label;

  /// Чи йде цей день у тижні раніше за [other].
  bool isBefore(Weekday other) => index < other.index;

  /// Шукає день за назвою. Повертає `null`, якщо такого дня немає.
  static Weekday? tryParse(String text) =>
      values.where((day) => day.label == text).firstOrNull;
}
