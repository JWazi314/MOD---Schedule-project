import 'package:flutter_test/flutter_test.dart';
import 'package:mod_app/game/progression.dart';
import 'package:mod_app/models/custom_reward.dart';
import 'package:mod_app/models/task.dart';
import 'package:mod_app/pages/achievements_page.dart';

Task sample({
  int streak = 0,
  bool isDone = false,
  List<int> repeatDays = const [0, 1, 2, 3, 4, 5, 6],
  int gold = 10,
}) {
  return Task(
    title: 'Workout',
    difficulty: 1,
    repeatDays: repeatDays,
    gold: gold,
    silver: 5,
    xp: 50,
    section: 'Health',
    isDone: isDone,
    streak: streak,
  );
}

void main() {
  test('XP rolls into levels instead of stopping at 100', () {
    expect(levelForXp(0), 1);
    expect(levelForXp(99), 1);
    expect(xpTowardNextLevel(40), 40);
    expect(levelForXp(100), 2);
    expect(xpTowardNextLevel(100), 0);
    expect(levelForXp(250), 3);
    expect(xpTowardNextLevel(250), 50);
  });

  test('Every third streak day pays 2 extra gold', () {
    expect(streakGoldBonus(1), 0);
    expect(streakGoldBonus(2), 0);
    expect(streakGoldBonus(3), 2);
    expect(streakGoldBonus(6), 2);

    final task = sample();
    expect(collectQuestReward(task), 10);
    expect(task.streak, 1);
    expect(task.isDone, true);

    task.isDone = false;
    task.isDone = false;
    expect(collectQuestReward(task), 10);
    task.isDone = false;
    expect(collectQuestReward(task), 12);
    expect(task.streak, 3);
  });

  test('A missed daily loses its streak and a finished one keeps it', () {
    final monday = DateTime(2026, 10, 19);
    final kept = sample(streak: 2, isDone: true);
    final missed = sample(streak: 4);
    final later = sample(streak: 5, repeatDays: const [1]);
    final todo = sample(streak: 1, repeatDays: const [], isDone: true);

    final broken = rollOverDay([kept, missed, later, todo], monday);

    expect(broken, 1);
    expect(kept.streak, 2);
    expect(kept.isDone, false);
    expect(missed.streak, 0);
    expect(later.streak, 5);
    expect(todo.streak, 1);
    expect(todo.isDone, false);
  });

  test('To-dos do not grow a streak', () {
    final task = sample(repeatDays: const []);
    expect(collectQuestReward(task), 10);
    expect(task.streak, 0);
  });

  test('Custom rewards survive a JSON round trip', () {
    const reward = CustomReward(title: 'Hour of reading', cost: 20);
    final restored = CustomReward.fromJson(reward.toJson());
    expect(restored.title, 'Hour of reading');
    expect(restored.cost, 20);
  });

  test('New achievements follow streaks and shop purchases', () {
    const quiet = ProgressRecord(
      totalCompletedTasks: 0,
      totalHardTasksCompleted: 0,
      xp: 0,
      completedDays: 0,
      bestStreak: 2,
      rewardsBought: 0,
    );
    expect(isAchievementEarned('on_a_roll', quiet), false);
    expect(isAchievementEarned('treat_yourself', quiet), false);

    const earned = ProgressRecord(
      totalCompletedTasks: 1,
      totalHardTasksCompleted: 0,
      xp: 25,
      completedDays: 1,
      bestStreak: 3,
      rewardsBought: 1,
    );
    expect(isAchievementEarned('on_a_roll', earned), true);
    expect(isAchievementEarned('treat_yourself', earned), true);
    expect(achievements.map((item) => item.id), contains('on_a_roll'));
  });
}
