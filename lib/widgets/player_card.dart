import 'package:flutter/material.dart';

import '../game/progression.dart';

class PlayerCard extends StatelessWidget {
  final String name;
  final int gold;
  final int silver;
  final int xp;
  final int streak;

  const PlayerCard({
    super.key,
    required this.name,
    required this.gold,
    required this.silver,
    required this.xp,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final level = levelForXp(xp);
    final intoLevel = xpTowardNextLevel(xp);
    final progress = intoLevel / xpPerLevel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4DDD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF2F6B4F),
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Level $level',
                      style: const TextStyle(
                        color: Color(0xFF2F6B4F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(
                icon: Icons.monetization_on,
                label: '$gold gold',
                color: const Color(0xFFC4A35A),
              ),
              _StatPill(
                icon: Icons.toll,
                label: '$silver silver',
                color: const Color(0xFF8A8A8A),
              ),
              if (streak > 0)
                _StatPill(
                  icon: Icons.local_fire_department,
                  label: '$streak streak',
                  color: const Color(0xFFC4841D),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('$intoLevel / $xpPerLevel XP to level ${level + 1}'),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: const Color(0xFFE7E1D8),
            color: const Color(0xFF2F6B4F),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
