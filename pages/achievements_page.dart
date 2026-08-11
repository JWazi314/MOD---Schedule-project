import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final int reward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
  });
}

const List<Achievement> achievements = [
  Achievement(
    id: 'first_task',
    title: 'One Small Step',
    description: 'Complete your first task.',
    reward: 25,
  ),
  Achievement(
    id: 'getting_serious',
    title: 'Getting Serious',
    description: 'Complete 10 tasks.',
    reward: 50,
  ),
  Achievement(
    id: 'task_master',
    title: 'Task Master',
    description: 'Complete 25 tasks.',
    reward: 75,
  ),
  Achievement(
    id: 'rising_star',
    title: 'Rising Star',
    description: 'Earn 500 XP.',
    reward: 75,
  ),
  Achievement(
    id: 'hard_worker',
    title: 'Hard Worker',
    description: 'Complete 5 Hard tasks.',
    reward: 75,
  ),
  Achievement(
    id: 'dedicated',
    title: 'Dedicated',
    description: 'Complete tasks on 7 different days.',
    reward: 100,
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
            const SizedBox(height: 20),

            const Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 32,
                ),
                SizedBox(width: 10),
                Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
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
                    color: unlocked
                        ? const Color(0xFF2A1B3D)
                        : const Color(0xFF202020),
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: unlocked
                            ? Colors.amber
                            : Colors.grey.shade700,
                        width: 1.4,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      leading: Icon(
                        unlocked
                            ? Icons.emoji_events
                            : Icons.lock,
                        color: unlocked
                            ? Colors.amber
                            : Colors.grey,
                        size: 34,
                      ),
                      title: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: unlocked
                              ? Colors.white
                              : Colors.grey,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          achievement.description,
                          style: TextStyle(
                            color: unlocked
                                ? Colors.white70
                                : Colors.grey.shade600,
                          ),
                        ),
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