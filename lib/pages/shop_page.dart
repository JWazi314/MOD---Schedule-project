import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shop_item.dart';
import '../models/shop_item_icons.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/shop_item_card.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final items = gameState.discoveredShopItems;
    final lockedCount = gameState.undiscoveredShopItems.length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),

        child: Padding(
          padding: const EdgeInsets.all(18),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Reward Shop',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),

                  IconButton(
                    tooltip: 'Add Reward',
                    onPressed: () => _showItemDialog(context, gameState),
                    icon: const Icon(
                      Icons.add_circle_outline_outlined,
                      size: 28,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                'Gold: ${gameState.gold}',
                style: const TextStyle(fontSize: 22),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_mall,
                                size: 80,
                                color: Colors.amber,
                              ),
                              SizedBox(height: 18),
                              Text(
                                'Your shop is empty.',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Add a reward you actually want, and price it '
                                'yourself.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];

                          return ShopItemCard(
                            item: item,
                            gold: gameState.gold,
                            onBuy: () => gameState.buyItem(item),
                            onEdit: () => _showItemDialog(
                              context,
                              gameState,
                              existing: item,
                            ),
                            onDelete: () =>
                                _confirmDelete(context, gameState, item),
                          );
                        },
                      ),
              ),

              if (lockedCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '$lockedCount reward${lockedCount == 1 ? '' : 's'} still '
                    'waiting to be found on an adventure.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showItemDialog(
    BuildContext context,
    GameState gameState, {
    ShopItem? existing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final isEditing = existing != null;

    String name = existing?.name ?? '';
    String description = existing?.description ?? '';
    int cost = existing?.cost ?? 10;
    String iconId = existing?.iconId ?? 'reward';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Reward' : 'Add Reward'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        initialValue: name,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Reward Name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'enter a reward name';
                          }

                          if (gameState.shopItemNameAlreadyExists(
                            value,
                            ignoredItemId: existing?.id,
                          )) {
                            return 'that reward already exists';
                          }

                          return null;
                        },
                        onSaved: (value) {
                          name = value!.trim();
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        initialValue: description,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        onSaved: (value) {
                          description = value?.trim() ?? '';
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        initialValue: '$cost',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cost in gold',
                        ),
                        validator: (value) {
                          final parsed = int.tryParse(value?.trim() ?? '');

                          if (parsed == null) {
                            return 'enter a whole number';
                          }
                          if (parsed < 0) {
                            return 'cost cannot be negative';
                          }

                          return null;
                        },
                        onSaved: (value) {
                          cost = int.parse(value!.trim());
                        },
                      ),

                      const SizedBox(height: 20),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Icon', style: TextStyle(fontSize: 16)),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: shopItemIcons.entries.map((entry) {
                          final isSelected = entry.key == iconId;

                          return InkWell(
                            borderRadius: AppTheme.borderRadius,
                            onTap: () {
                              setDialogState(() {
                                iconId = entry.key;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.amber.withAlpha(35)
                                    : AppTheme.panel,
                                borderRadius: AppTheme.borderRadius,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.amber
                                      : AppTheme.border,
                                  width: isSelected ? 2 : 1.2,
                                ),
                              ),
                              child: Icon(
                                entry.value,
                                color: isSelected
                                    ? Colors.amber
                                    : Colors.white70,
                                size: 24,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    formKey.currentState!.save();

                    if (isEditing) {
                      gameState.updateShopItem(
                        existing,
                        name: name,
                        description: description,
                        cost: cost,
                        iconId: iconId,
                      );
                    } else {
                      gameState.addShopItem(
                        name: name,
                        description: description,
                        cost: cost,
                        iconId: iconId,
                      );
                    }

                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    GameState gameState,
    ShopItem item,
  ) async {
    final ownedCount = gameState.inventoryCounts[item.id] ?? 0;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete ${item.name}?'),
          content: Text(
            ownedCount == 0
                ? 'This removes the reward from your shop.'
                : 'This removes the reward from your shop and discards the '
                      '$ownedCount you already own.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    gameState.deleteShopItem(item);
  }
}
