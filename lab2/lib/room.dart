/// Аудиторія як окрема сутність.
library;

import 'entity.dart';

/// Аудиторія, у якій відбуваються заняття.
class Room extends Entity with Printable {
  /// Створює аудиторію з кодом [code], наприклад `Ж-301`.
  const Room(this.code);

  /// Код аудиторії.
  final String code;

  @override
  String get id => code;

  /// Корпус: частина коду до дефіса. Для коду без дефіса — увесь код.
  String get building => code.split('-').first;

  @override
  String toString() => 'Аудиторія $code';
}
