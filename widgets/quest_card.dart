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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDone
            ? const Color(0xFF1F3A28)
            : const Color(0xFF2A1B3D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone ? Colors.greenAccent : Colors.amber,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDone
                    ? Colors.greenAccent.withValues(alpha: 0.12)
                    : Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isDone ? Colors.greenAccent : Colors.amber,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            color: isDone ? Colors.white70 : Colors.white,
                          ),
                        ),
                      ),
                      if (isDone)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RewardBadge(
                        icon: Icons.monetization_on,
                        label: '$goldReward Gold',
                        color: Colors.amber,
                      ),
                      _RewardBadge(
                        icon: Icons.circle,
                        label: '$silverReward Silver',
                        color: Colors.grey,
                      ),
                      _RewardBadge(
                        icon: Icons.auto_awesome,
                        label: '$xpReward XP',
                        color: Colors.lightBlueAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: isDone ? 'Quest completed' : 'Complete quest',
              child: InkWell(
                onTap: isDone ? null : onComplete,
                borderRadius: BorderRadius.circular(12),
                hoverColor: Colors.greenAccent.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isDone
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isDone ? Colors.greenAccent : Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RewardBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}