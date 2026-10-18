import '../models/task.dart';

const int xpPerLevel = 100;
const int streakBonusEvery = 3;
const int streakBonusGold = 2;

class TaskPayout {
  final int gold;
  final int silver;
  final int xp;

  const TaskPayout(this.gold, this.silver, this.xp);

  static const byDifficulty = <TaskPayout>[
    TaskPayout(5, 2, 25),
    TaskPayout(10, 5, 50),
    TaskPayout(15, 7, 75),
  ];

  static TaskPayout forDifficulty(int difficulty) {
    if (difficulty < 0 || difficulty >= byDifficulty.length) {
      return byDifficulty.first;
    }
    return byDifficulty[difficulty];
  }
}

int levelForXp(int xp) {
  if (xp <= 0) {
    return 1;
  }
  return (xp ~/ xpPerLevel) + 1;
}

int xpTowardNextLevel(int xp) {
  if (xp <= 0) {
    return 0;
  }
  return xp % xpPerLevel;
}

int streakGoldBonus(int streak) {
  if (streak > 0 && streak % streakBonusEvery == 0) {
    return streakBonusGold;
  }
  return 0;
}

/// Clears the day's checkmarks.
///
/// A repeating quest that was scheduled today and left undone loses its streak.
/// To-dos and quests that were not due keep theirs. Returns how many streaks broke.
int rollOverDay(List<Task> tasks, [DateTime? now]) {
  final date = now ?? DateTime.now();
  var broken = 0;

  for (final task in tasks) {
    final missed =
        task.repeatDays.isNotEmpty && task.scheduledOn(date) && !task.isDone;
    if (missed && task.streak > 0) {
      task.streak = 0;
      broken++;
    } else if (missed) {
      task.streak = 0;
    }
    task.isDone = false;
    task.completedAt = null;
  }

  return broken;
}

/// Awards the quest payout and, for repeating quests, grows the streak.
///
/// Returns the gold granted, including a small bonus every third streak day.
int collectQuestReward(Task task) {
  if (task.isDone) {
    return 0;
  }

  task.isDone = true;
  task.completedAt = DateTime.now();

  var gold = task.gold;
  if (task.repeatDays.isNotEmpty) {
    task.streak += 1;
    gold += streakGoldBonus(task.streak);
  }
  return gold;
}
