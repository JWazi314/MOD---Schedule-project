import 'package:flutter/material.dart';
import '../widgets/shop_item_card.dart';

class ShopPage extends StatelessWidget {
  final int silver;
  final int gold;
  final void Function(int cost, String title) onBuy;

  const ShopPage({
    super.key,
    required this.silver,
    required this.gold,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),

        child: Padding(
          padding: const EdgeInsets.all(18),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              const Text(
                'Reward Shop',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),

              const SizedBox(height: 12),

              Text('Gold: $gold', style: const TextStyle(fontSize: 22)),

              const SizedBox(height: 20),

              ShopItemCard(
                title: 'Cheat Meal',
                cost: 100,
                description: 'Use this for one fun meal.',
                gold: gold,
                onBuy: () => onBuy(100, 'Cheat Meal'),
              ),

              ShopItemCard(
                title: 'Gaming Night',
                cost: 75,
                description: 'Take a night to play games guilt-free.',
                gold: gold,
                onBuy: () => onBuy(75, 'Gaming Night'),
              ),

              ShopItemCard(
                title: 'Energy Drink',
                cost: 30,
                description: 'Buy one drink as a small reward.',
                gold: gold,
                onBuy: () => onBuy(30, 'Energy Drink'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
