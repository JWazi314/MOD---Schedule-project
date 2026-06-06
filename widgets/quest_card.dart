import 'package:flutter/material.dart';

class QuestCard extends StatelessWidget {
  final String title;
  final int goldReward;
  final int silverReward;
  final int xpReward;
  final bool isDone;
  final IconData icon;
  final VoidCallback onComplete;

  const QuestCard({
    super.key,
    required this.title,
    required this.goldReward,
    required this.silverReward,
    required this.xpReward,
    required this.isDone,
    required this.icon,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 41, 24, 2),
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDone ? const Color.fromARGB(255, 51, 255, 0) : Colors.amber,
          width: 1.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDone ? const Color.fromARGB(255, 29, 252, 0) : Colors.amber,
              size: 34,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                    ],
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: isDone ? null : onComplete,
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              hoverColor: Colors.greenAccent.withValues(alpha: 0.15),
              child: Icon(
                isDone ? Icons.check_box : Icons.check_box_outline_blank,
                color: isDone ? Colors.greenAccent : Colors.white54,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
