import 'package:flutter/material.dart';

class PlayerCard extends StatelessWidget {
  final int gold;
  final int silver;
  final int xp;

  const PlayerCard({
    super.key,
    required this.gold,
    required this.silver,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final double xpProgress = (xp / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color.fromARGB(200, 100, 100, 100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber, width: 1.5),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Silver: $silver',
            style: const TextStyle(fontSize: 15, color: Colors.grey),
          ),

          Text(
            'Gold: $gold',
            style: const TextStyle(fontSize: 15, color: Colors.amber),
          ),

          const SizedBox(height: 12),

          Text('XP: $xp / 100'),

          const SizedBox(height: 6),

          LinearProgressIndicator(
            value: xpProgress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color.fromARGB(255, 0, 22, 148),
            ),
          ),
        ],
      ),
    );
  }
}
