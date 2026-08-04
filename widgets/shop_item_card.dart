import 'package:flutter/material.dart';

class ShopItemCard extends StatelessWidget {
  final String title;
  final int cost;
  final String description;
  final int gold;
  final VoidCallback onBuy;

  const ShopItemCard({
    super.key,
    required this.title,
    required this.cost,
    required this.description,
    required this.gold,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final bool canAfford = gold >= cost;

    return Card(
      color: const Color(0xFF2A1B3D),
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: canAfford ? Colors.amber : Colors.grey,
          width: 1.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.local_mall,
              color: canAfford ? Colors.amber : Colors.grey,
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
                  Text(description),
                  const SizedBox(height: 4),
                  Text('$cost gold', style: const TextStyle(color: Colors.amber)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: canAfford ? onBuy : null,
              child: const Text('Buy'),
            ),
          ],
        ),
      ),
    );
  }
}
