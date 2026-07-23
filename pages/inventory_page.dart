import 'package:flutter/material.dart';

class InventoryPage extends StatelessWidget {
  final List<String> inventory;

  const InventoryPage({
    super.key,
    required this.inventory,
  });

  IconData getItemIcon(String item) {
    switch (item) {
      case 'Cheat Meal':
        return Icons.restaurant;

      case 'Energy Drink':
        return Icons.bolt;

      case 'Gaming Night':
        return Icons.sports_esports;

      default:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, int> itemCounts = {};

    for (var item in inventory) {
      itemCounts[item] = (itemCounts[item] ?? 0) + 1;
    }

    if (itemCounts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2,
              size: 90,
              color: Colors.amber,
            ),
            SizedBox(height: 20),
            Text(
              'Your inventory is empty.',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B2200),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Complete quests and purchase rewards\nfrom the shop to fill it!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final entries = itemCounts.entries.toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: Colors.amber,
                  size: 30,
                ),
                SizedBox(width: 10),
                Text(
                  'Inventory',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final item = entries[index];

                  return Card(
                    color: const Color(0xFF2A1B3D),
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(
                        color: Colors.amber,
                        width: 1.4,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Icon(
                        getItemIcon(item.key),
                        color: Colors.amber,
                      ),
                      title: Text(
                        item.key,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'x${item.value}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}