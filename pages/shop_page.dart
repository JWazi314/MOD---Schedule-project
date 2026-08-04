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
        child: SingleChildScrollView(
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

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1B3D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.amber,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CurrencyDisplay(
                      icon: Icons.monetization_on,
                      label: 'Gold',
                      amount: gold,
                      color: Colors.amber,
                    ),
                    _CurrencyDisplay(
                      icon: Icons.circle,
                      label: 'Silver',
                      amount: silver,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const _SectionTitle(
                title: 'Food Rewards',
                icon: Icons.restaurant,
              ),

              ShopItemCard(
                title: 'Cheat Meal',
                cost: 100,
                description: 'Enjoy one fun meal without feeling guilty.',
                gold: gold,
                onBuy: () => onBuy(100, 'Cheat Meal'),
              ),

              ShopItemCard(
                title: 'Coffee Run',
                cost: 45,
                description: 'Treat yourself to your favorite coffee.',
                gold: gold,
                onBuy: () => onBuy(45, 'Coffee Run'),
              ),

              ShopItemCard(
                title: 'Energy Drink',
                cost: 30,
                description: 'Buy one drink as a small reward.',
                gold: gold,
                onBuy: () => onBuy(30, 'Energy Drink'),
              ),

              const SizedBox(height: 10),

              const _SectionTitle(
                title: 'Entertainment Rewards',
                icon: Icons.sports_esports,
              ),

              ShopItemCard(
                title: 'Gaming Night',
                cost: 75,
                description: 'Take a night to play games guilt-free.',
                gold: gold,
                onBuy: () => onBuy(75, 'Gaming Night'),
              ),

              ShopItemCard(
                title: 'Movie Night',
                cost: 60,
                description: 'Watch a movie and take time to relax.',
                gold: gold,
                onBuy: () => onBuy(60, 'Movie Night'),
              ),

              ShopItemCard(
                title: 'Extra Screen Time',
                cost: 40,
                description: 'Use one extra hour of screen time.',
                gold: gold,
                onBuy: () => onBuy(40, 'Extra Screen Time'),
              ),

              const SizedBox(height: 10),

              const _SectionTitle(
                title: 'Personal Rewards',
                icon: Icons.self_improvement,
              ),

              ShopItemCard(
                title: 'Rest Day',
                cost: 150,
                description: 'Take a planned day off from your routine.',
                gold: gold,
                onBuy: () => onBuy(150, 'Rest Day'),
              ),

              ShopItemCard(
                title: 'Sleep In',
                cost: 85,
                description: 'Give yourself permission to sleep in.',
                gold: gold,
                onBuy: () => onBuy(85, 'Sleep In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.amber,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyDisplay extends StatelessWidget {
  final IconData icon;
  final String label;
  final int amount;
  final Color color;

  const _CurrencyDisplay({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $amount',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}