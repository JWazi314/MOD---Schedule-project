import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/game_state.dart';
import '../theme.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final mod = gameState.mod;

    final completedTasks = gameState.tasks.where((task) => task.isDone).length;
    final totalTasks = gameState.tasks.length;
    final completionRate = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

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
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              if (mod != null)
                _StatisticCard(
                  title: '${mod.name}\'s Level',
                  value: '${mod.level}',
                  icon: Icons.trending_up,
                  color: AppTheme.accentBlue,
                ),
              _StatisticCard(
                title: 'Tasks Completed',
                value: '$completedTasks / $totalTasks',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _StatisticCard(
                title: 'Completion Rate',
                value: '${(completionRate * 100).toStringAsFixed(0)}%',
                icon: Icons.percent,
                color: Colors.green,
              ),
              _StatisticCard(
                title: 'Gold',
                value: '${gameState.gold}',
                icon: Icons.monetization_on,
                color: Colors.amber,
              ),
              _StatisticCard(
                title: 'Silver',
                value: '${gameState.silver}',
                icon: Icons.circle,
                color: Colors.grey,
              ),
              _StatisticCard(
                title: 'Total XP Earned',
                value: '${gameState.lifetimeXp}',
                icon: Icons.star,
                color: const Color.fromARGB(255, 0, 22, 148),
              ),
              const SizedBox(height: 12),
              const Text(
                'Daily Progress',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: completionRate,
                minHeight: 14,
                borderRadius: AppTheme.borderRadius,
                backgroundColor: AppTheme.track,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
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
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: AppTheme.cardShape(sideColor: color, width: 1.4),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
