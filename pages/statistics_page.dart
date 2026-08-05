import 'package:flutter/material.dart';
import '../models/task.dart';

class StatisticsPage extends StatelessWidget {
  final List<Task> tasks;
  final int gold;
  final int silver;
  final int xp;

  const StatisticsPage({
    super.key,
    required this.tasks,
    required this.gold,
    required this.silver,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final int completedTasks = tasks.where((task) => task.isDone).length;
    final int totalTasks = tasks.length;

    final double completionRate =
        totalTasks == 0 ? 0 : completedTasks / totalTasks;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),

              const SizedBox(height: 20),

              _StatisticCard(
                title: 'Tasks Completed',
                value: '$completedTasks / $totalTasks',
                icon: Icons.check_circle,
              ),

              _StatisticCard(
                title: 'Completion Rate',
                value: '${(completionRate * 100).round()}%',
                icon: Icons.bar_chart,
              ),

              _StatisticCard(
                title: 'Gold',
                value: '$gold',
                icon: Icons.monetization_on,
              ),

              _StatisticCard(
                title: 'Silver',
                value: '$silver',
                icon: Icons.circle,
              ),

              _StatisticCard(
                title: 'Experience',
                value: '$xp XP',
                icon: Icons.star,
              ),

              const SizedBox(height: 12),

              const Text(
                'Daily Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              LinearProgressIndicator(
                value: completionRate,
                minHeight: 14,
                borderRadius: BorderRadius.circular(10),
                backgroundColor: Colors.grey.shade800,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatisticCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.amber,
          size: 30,
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}