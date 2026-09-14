import 'package:flutter_test/flutter_test.dart';
import 'package:quest_tracker/game/mod_sprite.dart';
import 'package:quest_tracker/models/mod_appearance.dart';

void main() {
  test('every look is a 16 by 16 map', () {
    for (final appearance in modAppearances) {
      final rows = ModSprite.rowsFor(appearance.id);
      expect(rows, hasLength(ModSprite.size), reason: appearance.id);
      for (final row in rows) {
        expect(row.length, ModSprite.size, reason: appearance.id);
      }
    }
  });

  test('looks do not share the same pixels', () {
    final maps = {
      for (final appearance in modAppearances)
        appearance.id: ModSprite.rowsFor(appearance.id).join(),
    };

    final ids = maps.keys.toList();
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        expect(
          maps[ids[i]],
          isNot(maps[ids[j]]),
          reason: '${ids[i]} vs ${ids[j]}',
        );
      }
    }
  });
}
