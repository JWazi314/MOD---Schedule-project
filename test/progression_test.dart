import 'package:flutter_test/flutter_test.dart';
import 'package:quest_tracker/game/progression.dart';
import 'package:quest_tracker/models/mod_character.dart';

void main() {
  group('XP curve', () {
    test('starts at 100 and grows quadratically', () {
      expect(Progression.xpToNextLevel(1), 100);
      expect(Progression.xpToNextLevel(2), 155);
      expect(Progression.xpToNextLevel(10), 955);
    });

    test('never decreases as level rises', () {
      var previous = 0;

      for (var level = 1; level <= Progression.maxLevel; level++) {
        final needed = Progression.xpToNextLevel(level);
        expect(needed, greaterThanOrEqualTo(previous));
        previous = needed;
      }
    });
  });

  group('stat effects', () {
    test('level bonus is half the level, capped', () {
      expect(Progression.levelBonus(1), 0);
      expect(Progression.levelBonus(10), 5);
      expect(Progression.levelBonus(99), 49);
      expect(Progression.levelBonus(200), Progression.maxLevelBonus);
    });

    test('focus raises XP and fortune raises gold', () {
      expect(Progression.applyXpMultiplier(100, 0), 100);
      expect(Progression.applyXpMultiplier(100, 40), 200);
      expect(Progression.applyGoldMultiplier(100, 0), 100);
      expect(Progression.applyGoldMultiplier(100, 50), 200);
    });

    test('discovery chance is clamped', () {
      expect(Progression.discoveryChance(0), closeTo(0.10, 0.0001));
      expect(Progression.discoveryChance(1000), 0.75);
    });

    test('a Skip Token find stays rare', () {
      expect(Progression.skipTokenFindChance(0), closeTo(0.02, 0.0001));
      expect(Progression.skipTokenFindChance(1000), 0.08);
    });
  });

  group('ModCharacter', () {
    ModCharacter buildMod() {
      return ModCharacter(name: 'Pip', appearanceId: 'wanderer');
    }

    test('gaining enough XP levels up and grants a stat point', () {
      final mod = buildMod();

      final result = mod.gainXp(100);

      expect(result.levelsGained, 1);
      expect(result.statPointsGained, Progression.statPointsPerLevel);
      expect(mod.level, 2);
      expect(mod.xp, 0);
      expect(mod.unspentStatPoints, Progression.statPointsPerLevel);
    });

    test('overflow XP carries into the next level', () {
      final mod = buildMod();

      mod.gainXp(130);

      expect(mod.level, 2);
      expect(mod.xp, 30);
    });

    test('a single large award can cross several levels', () {
      final mod = buildMod();

      final result = mod.gainXp(1000);

      expect(result.levelsGained, greaterThan(2));
      expect(mod.level, result.levelsGained + 1);
      expect(mod.unspentStatPoints, result.statPointsGained);
    });

    test('effective stats include the level bonus', () {
      final mod = buildMod();
      mod.gainXp(100000);

      final bonus = Progression.levelBonus(mod.level);
      expect(mod.effectiveStat(ModStat.might), bonus);

      mod.spendStatPoint(ModStat.might);
      expect(mod.effectiveStat(ModStat.might), bonus + 1);
    });

    test('stat points cannot be spent when none are banked', () {
      final mod = buildMod();

      expect(mod.spendStatPoint(ModStat.focus), isFalse);
      expect(mod.focusPoints, 0);
    });

    test('vigor stays within bounds and flags resting at zero', () {
      final mod = buildMod();

      mod.drainVigor(500);
      expect(mod.currentVigor, 0);
      expect(mod.isResting, isTrue);

      mod.restoreVigor(500);
      expect(mod.currentVigor, Progression.maxVigor);
      expect(mod.isResting, isFalse);
    });

    test('survives a round trip through JSON', () {
      final mod = buildMod();
      mod.gainXp(400);
      mod.spendStatPoint(ModStat.fortune);
      mod.drainVigor(25);

      final restored = ModCharacter.fromJson(mod.toJson());

      expect(restored.name, mod.name);
      expect(restored.appearanceId, mod.appearanceId);
      expect(restored.level, mod.level);
      expect(restored.xp, mod.xp);
      expect(restored.fortunePoints, mod.fortunePoints);
      expect(restored.unspentStatPoints, mod.unspentStatPoints);
      expect(restored.currentVigor, mod.currentVigor);
    });
  });
}
