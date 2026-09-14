import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/achievement.dart';
import '../state/game_state.dart';
import '../theme.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final unlockedAchievements = context.watch<GameState>()
        .unlockedAchievements;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 32),
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
                  final unlocked = unlockedAchievements.contains(
                    achievement.id,
                  );

                  return Card(
                    color: unlocked ? AppTheme.surface : AppTheme.panel,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: AppTheme.cardShape(
                      sideColor: unlocked ? Colors.amber : Colors.grey.shade700,
                      width: 1.4,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      leading: Icon(
                        unlocked ? Icons.emoji_events : Icons.lock,
                        color: unlocked ? Colors.amber : Colors.grey,
                        size: 34,
                      ),
                      title: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: unlocked ? Colors.white : Colors.grey,
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
                                borderRadius: AppTheme.borderRadius,
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
