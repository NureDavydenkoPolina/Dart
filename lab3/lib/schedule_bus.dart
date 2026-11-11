/// Події розкладу та канал, яким їх передають.
library;

import 'dart:async';

import 'lesson.dart';

/// Подія зміни розкладу. Запечатаний клас: підтипи відомі компілятору.
sealed class ScheduleEvent {
  /// Створює подію.
  const ScheduleEvent();
}

/// До розкладу додано заняття.
final class LessonAdded extends ScheduleEvent {
  /// Створює подію додавання заняття [lesson].
  const LessonAdded(this.lesson);

  /// Додане заняття.
  final Lesson lesson;

  @override
  String toString() => 'додано: ${lesson.subject}';
}

/// З розкладу видалено заняття.
final class LessonRemoved extends ScheduleEvent {
  /// Створює подію видалення заняття з ідентифікатором [lessonId].
  const LessonRemoved(this.lessonId);

  /// Ідентифікатор видаленого заняття.
  final String lessonId;

  @override
  String toString() => 'видалено: $lessonId';
}

/// Канал подій розкладу на основі [StreamController].
///
/// Звичайний канал має потік одноразової підписки: події, додані до підписки,
/// буферизуються й не губляться. Канал [ScheduleBus.broadcast] дозволяє
/// кілька слухачів, але події без слухача пропадають.
class ScheduleBus {
  /// Створює канал з потоком одноразової підписки.
  ScheduleBus() : _controller = StreamController<ScheduleEvent>();

  /// Створює канал із широкомовним потоком.
  ScheduleBus.broadcast()
    : _controller = StreamController<ScheduleEvent>.broadcast();

  final StreamController<ScheduleEvent> _controller;

  /// Потік подій.
  Stream<ScheduleEvent> get events => _controller.stream;

  /// Публікує подію [event].
  void publish(ScheduleEvent event) => _controller.add(event);

  /// Закриває канал.
  Future<void> close() => _controller.close();
}
