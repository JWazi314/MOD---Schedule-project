import 'package:flutter/material.dart';

import '../models/custom_reward.dart';
import '../widgets/shop_item_card.dart';

class ShopListing {
  final String title;
  final int cost;
  final String description;
  final IconData icon;

  const ShopListing({
    required this.title,
    required this.cost,
    required this.description,
    required this.icon,
  });
}

const builtInRewards = <ShopListing>[
  ShopListing(
    title: 'Cheat Meal',
    cost: 100,
    description: 'One meal with no rules attached.',
    icon: Icons.restaurant,
  ),
  ShopListing(
    title: 'Gaming Night',
    cost: 75,
    description: 'An evening of games, guilt-free.',
    icon: Icons.sports_esports,
  ),
  ShopListing(
    title: 'Energy Drink',
    cost: 30,
    description: 'A small treat you can cash in today.',
    icon: Icons.bolt,
  ),
];

class ShopPage extends StatelessWidget {
  final int gold;
  final List<CustomReward> customRewards;
  final void Function(int cost, String title) onBuy;
  final void Function(CustomReward reward) onCreate;
  final void Function(CustomReward reward) onDelete;

  const ShopPage({
    super.key,
    required this.gold,
    required this.customRewards,
    required this.onBuy,
    required this.onCreate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reward Shop',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text('Spend gold on a break, or add one of your own.'),
                      ],
                    ),
                  ),
                  const Icon(Icons.monetization_on, color: Color(0xFFC4A35A)),
                  const SizedBox(width: 4),
                  Text(
                    '$gold',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: OutlinedButton.icon(
                onPressed: () => _addReward(context),
                icon: const Icon(Icons.add),
                label: const Text('Add your own reward'),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  if (customRewards.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Yours',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    for (final reward in customRewards)
                      ShopItemCard(
                        title: reward.title,
                        cost: reward.cost,
                        description: reward.description,
                        gold: gold,
                        icon: Icons.redeem,
                        onBuy: () => onBuy(reward.cost, reward.title),
                        onDelete: () => onDelete(reward),
                      ),
                    const SizedBox(height: 8),
                  ],
                  for (final reward in builtInRewards)
                    ShopItemCard(
                      title: reward.title,
                      cost: reward.cost,
                      description: reward.description,
                      gold: gold,
                      icon: reward.icon,
                      onBuy: () => onBuy(reward.cost, reward.title),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addReward(BuildContext context) async {
    final reward = await showDialog<CustomReward>(
      context: context,
      builder: (context) => const _CustomRewardDialog(),
    );
    if (reward != null) {
      onCreate(reward);
    }
  }
}

class _CustomRewardDialog extends StatefulWidget {
  const _CustomRewardDialog();

  @override
  State<_CustomRewardDialog> createState() => _CustomRewardDialogState();
}

class _CustomRewardDialogState extends State<_CustomRewardDialog> {
  final _titleController = TextEditingController();
  int _cost = 10;
  String? _error;

  static const _costs = [10, 25, 50, 100];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Name the reward');
      return;
    }
    Navigator.of(context).pop(CustomReward(title: title, cost: _cost));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your reward'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Hour of reading',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) {
                  setState(() => _error = null);
                }
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            const Text('Gold cost'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final cost in _costs)
                  ChoiceChip(
                    label: Text('$cost'),
                    selected: _cost == cost,
                    onSelected: (_) => setState(() => _cost = cost),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }
}
