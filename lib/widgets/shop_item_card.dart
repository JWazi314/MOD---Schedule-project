import 'package:flutter/material.dart';

class ShopItemCard extends StatelessWidget {
  final String title;
  final int cost;
  final String description;
  final int gold;
  final IconData icon;
  final VoidCallback onBuy;
  final VoidCallback? onDelete;

  const ShopItemCard({
    super.key,
    required this.title,
    required this.cost,
    required this.description,
    required this.gold,
    required this.icon,
    required this.onBuy,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = gold >= cost;
    final accent = canAfford ? const Color(0xFFC4A35A) : const Color(0xFFB0B0B0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.16),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(description),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Remove reward',
                onPressed: onDelete,
                icon: const Icon(Icons.close),
              ),
            const SizedBox(width: 4),
            FilledButton.tonal(
              onPressed: canAfford ? onBuy : null,
              child: Text('$cost gold'),
            ),
          ],
        ),
      ),
    );
  }
}
