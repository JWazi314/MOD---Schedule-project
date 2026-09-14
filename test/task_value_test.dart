import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_tracker/game/task_value.dart';
import 'package:quest_tracker/models/task.dart';

Task task({int difficulty = 1, double neglect = 0}) {
  return Task(
    title: 'Test',
    difficulty: difficulty,
    sectionId: 'dailies',
    neglect: neglect,
  );
}

void main() {
  setUp(() {
    TaskValue.nextRoll = () => 0.5;
  });

  tearDown(TaskValue.resetRoll);

  group('rewards', () {
    test('a fresh task pays exactly its base rate', () {
      expect(TaskValue.goldFor(task(difficulty: 0)), 5);
      expect(TaskValue.silverFor(task(difficulty: 0)), 2);
      expect(TaskValue.xpFor(task(difficulty: 0)), 25);

      expect(TaskValue.goldFor(task(difficulty: 1)), 10);
      expect(TaskValue.silverFor(task(difficulty: 1)), 5);
      expect(TaskValue.xpFor(task(difficulty: 1)), 50);

      expect(TaskValue.goldFor(task(difficulty: 2)), 15);
      expect(TaskValue.silverFor(task(difficulty: 2)), 7);
      expect(TaskValue.xpFor(task(difficulty: 2)), 75);
    });

    test('harder tasks always pay more than easier ones', () {
      expect(
        TaskValue.xpFor(task(difficulty: 2)),
        greaterThan(TaskValue.xpFor(task(difficulty: 1))),
      );
      expect(
        TaskValue.xpFor(task(difficulty: 1)),
        greaterThan(TaskValue.xpFor(task(difficulty: 0))),
      );
    });

    test('the multiplier runs from 1x to 1.5x and no further', () {
      expect(TaskValue.rewardMultiplier(0), 1.0);
      expect(TaskValue.rewardMultiplier(0.5), 1.25);
      expect(TaskValue.rewardMultiplier(1), 1.5);
      expect(TaskValue.rewardMultiplier(4), 1.5);
      expect(TaskValue.rewardMultiplier(-2), 1.0);
    });

    test('a badly neglected task is worth at most half again as much', () {
      final fresh = task(difficulty: 1);
      final stale = task(difficulty: 1, neglect: 1);

      expect(TaskValue.goldFor(stale), 15);
      expect(TaskValue.xpFor(stale), 75);
      expect(
        TaskValue.xpFor(stale),
        lessThanOrEqualTo((TaskValue.xpFor(fresh) * 1.5).round()),
      );
    });

    test('putting off an easy task never beats doing a hard one', () {
      // The whole point of capping the bonus: procrastination must not become
      // the better play.
      expect(
        TaskValue.xpFor(task(difficulty: 0, neglect: 1)),
        lessThan(TaskValue.xpFor(task(difficulty: 2))),
      );
    });

    test('the reward climbs gently rather than in visible jumps', () {
      final oneDay = TaskValue.xpFor(
        task(difficulty: 1, neglect: TaskValue.missedDailyStep),
      );

      expect(oneDay - TaskValue.xpFor(task(difficulty: 1)), lessThan(5));
    });

    test('the same task can pay a little more or less than its listed base', () {
      expect(TaskValue.goldFor(task(difficulty: 1), roll: 0), lessThan(10));
      expect(TaskValue.goldFor(task(difficulty: 1), roll: 1), greaterThan(10));
      expect(TaskValue.goldFor(task(difficulty: 1), roll: 0.5), 10);
    });

    test('a lucky easy task still cannot beat an unlucky hard one', () {
      expect(
        TaskValue.xpFor(task(difficulty: 0, neglect: 1), roll: 1),
        lessThan(TaskValue.xpFor(task(difficulty: 2), roll: 0)),
      );
    });
  });

  group('neglect movement', () {
    test('finishing a task clears most of the backlog', () {
      expect(TaskValue.afterCompletion(0.5), closeTo(0.15, 0.0001));
    });

    test('neglect never falls below zero or climbs past one', () {
      expect(TaskValue.afterCompletion(0.1), 0);
      expect(TaskValue.afterMiss(0.98, 0.5), 1);
    });

    test('a miss adds the step it was given', () {
      expect(
        TaskValue.afterMiss(0.2, TaskValue.missedDailyStep),
        closeTo(0.3, 0.0001),
      );
    });

    test('Dailies rot faster than To-Dos, which rot faster than Habits', () {
      expect(TaskValue.missedDailyStep, greaterThan(TaskValue.staleTodoStep));
      expect(TaskValue.staleTodoStep, greaterThan(TaskValue.idleHabitStep));
    });
  });

  group('colour', () {
    test('difficulty keeps its own hue no matter how neglected', () {
      for (var difficulty = 0; difficulty < 3; difficulty++) {
        final fresh = HSLColor.fromColor(
          TaskValue.cardColor(difficulty, 0),
        ).hue;
        final stale = HSLColor.fromColor(
          TaskValue.cardColor(difficulty, 1),
        ).hue;

        expect(stale, closeTo(fresh, 2));
      }
    });

    test('the three difficulties are visibly different hues', () {
      final hues = [
        for (var difficulty = 0; difficulty < 3; difficulty++)
          HSLColor.fromColor(TaskValue.cardColor(difficulty, 0.5)).hue,
      ];

      expect((hues[0] - hues[1]).abs(), greaterThan(30));
      expect((hues[1] - hues[2]).abs(), greaterThan(30));
    });

    test('the same difficulty deepens as it is left alone', () {
      final fresh = HSLColor.fromColor(TaskValue.cardColor(1, 0));
      final middling = HSLColor.fromColor(TaskValue.cardColor(1, 0.5));
      final stale = HSLColor.fromColor(TaskValue.cardColor(1, 1));

      expect(middling.saturation, greaterThan(fresh.saturation));
      expect(stale.saturation, greaterThan(middling.saturation));
      expect(stale.lightness, greaterThan(fresh.lightness));
    });

    test('the border thickens with neglect but stays bounded', () {
      expect(TaskValue.borderWidth(0), TaskValue.minBorderWidth);
      expect(TaskValue.borderWidth(1), TaskValue.maxBorderWidth);
      expect(
        TaskValue.borderWidth(0.5),
        greaterThan(TaskValue.borderWidth(0)),
      );
      expect(TaskValue.borderWidth(9), TaskValue.maxBorderWidth);
    });
  });

  group('penalties', () {
    test('a harder task costs more Vigor to miss', () {
      expect(TaskValue.vigorPenalty(0), 3);
      expect(TaskValue.vigorPenalty(1), 6);
      expect(TaskValue.vigorPenalty(2), 9);
    });

    test('an out of range difficulty is clamped rather than crashing', () {
      expect(TaskValue.vigorPenalty(99), 9);
      expect(TaskValue.goldFor(task(difficulty: -4)), 5);
    });
  });
}
