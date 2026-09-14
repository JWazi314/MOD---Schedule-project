import 'package:flutter_test/flutter_test.dart';
import 'package:quest_tracker/game/adventure_engine.dart';
import 'package:quest_tracker/game/progression.dart';
import 'package:quest_tracker/models/adventure.dart';
import 'package:quest_tracker/models/shop_item.dart';

void main() {
  tearDown(Progression.resetSkipTokenFindChance);

  test('a lucky find-tick can turn up a Skip Token', () {
    Progression.skipTokenFindChance = (_) => 1;

    final start = DateTime(2026, 3, 1, 8);
    final adventure = AdventureState(
      isOut: true,
      seed: 1,
      lastTickAt: start,
    );

    final outcome = AdventureEngine.run(
      adventure: adventure,
      modName: 'Pip',
      availableVigor: 100,
      might: 0,
      fortune: 0,
      undiscoveredItems: const [],
      repeatableFinds: [skipTokenItem()],
      now: start.add(const Duration(hours: 10)),
    );

    expect(outcome.itemsFound, contains(ShopItem.skipTokenId));
  });
}
