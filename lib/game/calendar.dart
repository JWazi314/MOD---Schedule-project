import '../models/task.dart';
import '../models/task_type.dart';

/// A task as it appears on one calendar day.
class CalendarItem {
  final Task task;
  final TaskType type;

  const CalendarItem({required this.task, required this.type});
}

/// Pure helpers for the month view. Kept off the widgets so the date rules
/// can be tested without pumping a page.
class Calendar {
  Calendar._();

  static const List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// To-Dos first, then Dailies. Habits stay last so they can be filtered in
  /// without taking over the month.
  static const List<TaskType> scheduleOrder = [
    TaskType.todo,
    TaskType.daily,
    TaskType.habit,
  ];

  static const List<String> weekdayLabels = [
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String monthTitle(DateTime month) {
    return '${monthNames[month.month - 1]} ${month.year}';
  }

  static DateTime monthStart(DateTime month) {
    return DateTime(month.year, month.month, 1);
  }

  /// How many blank cells sit before the 1st, Monday-first.
  static int leadingBlanks(DateTime month) {
    return monthStart(month).weekday - 1;
  }

  static int daysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }

  /// Dailies on their weekday, To-Dos on their due date.
  ///
  /// Habits are not dated, so they stay out of the month cells and show up
  /// in the selected-day list instead.
  static List<CalendarItem> datedItemsOn({
    required List<Task> tasks,
    required TaskType Function(Task) typeOf,
    required DateTime day,
    required Set<TaskType> visible,
  }) {
    final items = <CalendarItem>[];

    for (final task in tasks) {
      final type = typeOf(task);
      if (!visible.contains(type)) {
        continue;
      }

      switch (type) {
        case TaskType.daily:
          if (task.isDueOn(day)) {
            items.add(CalendarItem(task: task, type: type));
          }
        case TaskType.todo:
          final due = task.dueDate;
          if (due != null && sameDay(due, day)) {
            items.add(CalendarItem(task: task, type: type));
          }
        case TaskType.habit:
          break;
      }
    }

    items.sort((a, b) {
      return scheduleOrder.indexOf(a.type).compareTo(scheduleOrder.indexOf(b.type));
    });
    return items;
  }

  static List<CalendarItem> habits({
    required List<Task> tasks,
    required TaskType Function(Task) typeOf,
    required Set<TaskType> visible,
  }) {
    if (!visible.contains(TaskType.habit)) {
      return const [];
    }

    return [
      for (final task in tasks)
        if (typeOf(task) == TaskType.habit)
          CalendarItem(task: task, type: TaskType.habit),
    ];
  }

  static List<CalendarItem> undatedTodos({
    required List<Task> tasks,
    required TaskType Function(Task) typeOf,
    required Set<TaskType> visible,
  }) {
    if (!visible.contains(TaskType.todo)) {
      return const [];
    }

    return [
      for (final task in tasks)
        if (typeOf(task) == TaskType.todo && task.dueDate == null)
          CalendarItem(task: task, type: TaskType.todo),
    ];
  }

  /// A Daily's [Task.isDone] only describes today. Other days on the month
  /// are just the schedule.
  static bool showsAsDone(CalendarItem item, DateTime day, DateTime today) {
    switch (item.type) {
      case TaskType.habit:
        return false;
      case TaskType.todo:
        return item.task.isDone;
      case TaskType.daily:
        return item.task.isDone && sameDay(day, today);
    }
  }
}
