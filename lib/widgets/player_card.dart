import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/progression.dart';
import '../models/mod_appearance.dart';
import '../state/game_state.dart';
import '../theme.dart';
import 'mod_portrait.dart';

class PlayerCard extends StatelessWidget {
  final VoidCallback? onOpenModPage;
  final VoidCallback? onOpenAdventure;

  const PlayerCard({super.key, this.onOpenModPage, this.onOpenAdventure});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final mod = gameState.mod;
    final appearance = mod == null ? null : appearanceById(mod.appearanceId);

    return Container(
      color: AppTheme.surfaceDark,

      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),

          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Player',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton(
                    tooltip: 'Close Player Sidebar',
                    color: Colors.white,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.chevron_left, size: 30),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Tapping the portrait opens the full character sheet.
              InkWell(
                borderRadius: AppTheme.borderRadius,
                onTap: onOpenModPage,
                child: Container(
                  height: 235,
                  decoration: BoxDecoration(
                    color: AppTheme.panel,
                    borderRadius: AppTheme.borderRadius,
                    border: Border.all(
                      color: appearance?.color ?? Colors.green,
                      width: 1.5,
                    ),
                  ),

                  child: Center(
                    child: appearance == null
                        ? Icon(
                            Icons.person_4,
                            color: Colors.white70,
                            size: 96,
                          )
                        : ModPortrait(
                            appearanceId: appearance.id,
                            size: 144,
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                mod?.name ?? 'User',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (mod != null) ...[
                const SizedBox(height: 4),
                  Text(
                    'Level ${mod.level} ${appearance?.label ?? ''}'.trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                  if (gameState.isModOut || mod.isResting) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: _StatusBadge(
                        isOut: gameState.isModOut,
                        isResting: mod.isResting,
                        onTap: onOpenAdventure,
                      ),
                    ),
                  ],
              ],

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _PlayerStatBox(
                      title: 'Gold',
                      value: gameState.gold,
                      icon: Icons.monetization_on,
                      color: Colors.amber,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _PlayerStatBox(
                      title: 'Silver',
                      value: gameState.silver,
                      icon: Icons.circle,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.panel,
                  borderRadius: AppTheme.borderRadius,
                  border: Border.all(color: AppTheme.accentBlue, width: 1.4),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mod == null
                          ? 'Experience: ${gameState.lifetimeXp}'
                          : 'Experience: ${mod.xp} / ${mod.xpToNextLevel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    LinearProgressIndicator(
                      value: mod?.levelProgress ?? 0,
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

              if (mod != null) ...[
                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.panel,
                    borderRadius: AppTheme.borderRadius,
                    border: Border.all(
                      color: mod.isResting ? Colors.orange : Colors.green,
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vigor: ${mod.currentVigor} / ${Progression.maxVigor}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: mod.currentVigor / Progression.maxVigor,
                        minHeight: 12,
                        borderRadius: AppTheme.borderRadius,
                        backgroundColor: AppTheme.track,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          mod.isResting ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                if (mod.unspentStatPoints > 0) ...[
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: onOpenModPage,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(
                      '${mod.unspentStatPoints} stat point'
                      '${mod.unspentStatPoints == 1 ? '' : 's'} to spend',
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOut;
  final bool isResting;
  final VoidCallback? onTap;

  const _StatusBadge({
    required this.isOut,
    required this.isResting,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final out = isOut;
    final color = out ? Colors.amber : Colors.orange;
    final label = out ? 'Out on adventure' : 'Resting';

    return InkWell(
      borderRadius: AppTheme.borderRadius,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: AppTheme.borderRadius,
          border: Border.all(color: color, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(out ? Icons.explore : Icons.bedtime, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerStatBox extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _PlayerStatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: color, width: 1.4),
      ),

      child: Column(
        children: [
          Icon(icon, color: color, size: 28),

          const SizedBox(height: 7),

          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(title, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }
}
