import 'package:flutter/material.dart';

/// The three kinds of task, borrowed from Habitica.
///
/// The type lives on the section rather than the task, so a section is a
/// column of one kind and moving a task between columns converts it.
enum TaskType { habit, daily, todo }

extension TaskTypeInfo on TaskType {
  /// Plural, used for section names and column headers.
  String get label {
    switch (this) {
      case TaskType.habit:
        return 'Habits';
      case TaskType.daily:
        return 'Dailies';
      case TaskType.todo:
        return 'To-Dos';
    }
  }

  String get singularLabel {
    switch (this) {
      case TaskType.habit:
        return 'Habit';
      case TaskType.daily:
        return 'Daily';
      case TaskType.todo:
        return 'To-Do';
    }
  }

  String get description {
    switch (this) {
      case TaskType.habit:
        return 'Behaviour you want to encourage or discourage. Tap it as '
            'often as it happens.';
      case TaskType.daily:
        return 'Scheduled on set days. Builds a streak, and missing it wears '
            'the Mod down.';
      case TaskType.todo:
        return 'A one-off. Finish it whenever, with no penalty for taking '
            'your time.';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskType.habit:
        return Icons.autorenew;
      case TaskType.daily:
        return Icons.event_repeat;
      case TaskType.todo:
        return Icons.checklist;
    }
  }

  String get id => name;
}

TaskType taskTypeFromId(String? id, {TaskType fallback = TaskType.daily}) {
  for (final type in TaskType.values) {
    if (type.name == id) {
      return type;
    }
  }
  return fallback;
}
