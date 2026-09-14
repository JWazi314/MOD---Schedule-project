/// A reward the player can buy with gold.
///
/// Items the Mod has not found yet stay locked until an adventure turns them
/// up, which is what [isDiscovered] gates.
class ShopItem {
  static const String skipTokenId = 'skip_token';

  final String id;
  String name;
  String description;
  int cost;
  String iconId;
  bool isDiscovered;
  final bool isUserCreated;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    this.iconId = 'reward',
    this.isDiscovered = true,
    this.isUserCreated = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cost': cost,
      'iconId': iconId,
      'isDiscovered': isDiscovered,
      'isUserCreated': isUserCreated,
    };
  }

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Reward',
      description: json['description'] as String? ?? '',
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      iconId: json['iconId'] as String? ?? 'reward',
      isDiscovered: json['isDiscovered'] as bool? ?? true,
      isUserCreated: json['isUserCreated'] as bool? ?? false,
    );
  }
}

/// The shop the app ships with. Kept as a function so each load gets its own
/// mutable instances.
List<ShopItem> defaultShopItems() {
  return [
    ShopItem(
      id: 'cheat_meal',
      name: 'Cheat Meal',
      description: 'Use this for one fun meal.',
      cost: 100,
      iconId: 'meal',
    ),
    ShopItem(
      id: 'gaming_night',
      name: 'Gaming Night',
      description: 'Take a night to play games guilt-free.',
      cost: 75,
      iconId: 'gaming',
    ),
    ShopItem(
      id: 'energy_drink',
      name: 'Energy Drink',
      description: 'Buy one drink as a small reward.',
      cost: 30,
      iconId: 'drink',
    ),
    skipTokenItem(),
    ...lockedShopItems(),
  ];
}

/// A consumable that skips one Daily. Always in the shop, and the Mod can
/// also turn one up on an adventure.
ShopItem skipTokenItem() {
  return ShopItem(
    id: ShopItem.skipTokenId,
    name: 'Skip Token',
    description: 'Skip one Daily today. Your streak holds; no gold or XP.',
    cost: 55,
    iconId: 'skip',
  );
}

/// Rewards the Mod has to turn up on an adventure before they can be bought.
///
/// These IDs have never existed in an older save, so a migration can merge
/// them in without any risk of resurrecting something the player deleted.
List<ShopItem> lockedShopItems() {
  return [
    ShopItem(
      id: 'found_movie_night',
      name: 'Movie Night',
      description: 'A film and nothing else on the schedule.',
      cost: 90,
      iconId: 'movie',
      isDiscovered: false,
    ),
    ShopItem(
      id: 'found_album',
      name: 'New Album',
      description: 'Pick up a record you have been meaning to hear.',
      cost: 120,
      iconId: 'music',
      isDiscovered: false,
    ),
    ShopItem(
      id: 'found_lie_in',
      name: 'Lie In',
      description: 'One morning with the alarm switched off.',
      cost: 150,
      iconId: 'rest',
      isDiscovered: false,
    ),
    ShopItem(
      id: 'found_day_hike',
      name: 'Day Hike',
      description: 'A whole day outside, phone in your pocket.',
      cost: 110,
      iconId: 'outdoors',
      isDiscovered: false,
    ),
    ShopItem(
      id: 'found_dessert',
      name: 'Something Sweet',
      description: 'The good dessert, not the sensible one.',
      cost: 45,
      iconId: 'treat',
      isDiscovered: false,
    ),
    ShopItem(
      id: 'found_shopping_trip',
      name: 'Shopping Trip',
      description: 'Buy the thing sitting in your basket.',
      cost: 200,
      iconId: 'shopping',
      isDiscovered: false,
    ),
    ShopItem(
      id: 'found_takeaway',
      name: 'Takeaway Night',
      description: 'Someone else cooks tonight.',
      cost: 80,
      iconId: 'meal',
      isDiscovered: false,
    ),
    ShopItem(
      id: 'found_long_weekend',
      name: 'Long Weekend',
      description: 'Claim a third day and spend it on nothing.',
      cost: 400,
      iconId: 'rest',
      isDiscovered: false,
    ),
  ];
}

/// Maps legacy inventory entries, which stored display titles, onto the seeded
/// item IDs.
const Map<String, String> legacyItemTitleToId = {
  'Cheat Meal': 'cheat_meal',
  'Gaming Night': 'gaming_night',
  'Energy Drink': 'energy_drink',
};
