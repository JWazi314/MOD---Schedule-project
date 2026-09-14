import 'package:flutter_test/flutter_test.dart';
import 'package:quest_tracker/game/daily_rollover.dart';
import 'package:quest_tracker/game/task_value.dart';
import 'package:quest_tracker/models/checklist_item.dart';
import 'package:quest_tracker/models/task.dart';
import 'package:quest_tracker/models/task_type.dart';

const Map<String, TaskType> sectionTypes = {
  'habits': TaskType.habit,
  'dailies': TaskType.daily,
  'todos': TaskType.todo,
};

Task daily({
  String title = 'Water',
  int difficulty = 1,
  List<int>? repeatDays,
  bool isDone = false,
  int streak = 0,
  double neglect = 0,
}) {
  return Task(
    title: title,
    difficulty: difficulty,
    sectionId: 'dailies',
    repeatDays: repeatDays,
    isDone: isDone,
    streak: streak,
    neglect: neglect,
  );
}

Task todo({bool isDone = false, double neglect = 0}) {
  return Task(
    title: 'Taxes',
    difficulty: 1,
    sectionId: 'todos',
    isDone: isDone,
    neglect: neglect,
  );
}

Task habit({bool isPositive = true, bool isNegative = false}) {
  return Task(
    title: 'Read',
    difficulty: 1,
    sectionId: 'habits',
    isPositive: isPositive,
    isNegative: isNegative,
  );
}

RolloverOutcome run(
  List<Task> tasks, {
  required DateTime from,
  required DateTime to,
}) {
  return DailyRollover.run(
    tasks: tasks,
    sectionTypes: sectionTypes,
    lastRolloverAt: from,
    now: to,
  );
}

