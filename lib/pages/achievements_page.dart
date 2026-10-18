import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final int reward;
  final IconData icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.icon,
  });
}

class ProgressRecord {
  final int totalCompletedTasks;
  final int totalHardTasksCompleted;
  final int xp;
  final int completedDays;
  final int bestStreak;
  final int rewardsBought;

  const ProgressRecord({
    required this.totalCompletedTasks,
    required this.totalHardTasksCompleted,
    required this.xp,
    required this.completedDays,
    required this.bestStreak,
    required this.rewardsBought,
  });
}

bool isAchievementEarned(String id, ProgressRecord record) {
  switch (id) {
    case 'first_task':
      return record.totalCompletedTasks >= 1;
    case 'getting_serious':
      return record.totalCompletedTasks >= 10;
    case 'task_master':
      return record.totalCompletedTasks >= 25;
    case 'rising_star':
      return record.xp >= 500;
    case 'hard_worker':
      return record.totalHardTasksCompleted >= 5;
    case 'dedicated':
      return record.completedDays >= 7;
    case 'on_a_roll':
      return record.bestStreak >= 3;
    case 'treat_yourself':
      return record.rewardsBought >= 1;
    default:
      return false;
  }
}

const List<Achievement> achievements = [
  Achievement(
    id: 'first_task',
    title: 'One Small Step',
    description: 'Complete your first quest.',
    reward: 25,
    icon: Icons.flag,
  ),
  Achievement(
    id: 'getting_serious',
    title: 'Getting Serious',
    description: 'Complete 10 quests.',
    reward: 50,
    icon: Icons.trending_up,
  ),
  Achievement(
    id: 'task_master',
    title: 'Task Master',
    description: 'Complete 25 quests.',
    reward: 75,
    icon: Icons.military_tech,
  ),
  Achievement(
    id: 'rising_star',
    title: 'Rising Star',
    description: 'Earn 500 XP.',
    reward: 75,
    icon: Icons.star,
  ),
  Achievement(
    id: 'hard_worker',
    title: 'Hard Worker',
    description: 'Complete 5 hard quests.',
    reward: 75,
    icon: Icons.fitness_center,
  ),
  Achievement(
    id: 'dedicated',
    title: 'Dedicated',
    description: 'Finish quests on 7 different days.',
    reward: 100,
    icon: Icons.calendar_month,
  ),
  Achievement(
    id: 'on_a_roll',
    title: 'On a Roll',
    description: 'Reach a 3-day streak.',
    reward: 40,
    icon: Icons.local_fire_department,
  ),
  Achievement(
    id: 'treat_yourself',
    title: 'Treat Yourself',
    description: 'Buy a reward from the shop.',
    reward: 20,
    icon: Icons.redeem,
  ),
];

class AchievementsPage extends StatelessWidget {
  final Set<String> unlockedAchievements;

  const AchievementsPage({
    super.key,
    required this.unlockedAchievements,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Color(0xFFC4A35A), size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Achievements',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  final unlocked =
                      unlockedAchievements.contains(achievement.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: unlocked
                            ? const Color(0xFFC4A35A)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      leading: Icon(
                        unlocked ? achievement.icon : Icons.lock,
                        color: unlocked ? const Color(0xFFC4A35A) : Colors.grey,
                        size: 30,
                      ),
                      title: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: unlocked ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(achievement.description),
                      ),
                      trailing: unlocked
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withAlpha(35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+${achievement.reward} Gold',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const Text(
                              'LOCKED',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}