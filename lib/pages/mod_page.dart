import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/progression.dart';
import '../models/mod_appearance.dart';
import '../models/mod_character.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/mod_portrait.dart';
import 'mod_creation_page.dart';

/// The Mod's character sheet: level, experience, Vigor, and stat allocation.
class ModPage extends StatelessWidget {
  final VoidCallback? onOpenAdventure;

  const ModPage({super.key, this.onOpenAdventure});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final mod = gameState.mod;

    if (mod == null) {
      return const Center(child: Text('No Mod yet.'));
    }

    final appearance = appearanceById(mod.appearanceId);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(appearance.icon, color: appearance.color, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      mod.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: appearance.color,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit Mod',
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(context, gameState, mod),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                height: 210,
                decoration: BoxDecoration(
                  color: AppTheme.panel,
                  borderRadius: AppTheme.borderRadius,
                  border: Border.all(color: appearance.color, width: 2),
                ),
                child: Center(
                  child: ModPortrait(
                    appearanceId: mod.appearanceId,
                    size: 128,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              _LevelCard(mod: mod),

              const SizedBox(height: 14),

              _VigorCard(mod: mod),

              const SizedBox(height: 14),

              _AdventureStrip(
                gameState: gameState,
                onOpenAdventure: onOpenAdventure,
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Stats',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (mod.unspentStatPoints > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(35),
                        borderRadius: AppTheme.borderRadius,
                      ),
                      child: Text(
                        '${mod.unspentStatPoints} point'
                        '${mod.unspentStatPoints == 1 ? '' : 's'} to spend',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              ...ModStat.values.map((stat) {
                return _StatRow(
                  stat: stat,
                  mod: mod,
                  onSpend: mod.unspentStatPoints > 0
                      ? () => gameState.spendStatPoint(stat)
                      : null,
                );
              }),

              const SizedBox(height: 10),

              Text(
                'Every level adds +${Progression.statPointsPerLevel} point to '
                'spend, and half your level is added to every stat on top of '
                'that.',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    GameState gameState,
    ModCharacter mod,
  ) async {
    final formKey = GlobalKey<FormState>();
    String name = mod.name;
    String appearanceId = mod.appearanceId;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Mod'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: mod.name,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Mod Name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'give your Mod a name';
                          }
                          if (value.trim().length > 20) {
                            return 'keep it under 20 characters';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          name = value!.trim();
                        },
                      ),
                      const SizedBox(height: 20),
                      ModAppearancePicker(
                        selectedId: appearanceId,
                        onSelected: (id) {
                          setDialogState(() {
                            appearanceId = id;
                          });
                        },
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
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      gameState.updateModIdentity(
                        name: name,
                        appearanceId: appearanceId,
                      );
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LevelCard extends StatelessWidget {
  final ModCharacter mod;

  const _LevelCard({required this.mod});

  @override
  Widget build(BuildContext context) {
    final atMaxLevel = mod.level >= Progression.maxLevel;

    return Card(
      color: AppTheme.surface,
      margin: EdgeInsets.zero,
      shape: AppTheme.cardShape(sideColor: AppTheme.accentBlue, width: 1.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Level ${mod.level}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  atMaxLevel
                      ? 'Max level'
                      : '${mod.xp} / ${mod.xpToNextLevel} XP',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: atMaxLevel ? 1 : mod.levelProgress,
              minHeight: 12,
              borderRadius: AppTheme.borderRadius,
              backgroundColor: AppTheme.track,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.accentBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VigorCard extends StatelessWidget {
  final ModCharacter mod;

  const _VigorCard({required this.mod});

  @override
  Widget build(BuildContext context) {
    final resting = mod.isResting;
    final color = resting ? Colors.orange : Colors.green;

    return Card(
      color: AppTheme.surface,
      margin: EdgeInsets.zero,
      shape: AppTheme.cardShape(sideColor: color, width: 1.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  resting ? Icons.bedtime : Icons.favorite,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Vigor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${mod.currentVigor} / ${Progression.maxVigor}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: mod.currentVigor / Progression.maxVigor,
              minHeight: 12,
              borderRadius: AppTheme.borderRadius,
              backgroundColor: AppTheme.track,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 10),
            Text(
              resting
                  ? '${mod.name} is worn out and needs to rest before heading '
                        'out again. Nothing is ever lost, only paused.'
                  : 'Finishing tasks keeps ${mod.name} in good shape.',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdventureStrip extends StatelessWidget {
  final GameState gameState;
  final VoidCallback? onOpenAdventure;

  const _AdventureStrip({required this.gameState, this.onOpenAdventure});

  @override
  Widget build(BuildContext context) {
    final mod = gameState.mod;
    if (mod == null) {
      return const SizedBox.shrink();
    }

    final out = gameState.isModOut;
    final camped = out && !gameState.canAffordAdventureTick;

    final label = camped
        ? '${mod.name} made camp and is waiting to be recalled.'
        : out
        ? '${mod.name} is out. Recall from the adventure page.'
        : mod.isResting
        ? '${mod.name} is too worn out to leave.'
        : 'Send ${mod.name} out to look for gold and locked rewards.';

    return Card(
      color: AppTheme.surface,
      margin: EdgeInsets.zero,
      shape: AppTheme.cardShape(
        sideColor: out ? Colors.amber : AppTheme.border,
        width: 1.4,
      ),
      child: InkWell(
        borderRadius: AppTheme.borderRadius,
        onTap: onOpenAdventure,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                out ? Icons.explore : Icons.home,
                color: out ? Colors.amber : Colors.white54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final ModStat stat;
  final ModCharacter mod;
  final VoidCallback? onSpend;

  const _StatRow({required this.stat, required this.mod, this.onSpend});

  @override
  Widget build(BuildContext context) {
    final allocated = mod.statPoints(stat);
    final total = mod.effectiveStat(stat);

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: AppTheme.cardShape(width: 1.4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stat.description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$allocated + ${mod.levelBonus}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: onSpend == null
                  ? 'No points to spend'
                  : 'Spend a point on ${stat.label}',
              onPressed: onSpend,
              icon: const Icon(Icons.add_circle_outline_outlined, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}
