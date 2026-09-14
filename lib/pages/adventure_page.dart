import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/progression.dart';
import '../models/adventure.dart';
import '../models/mod_appearance.dart';
import '../state/game_state.dart';
import '../theme.dart';

/// Dispatch, recall, and the log of whatever happened while the Mod was out.
class AdventurePage extends StatelessWidget {
  const AdventurePage({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final mod = gameState.mod;
    final adventure = gameState.adventure;

    if (mod == null) {
      return const Center(child: Text('No Mod yet.'));
    }

    final appearance = appearanceById(mod.appearanceId);
    final isOut = adventure.isOut;
    final resting = mod.isResting;
    final camped = isOut && !gameState.canAffordAdventureTick;

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
                  Icon(appearance.icon, color: appearance.color, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Adventure',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _StatusCard(
                name: mod.name,
                appearanceColor: appearance.color,
                isOut: isOut,
                resting: resting,
                camped: camped,
                packFull: adventure.isPackFull,
                timeOut: isOut ? adventure.timeOut(DateTime.now()) : Duration.zero,
                vigor: mod.currentVigor,
                carried: adventure.carried,
              ),

              const SizedBox(height: 14),

              if (isOut)
                ElevatedButton.icon(
                  onPressed: () => gameState.recallMod(),
                  icon: const Icon(Icons.home),
                  label: const Text('Recall'),
                )
              else
                ElevatedButton.icon(
                  onPressed: resting ? null : () => gameState.sendModOnAdventure(),
                  icon: const Icon(Icons.explore),
                  label: Text(resting ? 'Too worn out to leave' : 'Send out'),
                ),

              const SizedBox(height: 8),

              Text(
                _hint(mod.name, isOut: isOut, resting: resting, camped: camped),
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),

              if (isOut || adventure.log.isNotEmpty) ...[
                const SizedBox(height: 18),
                _HaulCard(gameState: gameState),
              ],

              const SizedBox(height: 18),

              const Text(
                'Log',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: adventure.log.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          isOut
                              ? 'Nothing to report yet. Events land about '
                                  'every ${Progression.adventureTickMinutes} '
                                  'minutes while ${mod.name} is out.'
                              : 'Nothing has happened yet. Send the Mod out '
                                  'and come back later.',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: adventure.log.length,
                        itemBuilder: (context, index) {
                          // Newest first so the latest event is at the top.
                          final event =
                              adventure.log[adventure.log.length - 1 - index];
                          return _LogEntry(event: event);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _hint(
    String name, {
    required bool isOut,
    required bool resting,
    required bool camped,
  }) {
    if (resting && !isOut) {
      return '$name is worn out. Finish a task to restore some Vigor, then '
          'try again.';
    }
    if (camped) {
      return '$name made camp. Finish a task to get it moving again, or '
          'recall it home with whatever it is carrying.';
    }
    if (isOut) {
      return 'Loot stays in the pack until you recall $name. A full pack '
          'stops new finds, so coming home is a choice.';
    }
    return 'Each stretch of the trip burns a little Vigor. Missed Dailies '
        'shorten how long $name can stay out.';
  }
}

class _StatusCard extends StatelessWidget {
  final String name;
  final Color appearanceColor;
  final bool isOut;
  final bool resting;
  final bool camped;
  final bool packFull;
  final Duration timeOut;
  final int vigor;
  final int carried;

  const _StatusCard({
    required this.name,
    required this.appearanceColor,
    required this.isOut,
    required this.resting,
    required this.camped,
    required this.packFull,
    required this.timeOut,
    required this.vigor,
    required this.carried,
  });

  String get _statusLabel {
    if (camped) {
      return 'Camped';
    }
    if (isOut) {
      return packFull ? 'Pack full' : 'Out';
    }
    if (resting) {
      return 'Resting';
    }
    return 'Home';
  }

  Color get _statusColor {
    if (camped || resting) {
      return Colors.orange;
    }
    if (isOut) {
      return packFull ? Colors.amber : appearanceColor;
    }
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      margin: EdgeInsets.zero,
      shape: AppTheme.cardShape(sideColor: _statusColor, width: 1.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOut
                      ? (camped ? Icons.nights_stay : Icons.explore)
                      : (resting ? Icons.bedtime : Icons.home),
                  color: _statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$name is ${_statusLabel.toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.favorite,
                  label: '$vigor / ${Progression.maxVigor} Vigor',
                ),
                if (isOut)
                  _MetaChip(
                    icon: Icons.schedule,
                    label: _formatOut(timeOut),
                  ),
                _MetaChip(
                  icon: Icons.backpack,
                  label: '$carried / ${Progression.maxCarry} pack',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatOut(Duration elapsed) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);

    if (hours <= 0) {
      return '${minutes}m out';
    }
    return '${hours}h ${minutes}m out';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}

class _HaulCard extends StatelessWidget {
  final GameState gameState;

  const _HaulCard({required this.gameState});

  @override
  Widget build(BuildContext context) {
    final adventure = gameState.adventure;
    final itemNames = [
      for (final id in adventure.pendingItemIds)
        gameState.shopItemById(id)?.name ?? 'Unknown find',
    ];

    return Card(
      color: AppTheme.surface,
      margin: EdgeInsets.zero,
      shape: AppTheme.cardShape(sideColor: Colors.amber, width: 1.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pending haul',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (!adventure.hasHaul)
              const Text(
                'The pack is empty so far.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              )
            else ...[
              Text(
                '${adventure.pendingGold} Gold  ·  ${adventure.pendingXp} XP',
                style: const TextStyle(color: Colors.amber),
              ),
              if (itemNames.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final name in itemNames)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(30),
                          borderRadius: AppTheme.borderRadius,
                          border: Border.all(color: Colors.amber.withAlpha(120)),
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final AdventureEvent event;

  const _LogEntry({required this.event});

  IconData get _icon {
    switch (event.kind) {
      case AdventureEventKind.travel:
        return Icons.hiking;
      case AdventureEventKind.find:
        return Icons.inventory_2;
      case AdventureEventKind.encounter:
        return Icons.flash_on;
      case AdventureEventKind.camp:
        return Icons.nights_stay;
    }
  }

  Color get _color {
    switch (event.kind) {
      case AdventureEventKind.travel:
        return Colors.white54;
      case AdventureEventKind.find:
        return Colors.amber;
      case AdventureEventKind.encounter:
        return event.vigorLost > 0 ? Colors.redAccent : Colors.greenAccent;
      case AdventureEventKind.camp:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              event.text,
              style: TextStyle(
                color: event.kind == AdventureEventKind.travel
                    ? Colors.white70
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
