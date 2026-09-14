import 'package:flutter/material.dart';

import '../models/shop_item.dart';
import '../models/shop_item_icons.dart';
import '../theme.dart';

class ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final int gold;
  final VoidCallback onBuy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ShopItemCard({
    super.key,
    required this.item,
    required this.gold,
    required this.onBuy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool canAfford = gold >= item.cost;

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 14),
      shape: AppTheme.cardShape(
        sideColor: canAfford ? Colors.amber : Colors.grey,
        width: 1.4,
      ),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Row(
          children: [
            Icon(
              shopItemIcon(item.iconId),
              color: canAfford ? Colors.amber : Colors.grey,
              size: 34,
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.description),
                  ],
                  const SizedBox(height: 4),
                ],
              ),
            ),

            ElevatedButton(
              onPressed: canAfford ? onBuy : null,
              child: Text('${item.cost} gold'),
            ),

            PopupMenuButton<String>(
              tooltip: 'Item Options',
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                  PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}
