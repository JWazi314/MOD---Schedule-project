import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shop_item.dart';
import '../models/task_section.dart';
import '../models/task_type.dart';

/// Reads and writes the game's save blob.
///
/// Everything used to live in ten separate SharedPreferences keys. It now sits
/// in one versioned JSON document under [saveKey], and older saves are folded
/// into the current shape the first time they are loaded.
class SaveData {
  SaveData._();

  static const String saveKey = 'modSave';

  /// 1 was the flat SharedPreferences keys, 2 added the Mod and the shop,
  /// 3 added task types, 4 added adventures and the rewards they turn up.
  static const int currentSchemaVersion = 4;

  static const List<String> legacyKeys = [
    'gold',
    'silver',
    'xp',
    'tasks',
    'taskSections',
    'inventory',
    'achievements',
    'totalCompletedTasks',
    'totalHardTasksCompleted',
    'completedDays',
  ];

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(saveKey);

    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final data = Map<String, dynamic>.from(decoded);
          final version = (data['schemaVersion'] as num?)?.toInt() ?? 1;

          if (version >= currentSchemaVersion) {
            return data;
          }

          var upgraded = data;
          if (version < 3) {
            upgraded = upgradeToV3(upgraded);
          }
          if (version < 4) {
            upgraded = upgradeToV4(upgraded);
          }