void main() {
  final monday = DateTime(2026, 1, 12, 9);

  group('when nothing has changed', () {
    test('the same day does nothing at all', () {
      final task = daily(isDone: true, streak: 4);

      final outcome = run(
        [task],
        from: monday,
        to: monday.add(const Duration(hours: 6)),
      );

      expect(outcome.didRun, isFalse);
      expect(task.isDone, isTrue);
      expect(task.streak, 4);
      expect(task.neglect, 0);
    });

    test('a clock that has gone backwards is ignored', () {
      final task = daily();

      final outcome = run(
        [task],
        from: monday,
        to: monday.subtract(const Duration(days: 3)),
      );

      expect(outcome.didRun, isFalse);
      expect(task.neglect, 0);
    });
  });

  group('Dailies', () {
    test('a missed Daily breaks the streak and costs Vigor', () {
      final task = daily(streak: 6);

      final outcome = run(
        [task],
        from: monday,
        to: monday.add(const Duration(days: 1)),
      );

      expect(outcome.didRun, isTrue);
      expect(outcome.missedDailies, 1);
      expect(outcome.streaksBroken, 1);
      expect(outcome.vigorLost, TaskValue.vigorPenalty(1));
      expect(task.streak, 0);
      expect(task.neglect, closeTo(TaskValue.missedDailyStep, 0.0001));
    });

    test('a Daily that was finished is not punished, only reset', () {
      final task = daily(isDone: true, streak: 6);

      final outcome = run(
        [task],
        from: monday,
        to: monday.add(const Duration(days: 1)),
      );

      expect(outcome.missedDailies, 0);
      expect(outcome.vigorLost, 0);
      expect(task.streak, 6);
      expect(task.neglect, 0);
      expect(task.isDone, isFalse);
      expect(task.completedAt, isNull);
    });

    test('every day away counts, not just the last one', () {
      final task = daily();

      final outcome = run(
        [task],
        from: monday,
        to: monday.add(const Duration(days: 3)),
      );

      expect(outcome.daysProcessed, 3);
      expect(outcome.missedDailies, 3);
      expect(task.neglect, closeTo(TaskValue.missedDailyStep * 3, 0.0001));
    });

    test('finishing before closing the app only covers that first day', () {
      final task = daily(isDone: true);

      final outcome = run(
        [task],
        from: monday,
        to: monday.add(const Duration(days: 3)),
      );

      expect(outcome.missedDailies, 2);
    });

    test('a Daily is only judged on the weekdays it is scheduled', () {
      // Monday and Wednesday only, over Monday through Thursday.
      final task = daily(repeatDays: [0, 2]);

      final outcome = run(
        [task],
        from: monday,
        to: monday.add(const Duration(days: 3)),
      );

      expect(outcome.daysProcessed, 3);
      expect(outcome.missedDailies, 2);
    });

    test('a long absence is capped so the Mod is not flattened', () {
      final task = daily();

      final outcome = run(
        [task],
        from: monday,
        to: monday.add(const Duration(days: 40)),
      );

      expect(outcome.daysProcessed, DailyRollover.maxCatchUpDays);
      expect(outcome.daysSkipped, 40 - DailyRollover.maxCatchUpDays);
      expect(outcome.missedDailies, DailyRollover.maxCatchUpDays);
    });

    test('neglect saturates instead of running away', () {
      final task = daily(neglect: 0.95);

      run([task], from: monday, to: monday.add(const Duration(days: 7)));

      expect(task.neglect, 1);
    });

    test('one disastrous day has a ceiling on what it can cost', () {
      final tasks = [
        for (var i = 0; i < 20; i++) daily(title: 'Daily $i', difficulty: 2),
      ];

      final outcome = run(
        tasks,
        from: monday,
        to: monday.add(const Duration(days: 1)),
      );

      expect(outcome.missedDailies, 20);
      expect(outcome.vigorLost, DailyRollover.maxVigorLossPerDay);
    });

    test('a fresh day clears the parts along with the tick', () {
      final task = daily(isDone: true);
      task.checklist.addAll([
        ChecklistItem(id: 'a', title: 'Step A', isDone: true),
        ChecklistItem(id: 'b', title: 'Step B', isDone: true),
      ]);

      run([task], from: monday, to: monday.add(const Duration(days: 1)));

      expect(task.isDone, isFalse);
      expect(task.completedParts, 0);
      expect(task.checklist, hasLength(2));
    });

    test('a task with no streak to break does not report one', () {
      final outcome = run(
        [daily(streak: 0)],
        from: monday,
        to: monday.add(const Duration(days: 1)),
      );

      expect(outcome.missedDailies, 1);
      expect(outcome.streaksBroken, 0);
    });
  });

  group('To-Dos', () {
    test('keep their part progress across a day boundary', () {
      final task = todo();
      task.checklist.add(ChecklistItem(id: 'a', title: 'Step A', isDone: true));

      run([task], from: monday, to: monday.add(const Duration(days: 2)));

      expect(task.completedParts, 1);
    });

    test('are never reset and never cost Vigor', () {
      final task = todo(isDone: true);

      final outcome = run(
        [task],
        from: monday,
        to: monday.add(const Duration(days: 2)),
      );

      expect(task.isDone, isTrue);
      expect(outcome.vigorLost, 0);
      expect(task.neglect, 0);
    });

    test('an unfinished one drifts slowly with the days', () {
      final task = todo();

      run([task], from: monday, to: monday.add(const Duration(days: 4)));

      expect(task.neglect, closeTo(TaskValue.staleTodoStep * 4, 0.0001));
    });
  });

  group('Habits', () {
    test('a good habit left alone drifts', () {
      final task = habit();

      run([task], from: monday, to: monday.add(const Duration(days: 3)));

      expect(task.neglect, closeTo(TaskValue.idleHabitStep * 3, 0.0001));
    });

    test('a purely bad habit left alone is a win, not a miss', () {
      final task = habit(isPositive: false, isNegative: true);

      final outcome = run(
        [task],
        from: monday,
        to: monday.add(const Duration(days: 5)),
      );

      expect(task.neglect, 0);
      expect(outcome.vigorLost, 0);
    });
  });

  group('day maths', () {
    test('counts calendar boundaries, not elapsed hours', () {
      final lateMonday = DateTime(2026, 1, 12, 23, 30);
      final earlyTuesday = DateTime(2026, 1, 13, 0, 30);

      expect(DailyRollover.daysBetween(lateMonday, earlyTuesday), 1);
      expect(
        DailyRollover.daysBetween(monday, DateTime(2026, 1, 12, 23, 59)),
        0,
      );
    });
  });

  test('a task in an unknown section is treated as a Daily', () {
    final orphan = Task(
      title: 'Orphan',
      difficulty: 0,
      sectionId: 'deleted-section',
    );

    final outcome = run(
      [orphan],
      from: monday,
      to: monday.add(const Duration(days: 1)),
    );

    expect(outcome.missedDailies, 1);
  });
}
