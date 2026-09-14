import '../models/task.dart';
import '../models/task_type.dart';
import 'task_value.dart';

/// What a rollover did, so the caller can apply the Vigor hit and tell the
/// player about it.
class RolloverOutcome {
  final int daysProcessed;
  final int daysSkipped;
  final int missedDailies;
  final int vigorLost;
  final int streaksBroken;

  /// Days that closed without dropping a single Daily. These are what the Mod
  /// recovers Vigor on, so a quiet day pays and a sloppy one does not.
  final int restfulDays;

  const RolloverOutcome({
    this.daysProcessed = 0,
    this.daysSkipped = 0,
    this.missedDailies = 0,
    this.vigorLost = 0,
    this.streaksBroken = 0,
    this.restfulDays = 0,
  });

  static const RolloverOutcome none = RolloverOutcome();

  bool get didRun => daysProcessed > 0;
  bool get hurt => vigorLost > 0;
}

/// Closes out the days that passed while the app was shut.
///
/// Written as a pure function over a task list so the date maths can be
/// tested without a widget tree or a clock.
class DailyRollover {
  DailyRollover._();

  /// A fortnight away should not flatten the Mod, so only this many days are
  /// ever judged.
  static const int maxCatchUpDays = 7;

  /// Ceiling on what a single day can cost, no matter how many Dailies were
  /// missed that day.
  static const int maxVigorLossPerDay = 30;

  static DateTime dayStart(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int daysBetween(DateTime from, DateTime to) {
    return dayStart(to).difference(dayStart(from)).inDays;
  }

  static RolloverOutcome run({
    required List<Task> tasks,
    required Map<String, TaskType> sectionTypes,
    required DateTime lastRolloverAt,
    required DateTime now,
  }) {
    final elapsed = daysBetween(lastRolloverAt, now);

    if (elapsed <= 0) {
      return RolloverOutcome.none;
    }

    final processed = elapsed > maxCatchUpDays ? maxCatchUpDays : elapsed;

    final dailies = <Task>[];
    final todos = <Task>[];
    final habits = <Task>[];

    for (final task in tasks) {
      switch (sectionTypes[task.sectionId] ?? TaskType.daily) {
        case TaskType.daily:
          dailies.add(task);
          break;
        case TaskType.todo:
          todos.add(task);
          break;
        case TaskType.habit:
          habits.add(task);
          break;
      }
    }

    var missedDailies = 0;
    var streaksBroken = 0;
    var vigorLost = 0;
    var restfulDays = 0;

    final firstDay = dayStart(lastRolloverAt);

    for (var dayOffset = 0; dayOffset < processed; dayOffset++) {
      final day = firstDay.add(Duration(days: dayOffset));

      // isDone only describes the day the app was last open. Every day after
      // that went by untouched, so those Dailies are misses by definition.
      final canStillBeDone = dayOffset == 0;

      var lossToday = 0;
      var missedToday = 0;

      for (final task in dailies) {
        if (!task.isDueOn(day)) {
          continue;
        }

        if (canStillBeDone && (task.isDone || task.isSkipped)) {
          continue;
        }

        missedDailies++;
        missedToday++;
        if (task.streak > 0) {
          streaksBroken++;
          task.streak = 0;
        }

        task.neglect = TaskValue.afterMiss(
          task.neglect,
          TaskValue.missedDailyStep,
        );

        lossToday += TaskValue.vigorPenalty(task.difficulty);
      }

      vigorLost += lossToday > maxVigorLossPerDay
          ? maxVigorLossPerDay
          : lossToday;

      if (missedToday == 0) {
        restfulDays++;
      }
    }

    for (final task in dailies) {
      task.isDone = false;
      task.isSkipped = false;
      task.completedAt = null;
      task.clearChecklist();
      task.clearReserve();
    }

    // To-Dos never reset and are never punished; they just drift as they age.
    for (final task in todos) {
      if (task.isDone) {
        continue;
      }
      task.neglect = TaskValue.afterMiss(
        task.neglect,
        TaskValue.staleTodoStep * processed,
      );
    }

    // A good habit left alone drifts. A purely bad habit left alone is a win,
    // so it is not counted against the player.
    for (final task in habits) {
      if (!task.isPositive) {
        continue;
      }
      task.neglect = TaskValue.afterMiss(
        task.neglect,
        TaskValue.idleHabitStep * processed,
      );
    }

    return RolloverOutcome(
      daysProcessed: processed,
      daysSkipped: elapsed - processed,
      missedDailies: missedDailies,
      vigorLost: vigorLost,
      streaksBroken: streaksBroken,
      restfulDays: restfulDays,
    );
  }
}
