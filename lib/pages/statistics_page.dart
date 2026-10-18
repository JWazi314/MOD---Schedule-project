import 'package:flutter/material.dart';

import '../game/progression.dart';
import '../models/task.dart';

class StatisticsPage extends StatelessWidget {
  final List<Task> tasks;
  final int gold;
  final int silver;
  final int xp;
  final int totalCompleted;
  final int bestStreak;
  final int rewardsBought;

  const StatisticsPage({
    super.key,
    required this.tasks,
    required this.gold,
    required this.silver,
    required this.xp,
    required this.totalCompleted,
    required this.bestStreak,
    required this.rewardsBought,
  });

  @override
  Widget build(BuildContext context) {
    final dueToday = tasks.where((task) => task.showsOnTodayBoard()).toList();
    final doneToday = dueToday.where((task) => task.isDone).length;
    final todayRate = dueToday.isEmpty ? 0.0 : doneToday / dueToday.length;
    final level = levelForXp(xp);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text('How the days are adding up.'),
            const SizedBox(height: 16),
            Text(
              'Today',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: todayRate,
              minHeight: 12,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: const Color(0xFFE7E1D8),
              color: const Color(0xFF2F6B4F),
            ),
            const SizedBox(height: 6),
            Text('$doneToday of ${dueToday.length} due today'),
            const SizedBox(height: 16),
            _StatisticCard(
              title: 'Level',
              value: '$level',
              icon: Icons.shield,
              color: const Color(0xFF2F6B4F),
            ),
            _StatisticCard(
              title: 'Completed all-time',
              value: '$totalCompleted',
              icon: Icons.check_circle,
              color: const Color(0xFF2F6B4F),
            ),
            _StatisticCard(
              title: 'Best streak',
              value: bestStreak == 1 ? '1 day' : '$bestStreak days',
              icon: Icons.local_fire_department,
              color: const Color(0xFFC4841D),
            ),
            _StatisticCard(
              title: 'Rewards bought',
              value: '$rewardsBought',
              icon: Icons.redeem,
              color: const Color(0xFFC4A35A),
            ),
            _StatisticCard(
              title: 'Gold',
              value: '$gold',
              icon: Icons.monetization_on,
              color: const Color(0xFFC4A35A),
            ),
            _StatisticCard(
              title: 'Silver',
              value: '$silver',
              icon: Icons.toll,
              color: const Color(0xFF8A8A8A),
            ),
            _StatisticCard(
              title: 'Experience',
              value: '$xp XP',
              icon: Icons.star,
              color: const Color(0xFF2F6B4F),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatisticCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
