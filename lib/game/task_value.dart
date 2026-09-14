import 'dart:math';

import 'package:flutter/material.dart';

import '../models/task.dart';

/// One payout from finishing a task or scoring a good habit.
class TaskPayout {
  final Task task;
  final int gold;
  final int silver;
  final int xp;
  final int token;

  const TaskPayout({
    required this.task,
    required this.gold,
    required this.silver,
    required this.xp,
    required this.token,
  });

  String get label => '+$gold gold · +$silver silver · +$xp XP';
}

/// Task rewards, and the hidden neglect value that drives a card's colour.
///
/// Habitica turns neglected tasks bright red and pays out far more for them,
/// which quietly rewards procrastination. Here the colour keeps meaning
/// difficulty and only deepens with age, and the reward drift is small enough
/// that putting something off is never the better play.
class TaskValue {
  TaskValue._();

  // Base rewards by difficulty: easy, medium, hard.
  static const List<int> baseGold = [5, 10, 15];
  static const List<int> baseSilver = [2, 5, 7];
  static const List<int> baseXp = [25, 50, 75];

  /// How far a single roll can drift from the listed base, as a fraction.
  /// Kept small so an easy task can never out-earn a hard one.
  static const double rewardSpread = 0.15;

  /// Override in tests so payouts stay deterministic. 0.5 is the listed base.
  static double Function() nextRoll = _defaultRoll;

  static double _defaultRoll() => Random().nextDouble();

  static void resetRoll() {
    nextRoll = _defaultRoll;
  }

  /// The most a fully neglected task can pay above its base, as a fraction.
  static const double maxRewardBonus = 0.5;

  // How fast neglect builds. Each is one day's worth.
  static const double missedDailyStep = 0.10;
  static const double staleTodoStep = 0.045;
  static const double idleHabitStep = 0.03;

  /// How much of the backlog doing the task clears.
  static const double completionRelief = 0.35;

  static int _difficultyIndex(int difficulty) => difficulty.clamp(0, 2);

  static double rewardMultiplier(double neglect) {
    return 1 + neglect.clamp(0.0, 1.0) * maxRewardBonus;
  }

  static int _scaled(int base, double neglect, double roll) {
    final factor = (1 - rewardSpread) + (roll * 2 * rewardSpread);
    var varied = (base * factor).round();
    if (base <= 3) {
      varied = base + (roll < 0.33 ? -1 : roll > 0.67 ? 1 : 0);
    }
    return max(1, (varied * rewardMultiplier(neglect)).round());
  }

  static int goldFor(Task task, {double? roll}) {
    return _scaled(
      baseGold[_difficultyIndex(task.difficulty)],
      task.neglect,
      roll ?? nextRoll(),
    );
  }

  static int silverFor(Task task, {double? roll}) {
    return _scaled(
      baseSilver[_difficultyIndex(task.difficulty)],
      task.neglect,
      roll ?? nextRoll(),
    );
  }

  static int xpFor(Task task, {double? roll}) {
    return _scaled(
      baseXp[_difficultyIndex(task.difficulty)],
      task.neglect,
      roll ?? nextRoll(),
    );
  }

  static TaskPayout payoutFor(Task task, {int token = 0}) {
    return TaskPayout(
      task: task,
      gold: goldFor(task),
      silver: silverFor(task),
      xp: xpFor(task),
      token: token,
    );
  }

  /// Vigor the Mod loses to a missed Daily or a bad habit.
  static int vigorPenalty(int difficulty) {
    return 3 + _difficultyIndex(difficulty) * 3;
  }

  static double afterCompletion(double neglect) {
    return (neglect - completionRelief).clamp(0.0, 1.0);
  }

  static double afterMiss(double neglect, double step) {
    return (neglect + step).clamp(0.0, 1.0);
  }

  // Hue anchors for easy, medium, and hard. Saturation and lightness are what
  // change with neglect, so the difficulty always reads the same.
  static const List<double> _difficultyHue = [132, 45, 4];

  static const double _minSaturation = 0.40;
  static const double _maxSaturation = 0.95;
  static const double _minLightness = 0.40;
  static const double _maxLightness = 0.58;

  static const double minBorderWidth = 1.6;
  static const double maxBorderWidth = 3.2;

  /// A fresh task renders muted; the same task deepens toward vivid as it is
  /// left alone.
  static Color cardColor(int difficulty, double neglect) {
    final t = neglect.clamp(0.0, 1.0);

    return HSLColor.fromAHSL(
      1,
      _difficultyHue[_difficultyIndex(difficulty)],
      _minSaturation + (_maxSaturation - _minSaturation) * t,
      _minLightness + (_maxLightness - _minLightness) * t,
    ).toColor();
  }

  static double borderWidth(double neglect) {
    final t = neglect.clamp(0.0, 1.0);
    return minBorderWidth + (maxBorderWidth - minBorderWidth) * t;
  }

  static String difficultyLabel(int difficulty) {
    switch (_difficultyIndex(difficulty)) {
      case 0:
        return 'Easy';
      case 1:
        return 'Medium';
      default:
        return 'Hard';
    }
  }
}
