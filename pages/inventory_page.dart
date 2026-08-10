import 'package:flutter/material.dart';

class InventoryPage extends StatelessWidget {
  final List<String> inventory;
  final ValueChanged<String> onUse;

  const InventoryPage({
    super.key,
    required this.inventory,
    required this.onUse,
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
    final itemCounts = <String, int>{};

    for (final item in inventory) {
      itemCounts[item] = (itemCounts[item] ?? 0) + 1;
    }

    if (itemCounts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2, size: 90, color: Colors.amber),
              SizedBox(height: 20),
              Text(
                'Your inventory is empty.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Purchase rewards from the shop to fill it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final entries = itemCounts.entries.toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.inventory_2, color: Colors.amber, size: 30),
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
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final item = entries[index];

                    return Card(
                      color: const Color.fromARGB(50, 50, 50, 50),
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(
                          color: Colors.amber,
                          width: 1.4,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              getItemIcon(item.key),
                              color: Colors.amber,
                              size: 32,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.key,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
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
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => onUse(item.key),
                              child: const Text('Use'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
