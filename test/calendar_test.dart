import 'package:flutter_test/flutter_test.dart';
import 'package:quest_tracker/game/calendar.dart';
import 'package:quest_tracker/models/task.dart';
import 'package:quest_tracker/models/task_type.dart';

Task daily({
  String title = 'Water',
  List<int>? repeatDays,
  bool isDone = false,
}) {
  return Task(
    title: title,
    difficulty: 0,
    sectionId: 'dailies',
    repeatDays: repeatDays,
    isDone: isDone,
  );
}

Task todo({
  String title = 'Taxes',
  DateTime? due,
  bool isDone = false,
}) {
  return Task(
    title: title,
    difficulty: 1,
    sectionId: 'todos',
    dueDate: due,
    isDone: isDone,
  );
}

Task habit({String title = 'Read'}) {
  return Task(title: title, difficulty: 1, sectionId: 'habits');
}

TaskType typeOf(Task task) {
  switch (task.sectionId) {
    case 'habits':
      return TaskType.habit;
    case 'todos':
      return TaskType.todo;
    default:
      return TaskType.daily;
  }
}

const visibleAll = {TaskType.habit, TaskType.daily, TaskType.todo};

void main() {
  // 2026-09-01 is a Tuesday.
  final tuesday = DateTime(2026, 9, 1);
  final wednesday = DateTime(2026, 9, 2);
  final monday = DateTime(2026, 8, 31);

  group('dated items', () {
    test('a Daily with no weekdays lands on every day', () {
      final items = Calendar.datedItemsOn(
        tasks: [daily()],
        typeOf: typeOf,
        day: tuesday,
        visible: visibleAll,
      );

      expect(items, hasLength(1));
      expect(items.first.task.title, 'Water');
    });

    test('a Daily only appears on the weekdays it was given', () {
      // 0 is Monday.
      final gym = daily(title: 'Gym', repeatDays: [0]);

      List<CalendarItem> on(DateTime day) {
        return Calendar.datedItemsOn(
          tasks: [gym],
          typeOf: typeOf,
          day: day,
          visible: visibleAll,
        );
      }

      expect(on(monday), hasLength(1));
      expect(on(tuesday), isEmpty);
      expect(on(wednesday), isEmpty);
    });

    test('a To-Do sits on its due date and nowhere else', () {
      final taxes = todo(due: DateTime(2026, 9, 10, 18));

      List<CalendarItem> on(DateTime day) {
        return Calendar.datedItemsOn(
          tasks: [taxes],
          typeOf: typeOf,
          day: day,
          visible: visibleAll,
        );
      }

      expect(on(DateTime(2026, 9, 10)), hasLength(1));
      expect(on(DateTime(2026, 9, 11)), isEmpty);
    });

    test('Habits never appear as dated items', () {
      final items = Calendar.datedItemsOn(
        tasks: [habit()],
        typeOf: typeOf,
        day: tuesday,
        visible: visibleAll,
      );

      expect(items, isEmpty);
    });

    test('To-Dos sit above Dailies on the same day', () {
      final items = Calendar.datedItemsOn(
        tasks: [daily(), todo(due: tuesday)],
        typeOf: typeOf,
        day: tuesday,
        visible: visibleAll,
      );

      expect(items.map((item) => item.type), [TaskType.todo, TaskType.daily]);
    });

    test('a hidden type is left off the day', () {
      final items = Calendar.datedItemsOn(
        tasks: [daily(), todo(due: tuesday)],
        typeOf: typeOf,
        day: tuesday,
        visible: {TaskType.todo},
      );

      expect(items.map((item) => item.type), [TaskType.todo]);
    });
  });

  group('undated lists', () {
    test('Habits are listed when that filter is on', () {
      expect(
        Calendar.habits(
          tasks: [habit(), daily()],
          typeOf: typeOf,
          visible: {TaskType.habit},
        ),
        hasLength(1),
      );
      expect(
        Calendar.habits(
          tasks: [habit()],
          typeOf: typeOf,
          visible: {TaskType.daily},
        ),
        isEmpty,
      );
    });

    test('To-Dos without a due date are kept off the grid', () {
      final items = Calendar.undatedTodos(
        tasks: [todo(), todo(title: 'Dated', due: tuesday)],
        typeOf: typeOf,
        visible: visibleAll,
      );

      expect(items, hasLength(1));
      expect(items.first.task.title, 'Taxes');
    });
  });

  group('done state', () {
    test('a finished Daily only reads as done on today', () {
      final item = CalendarItem(
        task: daily(isDone: true),
        type: TaskType.daily,
      );

      expect(Calendar.showsAsDone(item, tuesday, tuesday), isTrue);
      expect(Calendar.showsAsDone(item, wednesday, tuesday), isFalse);
    });

    test('a finished To-Do stays done on its due date', () {
      final item = CalendarItem(
        task: todo(due: tuesday, isDone: true),
        type: TaskType.todo,
      );

      expect(Calendar.showsAsDone(item, tuesday, wednesday), isTrue);
    });
  });

  group('month maths', () {
    test('September 2026 starts on a Tuesday, so one blank Monday', () {
      expect(Calendar.leadingBlanks(DateTime(2026, 9)), 1);
      expect(Calendar.daysInMonth(DateTime(2026, 9)), 30);
      expect(Calendar.monthTitle(DateTime(2026, 9)), 'September 2026');
    });
  });
}
