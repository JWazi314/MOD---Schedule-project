import 'package:flutter/material.dart';

/// Visual presets for the Mod. These are referenced by ID so real sprites can
/// replace the icons later without touching saved data.
class ModAppearance {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const ModAppearance({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const List<ModAppearance> modAppearances = [
  ModAppearance(
    id: 'wanderer',
    label: 'Wanderer',
    icon: Icons.person_4,
    color: Colors.green,
  ),
  ModAppearance(
    id: 'knight',
    label: 'Knight',
    icon: Icons.shield,
    color: Colors.lightBlueAccent,
  ),
  ModAppearance(
    id: 'scholar',
    label: 'Scholar',
    icon: Icons.auto_stories,
    color: Colors.purpleAccent,
  ),
  ModAppearance(
    id: 'scout',
    label: 'Scout',
    icon: Icons.explore,
    color: Colors.amber,
  ),
  ModAppearance(
    id: 'brawler',
    label: 'Brawler',
    icon: Icons.sports_mma,
    color: Colors.redAccent,
  ),
  ModAppearance(
    id: 'tinkerer',
    label: 'Tinkerer',
    icon: Icons.build,
    color: Colors.orangeAccent,
  ),
];

ModAppearance appearanceById(String id) {
  return modAppearances.firstWhere(
    (appearance) => appearance.id == id,
    orElse: () => modAppearances.first,
  );
}
