import 'package:flutter/material.dart';

/// Icon choices offered when creating or editing a shop item. Stored by ID so
/// saved data stays independent of Flutter's icon table.
const Map<String, IconData> shopItemIcons = {
  'reward': Icons.local_mall,
  'meal': Icons.restaurant,
  'drink': Icons.bolt,
  'gaming': Icons.sports_esports,
  'movie': Icons.movie,
  'music': Icons.music_note,
  'rest': Icons.bedtime,
  'outdoors': Icons.park,
  'shopping': Icons.shopping_bag,
  'treat': Icons.icecream,
  'skip': Icons.skip_next,
};

IconData shopItemIcon(String iconId) {
  return shopItemIcons[iconId] ?? Icons.local_mall;
}
