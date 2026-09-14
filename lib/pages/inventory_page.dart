import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shop_item.dart';
import '../models/shop_item_icons.dart';
import '../models/task.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/item_slot.dart';
import '../widgets/mod_portrait.dart';

class _GearSlot {
  final String id;
  final String label;
  final IconData icon;

  const _GearSlot(this.id, this.label, this.icon);
}

const _leftGear = [
  _GearSlot('head', 'Head', Icons.face),
  _GearSlot('shoulders', 'Shoulders', Icons.view_week),
  _GearSlot('chest', 'Chest', Icons.shield),
  _GearSlot('hands', 'Hands', Icons.front_hand),
  _GearSlot('legs', 'Legs', Icons.accessibility),
  _GearSlot('mainHand', 'Main Hand', Icons.flash_on),
];

const _rightGear = [
  _GearSlot('neck', 'Neck', Icons.diamond),
  _GearSlot('back', 'Back', Icons.layers),
  _GearSlot('waist', 'Waist', Icons.horizontal_rule),
  _GearSlot('feet', 'Feet', Icons.directions_walk),
  _GearSlot('charm', 'Charm', Icons.auto_awesome),
  _GearSlot('offHand', 'Off Hand', Icons.security),
];

const int _bagSlots = 20;
const int _bagColumns = 4;

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String? _selectedItemId;

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final counts = gameState.inventoryCounts;
    final bagItems = counts.entries.toList();

    if (_selectedItemId != null && !counts.containsKey(_selectedItemId)) {
      _selectedItemId = null;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, color: Colors.amber, size: 26),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Inventory',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
              Text(
                '${gameState.gold}g',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide = constraints.maxWidth >= 720;
                final paperdoll = _PaperdollPane(gameState: gameState);
                final bag = _BagPane(
                  gameState: gameState,
                  bagItems: bagItems,
                  selectedItemId: _selectedItemId,
                  onSelect: (id) {
                    setState(() => _selectedItemId = id);
                  },
                  onUse: (id) => _useItem(context, gameState, id),
                );

                if (sideBySide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: paperdoll),
                      const SizedBox(width: 12),
                      SizedBox(width: 280, child: bag),
                    ],
                  );
                }

                return Column(
                  children: [
                    Expanded(flex: 3, child: paperdoll),
                    const SizedBox(height: 12),
                    Expanded(flex: 2, child: bag),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useItem(
    BuildContext context,
    GameState gameState,
    String itemId,
  ) async {
    if (itemId != ShopItem.skipTokenId) {
      gameState.useInventoryItem(itemId);
      return;
    }

    final dailies = gameState.skippableDailies();
    if (dailies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Dailies to skip today.')),
      );
      return;
    }

    final chosen = await showDialog<Task>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Skip which Daily?'),
          children: [
            for (final task in dailies)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(task),
                child: Text(task.title),
              ),
          ],
        );
      },
    );

    if (chosen == null) {
      return;
    }

    gameState.skipDaily(chosen);
  }
}

class _PaperdollPane extends StatelessWidget {
  final GameState gameState;

  const _PaperdollPane({required this.gameState});

  @override
  Widget build(BuildContext context) {
    final mod = gameState.mod;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        children: [
          Text(
            mod?.name ?? 'No Mod',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (mod != null)
            Text(
              'Level ${mod.level}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _slotColumn(_leftGear),
                Expanded(child: _doll(mod?.appearanceId)),
                _slotColumn(_rightGear),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotColumn(List<_GearSlot> slots) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final slot in slots)
          ItemSlot(
            key: ValueKey('gear-${slot.id}'),
            size: 44,
            tooltip: slot.label,
            icon: slot.icon,
            empty: true,
          ),
      ],
    );
  }

  Widget _doll(String? appearanceId) {
    return Center(
      child: Container(
        width: 168,
        height: 188,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: AppTheme.borderRadius,
          border: Border.all(color: AppTheme.border),
        ),
        child: appearanceId == null
            ? Icon(
                Icons.person,
                size: 72,
                color: Colors.white.withValues(alpha: 0.2),
              )
            : Center(
                child: ModPortrait(appearanceId: appearanceId, size: 148),
              ),
      ),
    );
  }
}

class _BagPane extends StatelessWidget {
  final GameState gameState;
  final List<MapEntry<String, int>> bagItems;
  final String? selectedItemId;
  final ValueChanged<String?> onSelect;
  final ValueChanged<String> onUse;

  const _BagPane({
    required this.gameState,
    required this.bagItems,
    required this.selectedItemId,
    required this.onSelect,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedItemId == null
        ? null
        : gameState.shopItemById(selectedItemId!);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Bags',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              itemCount: _bagSlots,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _bagColumns,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                if (index >= bagItems.length) {
                  return const ItemSlot(empty: true);
                }

                final entry = bagItems[index];
                final item = gameState.shopItemById(entry.key);
                return ItemSlot(
                  key: ValueKey('bag-${entry.key}'),
                  empty: false,
                  selected: entry.key == selectedItemId,
                  icon: shopItemIcon(item?.iconId ?? 'reward'),
                  tooltip: item?.name,
                  count: entry.value,
                  onTap: () => onSelect(entry.key),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _inspect(selected),
        ],
      ),
    );
  }

  Widget _inspect(ShopItem? item) {
    if (item == null) {
      return Text(
        bagItems.isEmpty
            ? 'The bag is empty. Buy something from the shop.'
            : 'Click an item to inspect it.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        if (item.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            item.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => onUse(item.id),
            child: const Text('Use'),
          ),
        ),
      ],
    );
  }
}