          await prefs.setString(saveKey, jsonEncode(upgraded));
          return upgraded;
        }
      } catch (error) {
        debugPrint('Failed to read save data: $error');
      }
    }

    final legacy = readLegacy(prefs);
    if (legacy == null) {
      return null;
    }

    final migrated = migrateLegacy(legacy);
    await prefs.setString(saveKey, jsonEncode(migrated));
    return migrated;
  }

  static Future<void> save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(saveKey, jsonEncode(data));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(saveKey);
  }

  /// Pulls the old flat keys out of prefs, or null when there is nothing to
  /// migrate.
  static Map<String, Object?>? readLegacy(SharedPreferences prefs) {
    final hasLegacyData = legacyKeys.any(prefs.containsKey);
    if (!hasLegacyData) {
      return null;
    }

    return {
      'gold': prefs.getInt('gold'),
      'silver': prefs.getInt('silver'),
      'xp': prefs.getInt('xp'),
      'tasks': prefs.getString('tasks'),
      'taskSections': prefs.getString('taskSections'),
      'inventory': prefs.getStringList('inventory'),
      'achievements': prefs.getStringList('achievements'),
      'totalCompletedTasks': prefs.getInt('totalCompletedTasks'),
      'totalHardTasksCompleted': prefs.getInt('totalHardTasksCompleted'),
      'completedDays': prefs.getStringList('completedDays'),
    };
  }

  /// Brings a version 2 document up to version 3.
  ///
  /// Sections gain a type. Everything that already existed behaved like a
  /// Daily, so that is what it becomes, and a Habits and a To-Dos column are
  /// added alongside so the full board is there on first open.
  static Map<String, dynamic> upgradeToV3(Map<String, dynamic> data) {
    final sections = _mapList(data['sections']);

    for (final section in sections) {
      final type = section['type'];
      if (type is! String || type.trim().isEmpty) {
        section['type'] = TaskType.daily.id;
      }
    }

    if (sections.isEmpty) {
      sections.addAll(defaultSections().map((section) => section.toJson()));
    } else {
      final usedIds = sections
          .map((section) => section['id'])
          .whereType<String>()
          .toSet();

      final presentTypes = sections
          .map((section) => section['type'])
          .whereType<String>()
          .toSet();

      for (final missing in [TaskType.habit, TaskType.todo]) {
        if (presentTypes.contains(missing.id)) {
          continue;
        }

        final id = _unusedId(missing.id, usedIds);
        usedIds.add(id);

        sections.add(
          TaskSection(id: id, name: missing.label, type: missing).toJson(),
        );
      }
    }

    return {
      ...data,
      'schemaVersion': 3,
      'sections': sections,
      // Null starts the rollover clock on this load rather than punishing the
      // player for however long the app sat unopened before the upgrade.
      'lastRolloverAt': null,
    };
  }

  /// Brings a version 3 document up to version 4.
  ///
  /// Adds the adventure slot and merges in the locked rewards, since before
  /// this version there was nothing for the Mod to find. Those IDs never
  /// existed in version 3, so the merge cannot resurrect an item the player
  /// deleted on purpose.
  static Map<String, dynamic> upgradeToV4(Map<String, dynamic> data) {
    final shopItems = _mapList(data['shopItems']);

    // An empty list means the save never stored a shop, so leave it alone and
    // let the seeded shop load as a whole instead of a locked-only one.
    if (shopItems.isNotEmpty) {
      final existingIds = shopItems
          .map((item) => item['id'])
          .whereType<String>()
          .toSet();

      for (final locked in lockedShopItems()) {
        if (!existingIds.contains(locked.id)) {
          shopItems.add(locked.toJson());
        }
      }
    }

    return {
      ...data,
      'schemaVersion': 4,
      'shopItems': shopItems,
      'adventure': null,
    };
  }

  static String _unusedId(String preferred, Set<String> taken) {
    if (!taken.contains(preferred)) {
      return preferred;
    }

    var suffix = 2;
    while (taken.contains('$preferred$suffix')) {
      suffix++;
    }
    return '$preferred$suffix';
  }

  /// Converts the pre-Mod save format into the current one.
  ///
  /// Inventory used to store display titles. Known titles map onto the seeded
  /// shop items; anything unrecognised becomes a user-created item so the
  /// player does not silently lose a reward they paid for.
  static Map<String, dynamic> migrateLegacy(Map<String, Object?> legacy) {
    final shopItems = defaultShopItems();
    final inventoryIds = <String>[];

    final legacyInventory = legacy['inventory'];
    if (legacyInventory is List) {
      for (final entry in legacyInventory.whereType<String>()) {
        final knownId = legacyItemTitleToId[entry];

        if (knownId != null) {
          inventoryIds.add(knownId);
          continue;
        }

        final rescuedId = 'legacy_${entry.hashCode.toUnsigned(32)}';
        if (!shopItems.any((item) => item.id == rescuedId)) {
          shopItems.add(
            ShopItem(
              id: rescuedId,
              name: entry,
              description: 'Recovered from an earlier save.',
              cost: 50,
              isUserCreated: true,
            ),
          );
        }
        inventoryIds.add(rescuedId);
      }
    }

    // Built in the version 2 shape, then run through the same upgrade path a
    // stored version 2 document takes.
    return upgradeToV4(upgradeToV3({
      'schemaVersion': 2,
      'gold': (legacy['gold'] as num?)?.toInt() ?? 0,
      'silver': (legacy['silver'] as num?)?.toInt() ?? 0,
      'lifetimeXp': (legacy['xp'] as num?)?.toInt() ?? 0,
      'totalCompletedTasks':
          (legacy['totalCompletedTasks'] as num?)?.toInt() ?? 0,
      'totalHardTasksCompleted':
          (legacy['totalHardTasksCompleted'] as num?)?.toInt() ?? 0,
      'completedDays': _stringList(legacy['completedDays']),
      'achievements': _stringList(legacy['achievements']),
      'tasks': _decodeList(legacy['tasks']),
      'sections': _decodeList(legacy['taskSections']),
      'inventory': inventoryIds,
      'shopItems': shopItems.map((item) => item.toJson()).toList(),
      'mod': null,
    }));
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return <String>[];
  }

  static List<Map<String, dynamic>> _mapList(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static List<Map<String, dynamic>> _decodeList(Object? value) {
    if (value is! String || value.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      return _mapList(jsonDecode(value));
    } catch (error) {
      debugPrint('Failed to decode legacy list: $error');
      return <Map<String, dynamic>>[];
    }
  }
}
