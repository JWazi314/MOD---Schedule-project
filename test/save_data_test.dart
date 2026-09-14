import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quest_tracker/models/task.dart';
import 'package:quest_tracker/state/save_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a fresh install has nothing to load', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await SaveData.load(), isNull);
  });

  group('legacy migration', () {
    test('carries currency, counters, and tasks across', () async {
      final savedTask = Task(
        title: 'Workout',
        difficulty: 2,
        repeatDays: [1, 3, 5],
        sectionId: 'main',
        isDone: true,
      );

      SharedPreferences.setMockInitialValues({
        'gold': 100,
        'silver': 50,
        'xp': 300,
        'tasks': jsonEncode([savedTask.toJson()]),
        'totalCompletedTasks': 12,
        'totalHardTasksCompleted': 4,
        'achievements': ['first_task'],
        'completedDays': ['2026-8-10'],
      });

      final data = await SaveData.load();

      expect(data, isNotNull);
      expect(data!['schemaVersion'], SaveData.currentSchemaVersion);
      expect(data['gold'], 100);
      expect(data['silver'], 50);
      expect(data['lifetimeXp'], 300);
      expect(data['totalCompletedTasks'], 12);
      expect(data['totalHardTasksCompleted'], 4);
      expect(data['achievements'], ['first_task']);
      expect(data['completedDays'], ['2026-8-10']);
      expect((data['tasks'] as List), hasLength(1));
      expect(data['mod'], isNull);
    });

    test('maps known inventory titles onto seeded shop item IDs', () async {
      SharedPreferences.setMockInitialValues({
        'gold': 10,
        'inventory': ['Cheat Meal', 'Energy Drink', 'Cheat Meal'],
      });

      final data = await SaveData.load();

      expect(data!['inventory'], [
        'cheat_meal',
        'energy_drink',
        'cheat_meal',
      ]);
    });

    test('rescues unknown inventory titles as user-created items', () async {
      SharedPreferences.setMockInitialValues({
        'gold': 10,
        'inventory': ['Mystery Prize'],
      });

      final data = await SaveData.load();
      final inventory = data!['inventory'] as List;
      final shopItems = (data['shopItems'] as List)
          .cast<Map<String, dynamic>>();

      expect(inventory, hasLength(1));

      final rescued = shopItems.firstWhere(
        (item) => item['id'] == inventory.first,
      );

      expect(rescued['name'], 'Mystery Prize');
      expect(rescued['isUserCreated'], isTrue);
    });

    test('runs once and then reads the migrated blob', () async {
      SharedPreferences.setMockInitialValues({'gold': 42});

      await SaveData.load();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(SaveData.saveKey), isTrue);

      // A later load should come straight from the blob, not the old keys.
      await prefs.setInt('gold', 999);
      final second = await SaveData.load();
      expect(second!['gold'], 42);
    });

    test('tolerates corrupt legacy JSON without throwing', () async {
      SharedPreferences.setMockInitialValues({
        'gold': 5,
        'tasks': 'not valid json',
      });

      final data = await SaveData.load();

      expect(data!['gold'], 5);
      expect(data['tasks'], isEmpty);
    });
  });

  group('version 2 to 3 upgrade', () {
    Future<Map<String, dynamic>> loadV2(Map<String, dynamic> document) async {
      SharedPreferences.setMockInitialValues({
        SaveData.saveKey: jsonEncode({'schemaVersion': 2, ...document}),
      });

      return (await SaveData.load())!;
    }

    test('existing sections become Dailies and the rest of the board is added',
        () async {
      final data = await loadV2({
        'gold': 10,
        'sections': [
          {'id': 'main', 'name': 'Main Tasks'},
        ],
      });

      final sections = (data['sections'] as List).cast<Map<String, dynamic>>();

      expect(data['schemaVersion'], SaveData.currentSchemaVersion);
      expect(data['gold'], 10);
      expect(sections, hasLength(3));
      expect(sections.first['id'], 'main');
      expect(sections.first['type'], 'daily');
      expect(
        sections.map((section) => section['type']),
        containsAll(<String>['habit', 'daily', 'todo']),
      );
    });

    test('a board with no sections at all gets the full default set',
        () async {
      final data = await loadV2({'gold': 1});

      final sections = (data['sections'] as List).cast<Map<String, dynamic>>();

      expect(
        sections.map((section) => section['type']),
        ['habit', 'daily', 'todo'],
      );
    });

    test('the added columns avoid colliding with an existing section ID',
        () async {
      final data = await loadV2({
        'sections': [
          {'id': 'habits', 'name': 'Chores'},
        ],
      });

      final sections = (data['sections'] as List).cast<Map<String, dynamic>>();
      final ids = sections.map((section) => section['id']).toList();

      expect(ids, hasLength(3));
      expect(ids.toSet(), hasLength(3));
      expect(ids, contains('habits'));
    });

    test('the rollover clock starts fresh instead of punishing the player',
        () async {
      final data = await loadV2({'gold': 1});

      expect(data['lastRolloverAt'], isNull);
    });

    test('the upgrade is written back so it only runs once', () async {
      await loadV2({'gold': 3});

      final prefs = await SharedPreferences.getInstance();
      final stored =
          jsonDecode(prefs.getString(SaveData.saveKey)!) as Map<String, dynamic>;

      expect(stored['schemaVersion'], SaveData.currentSchemaVersion);
      expect(stored['sections'], hasLength(3));
    });
  });

  group('version 3 to 4 upgrade', () {
    test('adds an adventure slot and the locked rewards', () async {
      SharedPreferences.setMockInitialValues({
        SaveData.saveKey: jsonEncode({
          'schemaVersion': 3,
          'gold': 8,
          'shopItems': [
            {
              'id': 'cheat_meal',
              'name': 'Cheat Meal',
              'description': '',
              'cost': 100,
              'iconId': 'meal',
              'isDiscovered': true,
              'isUserCreated': false,
            },
          ],
        }),
      });

      final data = await SaveData.load();

      expect(data!['schemaVersion'], 4);
      expect(data['adventure'], isNull);
      expect((data['shopItems'] as List), hasLength(9));
    });
  });

  test('save then load returns the same document', () async {
    SharedPreferences.setMockInitialValues({});

    await SaveData.save({
      'schemaVersion': SaveData.currentSchemaVersion,
      'gold': 7,
    });
    final data = await SaveData.load();

    expect(data!['gold'], 7);
  });
}
