import 'package:flutter_test/flutter_test.dart';
import 'package:quest_tracker/game/progression.dart';
import 'package:quest_tracker/game/task_value.dart';
import 'package:quest_tracker/models/checklist_item.dart';
import 'package:quest_tracker/models/mod_character.dart';
import 'package:quest_tracker/models/shop_item.dart';
import 'package:quest_tracker/models/task.dart';
import 'package:quest_tracker/models/task_type.dart';
import 'package:quest_tracker/state/game_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Task buildTask({
  String title = 'Workout',
  int difficulty = 1,
  String sectionId = 'dailies',
  bool isDone = false,
  double neglect = 0,
  bool isPositive = true,
  bool isNegative = false,
}) {
  return Task(
    title: title,
    difficulty: difficulty,
    sectionId: sectionId,
    isDone: isDone,
    neglect: neglect,
    isPositive: isPositive,
    isNegative: isNegative,
  );
}

Future<GameState> loadedState() async {
  final state = GameState();
  await state.load();
  return state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TaskValue.nextRoll = () => 0.5;
  });

  tearDown(TaskValue.resetRoll);

  group('the starting board', () {
    test('opens with one column of each type', () async {
      final state = await loadedState();

      expect(state.sections.map((section) => section.type), [
        TaskType.habit,
        TaskType.daily,
        TaskType.todo,
      ]);
    });

    test('a task takes its type from the section it sits in', () async {
      final state = await loadedState();

      expect(taskTypeOf(state, 'habits'), TaskType.habit);
      expect(taskTypeOf(state, 'dailies'), TaskType.daily);
      expect(taskTypeOf(state, 'todos'), TaskType.todo);
    });

    test('a task in a section that no longer exists reads as a Daily',
        () async {
      final state = await loadedState();

      expect(taskTypeOf(state, 'nowhere'), TaskType.daily);
    });
  });

  group('tasks', () {
    test('completing a task awards gold, silver, and XP', () async {
      final state = await loadedState();
      // Pre-unlock the first-task achievement so its gold bonus does not get
      // mixed into the reward being measured.
      state.unlockedAchievements.add('first_task');

      final task = buildTask();
      state.addTask(task);

      state.completeTask(task);

      expect(task.isDone, isTrue);
      expect(task.completedAt, isNotNull);
      expect(state.gold, 10);
      expect(state.silver, 5);
      expect(state.lifetimeXp, 50);
      expect(state.latestPayout, isNotNull);
      expect(state.latestPayout!.gold, 10);
      expect(state.latestPayout!.silver, 5);
      expect(state.latestPayout!.xp, 50);
      expect(identical(state.latestPayout!.task, task), isTrue);
    });

    test('two finishes of the same difficulty can pay different amounts',
        () async {
      Future<int> goldForRoll(double roll) async {
        SharedPreferences.setMockInitialValues({});
        TaskValue.nextRoll = () => roll;
        final state = await loadedState();
        state.unlockedAchievements.add('first_task');
        final task = buildTask(difficulty: 0);
        state.addTask(task);
        state.completeTask(task);
        return state.latestPayout!.gold;
      }

      expect(await goldForRoll(1), greaterThan(await goldForRoll(0)));
    });

    test('completing the same task twice does not double the rewards',
        () async {
      final state = await loadedState();
      state.unlockedAchievements.add('first_task');

      final task = buildTask(difficulty: 2);
      state.addTask(task);

      state.completeTask(task);
      state.completeTask(task);

      expect(state.gold, 15);
      expect(state.silver, 7);
      expect(state.lifetimeXp, 75);
    });

    test('a Mod with Focus and Fortune earns more than a bare player',
        () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'wanderer');

      final mod = state.mod!;
      mod.focusPoints = 40;
      mod.fortunePoints = 50;

      state.completeTask(buildTask());

      // Focus 40 doubles XP, Fortune 50 doubles gold, plus the level bonus.
      expect(state.lifetimeXp, greaterThan(50));
      expect(state.gold, greaterThan(10));
    });

    test('completing tasks levels the Mod up', () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'wanderer');

      for (var i = 0; i < 4; i++) {
        state.completeTask(buildTask(title: 'Task $i'));
      }

      expect(state.mod!.level, greaterThan(1));
    });

    test('finishing a Daily extends its streak', () async {
      final state = await loadedState();
      final task = buildTask();
      state.addTask(task);

      state.completeTask(task);

      expect(task.streak, 1);
    });

    test('finishing a To-Do leaves the streak alone', () async {
      final state = await loadedState();
      final task = buildTask(sectionId: 'todos');
      state.addTask(task);

      state.completeTask(task);

      expect(task.isDone, isTrue);
      expect(task.streak, 0);
    });

    test('a neglected task pays out more, then loses most of its backlog',
        () async {
      final state = await loadedState();
      state.unlockedAchievements.add('first_task');

      final task = buildTask(neglect: 1);
      state.addTask(task);

      state.completeTask(task);

      // Difficulty 1 at full neglect, so 10 gold times the 1.5x cap.
      expect(state.gold, 15);
      expect(task.neglect, closeTo(1 - TaskValue.completionRelief, 0.0001));
    });

    test('removing a task deletes it', () async {
      final state = await loadedState();
      final task = buildTask();
      state.addTask(task);

      expect(state.tasks, hasLength(1));

      state.removeTask(task);

      expect(state.tasks, isEmpty);
    });

    test('editing keeps the streak, neglect, and habit counts', () async {
      final state = await loadedState();

      final task = buildTask(neglect: 0.6);
      task.streak = 5;
      task.upCount = 12;
      state.addTask(task);

      state.updateTask(
        task,
        title: 'Longer Workout',
        description: 'Add a warm-up.',
        difficulty: 2,
        sectionId: 'dailies',
        repeatDays: const [0, 2, 4],
        dueDate: null,
        isPositive: true,
        isNegative: false,
      );

      expect(task.title, 'Longer Workout');
      expect(task.description, 'Add a warm-up.');
      expect(task.difficulty, 2);
      expect(task.repeatDays, [0, 2, 4]);
      expect(task.neglect, 0.6);
      expect(task.streak, 5);
      expect(task.upCount, 12);
    });

    test('moving a task to another section converts its type', () async {
      final state = await loadedState();
      final task = buildTask();
      state.addTask(task);

      expect(state.taskTypeFor(task), TaskType.daily);

      state.updateTask(
        task,
        title: task.title,
        difficulty: task.difficulty,
        sectionId: 'habits',
        repeatDays: const [],
        dueDate: null,
        isPositive: true,
        isNegative: false,
      );

      expect(state.taskTypeFor(task), TaskType.habit);
    });
  });

  group('checklists', () {
    Task withParts(int count, {String sectionId = 'dailies'}) {
      return Task(
        title: 'Clean the kitchen',
        difficulty: 1,
        sectionId: sectionId,
        checklist: [
          for (var i = 0; i < count; i++)
            ChecklistItem(id: 'p$i', title: 'Step $i'),
        ],
      );
    }

    test('ticking a part short of the last one leaves the task open',
        () async {
      final state = await loadedState();
      final task = withParts(3);
      state.addTask(task);

      state.toggleChecklistItem(task, task.checklist.first);

      expect(task.completedParts, 1);
      expect(task.isDone, isFalse);
      expect(state.gold, greaterThan(0));
      expect(state.gold, lessThan(10));
    });

    test('ticking the last part finishes the whole task', () async {
      final state = await loadedState();
      state.unlockedAchievements.add('first_task');

      final task = withParts(2);
      state.addTask(task);

      state.toggleChecklistItem(task, task.checklist[0]);
      state.toggleChecklistItem(task, task.checklist[1]);

      expect(task.isDone, isTrue);
      expect(task.streak, 1);
      expect(state.gold, 10);
    });

    test('a part can be un-ticked while the task is still open', () async {
      final state = await loadedState();
      final task = withParts(3);
      state.addTask(task);

      state.toggleChecklistItem(task, task.checklist.first);
      state.toggleChecklistItem(task, task.checklist.first);

      expect(task.completedParts, 0);
      expect(task.isDone, isFalse);
      expect(state.gold, 0);
    });

    test('checking the task off ticks every part with it', () async {
      final state = await loadedState();
      final task = withParts(4);
      state.addTask(task);

      state.completeTask(task);

      expect(task.allPartsDone, isTrue);
    });

    test('a finished task is locked so it cannot pay out twice', () async {
      final state = await loadedState();
      state.unlockedAchievements.add('first_task');

      final task = withParts(2);
      state.addTask(task);
      state.completeTask(task);

      final goldAfterFirst = state.gold;
      state.toggleChecklistItem(task, task.checklist.first);

      expect(task.isDone, isTrue);
      expect(task.allPartsDone, isTrue);
      expect(state.gold, goldAfterFirst);
    });

    test('a task with no parts is never auto-completed', () async {
      final state = await loadedState();
      final task = buildTask();
      state.addTask(task);

      state.toggleChecklistItem(task, ChecklistItem(id: 'x', title: 'Ghost'));

      expect(task.isDone, isFalse);
    });

    test('habits have no parts to tick', () async {
      final state = await loadedState();
      final task = withParts(2, sectionId: 'habits');
      state.addTask(task);

      state.toggleChecklistItem(task, task.checklist.first);

      expect(task.completedParts, 0);
    });

    test('resetting the day clears the parts of a Daily', () async {
      final state = await loadedState();
      final task = withParts(2);
      state.addTask(task);
      state.completeTask(task);

      state.resetDay();

      expect(task.isDone, isFalse);
      expect(task.completedParts, 0);
    });

    test('a finished To-Do keeps its parts through a reset', () async {
      final state = await loadedState();
      final task = withParts(2, sectionId: 'todos');
      state.addTask(task);
      state.completeTask(task);

      state.resetDay();

      expect(task.isDone, isTrue);
      expect(task.allPartsDone, isTrue);
    });

    test('editing replaces the parts but leaves progress alone when it is '
        'not given any', () async {
      final state = await loadedState();
      final task = withParts(2);
      state.addTask(task);
      state.toggleChecklistItem(task, task.checklist.first);

      state.updateTask(
        task,
        title: 'Tidy up',
        difficulty: 1,
        sectionId: 'dailies',
        repeatDays: const [],
        dueDate: null,
        isPositive: true,
        isNegative: false,
      );

      expect(task.checklist, hasLength(2));
      expect(task.completedParts, 1);
    });

    test('editing can swap the parts out entirely', () async {
      final state = await loadedState();
      final task = withParts(2);
      state.addTask(task);

      state.updateTask(
        task,
        title: 'Tidy up',
        difficulty: 1,
        sectionId: 'dailies',
        repeatDays: const [],
        dueDate: null,
        isPositive: true,
        isNegative: false,
        checklist: [ChecklistItem(id: 'new', title: 'Only step')],
      );

      expect(task.checklist, hasLength(1));
      expect(task.checklist.first.title, 'Only step');
    });

    test('parts and their progress survive a reload', () async {
      final state = await loadedState();
      final task = withParts(3);
      state.addTask(task);
      state.toggleChecklistItem(task, task.checklist[1]);
      await state.pendingSave;

      final reloaded = await loadedState();
      final restored = reloaded.tasks.first;

      expect(restored.checklist, hasLength(3));
      expect(restored.completedParts, 1);
      expect(restored.checklist[1].title, 'Step 1');
    });
  });

  group('habits', () {
    test('tapping up on a good habit pays out and counts', () async {
      final state = await loadedState();
      final task = buildTask(sectionId: 'habits');
      state.addTask(task);

      state.scoreHabitUp(task);

      expect(task.upCount, 1);
      expect(state.gold, 10);
      expect(state.lifetimeXp, 50);
      expect(task.isDone, isFalse);
    });

    test('tapping up does not count toward completion achievements', () async {
      final state = await loadedState();
      final task = buildTask(sectionId: 'habits');
      state.addTask(task);

      for (var i = 0; i < 5; i++) {
        state.scoreHabitUp(task);
      }

      expect(task.upCount, 5);
      expect(state.totalCompletedTasks, 0);
      expect(state.unlockedAchievements, isNot(contains('first_task')));
    });

    test('tapping down costs Vigor and pays nothing', () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'wanderer');

      final task = buildTask(
        sectionId: 'habits',
        difficulty: 2,
        isPositive: false,
        isNegative: true,
      );
      state.addTask(task);

      state.scoreHabitDown(task);

      expect(task.downCount, 1);
      expect(state.gold, 0);
      expect(
        state.mod!.currentVigor,
        Progression.maxVigor - TaskValue.vigorPenalty(2),
      );
      expect(task.neglect, greaterThan(0));
    });

    test('a one-directional habit ignores the direction it does not have',
        () async {
      final state = await loadedState();

      final goodOnly = buildTask(sectionId: 'habits', title: 'Read');
      final badOnly = buildTask(
        sectionId: 'habits',
        title: 'Snack',
        isPositive: false,
        isNegative: true,
      );
      state.addTask(goodOnly);
      state.addTask(badOnly);

      state.scoreHabitDown(goodOnly);
      state.scoreHabitUp(badOnly);

      expect(goodOnly.downCount, 0);
      expect(badOnly.upCount, 0);
    });

    test('a habit cannot be ticked off like a Daily', () async {
      final state = await loadedState();
      final task = buildTask(sectionId: 'habits');
      state.addTask(task);

      state.completeTask(task);

      expect(task.isDone, isFalse);
      expect(state.gold, 0);
    });

    test('scoring a Daily as a habit does nothing', () async {
      final state = await loadedState();
      final task = buildTask();
      state.addTask(task);

      state.scoreHabitUp(task);

      expect(task.upCount, 0);
      expect(state.gold, 0);
    });
  });

  group('resetting the day', () {
    test('clears Dailies but keeps their rewards', () async {
      final state = await loadedState();
      final task = buildTask();
      state.addTask(task);
      state.completeTask(task);

      final goldBefore = state.gold;
      state.resetDay();

      expect(task.isDone, isFalse);
      expect(task.completedAt, isNull);
      expect(state.gold, goldBefore);
    });

    test('leaves finished To-Dos alone', () async {
      final state = await loadedState();
      final task = buildTask(sectionId: 'todos');
      state.addTask(task);
      state.completeTask(task);

      state.resetDay();

      expect(task.isDone, isTrue);
    });
  });

  group('daily rollover', () {
    test('the first ever load just starts the clock', () async {
      final state = await loadedState();

      expect(state.lastRolloverAt, isNotNull);
    });

    test('a day away drains Vigor and breaks the streak', () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'wanderer');

      final task = buildTask();
      task.streak = 4;
      state.addTask(task);

      final now = DateTime.now();
      state.lastRolloverAt = now.subtract(const Duration(days: 1));
      final changed = state.runRolloverAt(now);

      expect(changed, isTrue);
      expect(task.streak, 0);
      expect(task.neglect, greaterThan(0));
      expect(state.mod!.currentVigor, lessThan(Progression.maxVigor));
    });

    test('it tells the player what happened', () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'wanderer');
      state.takeMessages();

      state.addTask(buildTask());

      final now = DateTime.now();
      state.lastRolloverAt = now.subtract(const Duration(days: 1));
      state.runRolloverAt(now);

      final messages = state.takeMessages();

      expect(messages, hasLength(1));
      expect(messages.first, contains('Daily'));
      expect(messages.first, contains('Pip'));
    });

    test('opening the app twice in a day changes nothing', () async {
      final state = await loadedState();
      final task = buildTask();
      state.addTask(task);

      final changed = state.runRolloverAt(DateTime.now());

      expect(changed, isFalse);
      expect(task.neglect, 0);
    });

    test('it survives a save and picks up where it left off', () async {
      final state = await loadedState();
      state.addTask(buildTask());
      await state.pendingSave;

      final reloaded = await loadedState();

      expect(reloaded.lastRolloverAt, isNotNull);
      expect(reloaded.tasks.first.neglect, 0);
    });
  });

  group('sections', () {
    test('a new section carries the type it was given', () async {
      final state = await loadedState();

      state.addSection('Side Quests', TaskType.todo);

      expect(state.sections.last.name, 'Side Quests');
      expect(state.sections.last.type, TaskType.todo);
    });

    test('editing a section can change its name and its type', () async {
      final state = await loadedState();
      final section = state.sections.first;

      state.updateSection(section, name: 'Routines', type: TaskType.daily);

      expect(section.name, 'Routines');
      expect(section.type, TaskType.daily);
    });

    test('no more than the maximum number of sections can exist', () async {
      final state = await loadedState();

      for (var i = 0; i < 10; i++) {
        state.addSection('Extra $i', TaskType.todo);
      }

      expect(state.sections, hasLength(GameState.maxSections));
    });

    test('deleting a section moves its tasks to another one', () async {
      final state = await loadedState();
      state.addSection('Side Quests', TaskType.todo);

      final side = state.sections.last;
      final task = buildTask(sectionId: side.id);
      state.addTask(task);

      state.deleteSection(side);

      expect(state.sections, hasLength(3));
      expect(task.sectionId, state.sections.first.id);
    });

    test('the last section cannot be deleted', () async {
      final state = await loadedState();

      while (state.sections.length > 1) {
        state.deleteSection(state.sections.last);
      }

      state.deleteSection(state.sections.first);

      expect(state.sections, hasLength(1));
    });

    test('section names have to be unique', () async {
      final state = await loadedState();

      expect(state.sectionNameAlreadyExists('dailies'), isTrue);
      expect(state.sectionNameAlreadyExists('Something Else'), isFalse);
    });

    test('a column can be split into named groups', () async {
      final state = await loadedState();
      final dailies = state.sections.firstWhere((s) => s.id == 'dailies');

      final home = state.addGroup(dailies, 'Home');
      final school = state.addGroup(dailies, 'School');

      expect(home, isNotNull);
      expect(school, isNotNull);
      expect(dailies.groups.map((g) => g.name), ['Home', 'School']);

      final dishes = buildTask(title: 'Dishes');
      state.addTask(dishes);
      state.updateTask(
        dishes,
        title: dishes.title,
        difficulty: dishes.difficulty,
        sectionId: 'dailies',
        repeatDays: const [],
        dueDate: null,
        isPositive: true,
        isNegative: false,
        groupId: home!.id,
      );

      expect(dishes.groupId, home.id);
      expect(state.tasksForSection('dailies', groupId: home.id), [dishes]);

      state.deleteGroup(dailies, home);
      expect(dishes.groupId, '');
      expect(dailies.groups.map((g) => g.name), ['School']);
    });
  });

  group('daily skips', () {
    test('a skip token finishes the day without paying or growing the streak',
        () async {
      final state = await loadedState();
      state.unlockedAchievements.add('first_task');
      state.inventory.add(ShopItem.skipTokenId);
      final task = buildTask();
      state.addTask(task);

      expect(state.skipDaily(task), isTrue);

      expect(task.isDone, isTrue);
      expect(task.isSkipped, isTrue);
      expect(task.streak, 0);
      expect(state.gold, 0);
      expect(state.inventory, isEmpty);
    });

    test('a skip does nothing without a token', () async {
      final state = await loadedState();
      final task = buildTask();
      state.addTask(task);

      expect(state.skipDaily(task), isFalse);

      expect(task.isSkipped, isFalse);
      expect(task.isDone, isFalse);
      expect(state.takeMessages().first, contains('Skip Token'));
    });
  });

  group('reorder', () {
    test('dragging a task changes the order it is listed', () async {
      final state = await loadedState();
      final a = buildTask(title: 'A');
      final b = buildTask(title: 'B');
      final c = buildTask(title: 'C');
      state.addTask(a);
      state.addTask(b);
      state.addTask(c);

      expect(
        state.tasksForSection('dailies').map((t) => t.title),
        ['A', 'B', 'C'],
      );

      state.reorderTasks(
        sectionId: 'dailies',
        groupId: '',
        oldIndex: 0,
        newIndex: 3,
      );

      expect(
        state.tasksForSection('dailies').map((t) => t.title),
        ['B', 'C', 'A'],
      );
    });

    test('a task can be dropped into another group', () async {
      final state = await loadedState();
      final dailies = state.sections.firstWhere((s) => s.id == 'dailies');
      final home = state.addGroup(dailies, 'Home')!;
      final school = state.addGroup(dailies, 'School')!;
      final dishes = buildTask(title: 'Dishes');
      final homework = buildTask(title: 'Homework');
      state.addTask(dishes);
      state.addTask(homework);
      state.placeTask(dishes, sectionId: 'dailies', groupId: home.id);
      state.placeTask(homework, sectionId: 'dailies', groupId: school.id);

      state.placeTask(dishes, sectionId: 'dailies', groupId: school.id, index: 0);

      expect(dishes.groupId, school.id);
      expect(
        state.tasksForSection('dailies', groupId: school.id).map((t) => t.title),
        ['Dishes', 'Homework'],
      );
      expect(state.tasksForSection('dailies', groupId: home.id), isEmpty);
    });

    test('a task can be dropped into another column', () async {
      final state = await loadedState();
      final task = buildTask(title: 'File this');
      state.addTask(task);

      state.placeTask(task, sectionId: 'todos');

      expect(task.sectionId, 'todos');
      expect(task.groupId, '');
      expect(state.tasksForSection('dailies'), isEmpty);
      expect(state.tasksForSection('todos').map((t) => t.title), ['File this']);
    });
  });

  group('shop', () {
    test('ships with the three default rewards already unlocked', () async {
      final state = await loadedState();

      expect(state.discoveredShopItems.map((item) => item.id), [
        'cheat_meal',
        'gaming_night',
        'energy_drink',
        ShopItem.skipTokenId,
      ]);
      expect(state.undiscoveredShopItems, hasLength(8));
    });

    test('adding a reward marks it user created and discovered', () async {
      final state = await loadedState();

      final item = state.addShopItem(
        name: 'Long Bath',
        description: 'Soak for an hour.',
        cost: 40,
      );

      expect(state.shopItems, contains(item));
      expect(item.isUserCreated, isTrue);
      expect(item.isDiscovered, isTrue);
    });

    test('editing a reward updates it in place', () async {
      final state = await loadedState();
      final item = state.shopItems.first;

      state.updateShopItem(
        item,
        name: 'Big Cheat Meal',
        description: 'Two courses.',
        cost: 150,
        iconId: 'meal',
      );

      expect(state.shopItemById(item.id)!.name, 'Big Cheat Meal');
      expect(state.shopItemById(item.id)!.cost, 150);
    });

    test('deleting a reward also clears it out of the inventory', () async {
      final state = await loadedState();
      state.gold = 500;

      final item = state.shopItems.first;
      state.buyItem(item);
      expect(state.inventory, contains(item.id));

      state.deleteShopItem(item);

      expect(state.shopItemById(item.id), isNull);
      expect(state.inventory, isEmpty);
    });

    test('reward names have to be unique', () async {
      final state = await loadedState();

      expect(state.shopItemNameAlreadyExists('cheat meal'), isTrue);
      expect(state.shopItemNameAlreadyExists('Brand New'), isFalse);
    });

    test('buying spends gold and stores the item ID', () async {
      final state = await loadedState();
      state.gold = 100;

      final item = state.shopItems.firstWhere((i) => i.id == 'energy_drink');
      state.buyItem(item);

      expect(state.gold, 70);
      expect(state.inventory, ['energy_drink']);
      expect(state.inventoryCounts['energy_drink'], 1);
    });

    test('buying is refused when gold is short', () async {
      final state = await loadedState();
      state.gold = 5;

      state.buyItem(state.shopItems.first);

      expect(state.gold, 5);
      expect(state.inventory, isEmpty);
    });

    test('using an item removes one copy', () async {
      final state = await loadedState();
      state.gold = 200;

      final item = state.shopItems.firstWhere((i) => i.id == 'energy_drink');
      state.buyItem(item);
      state.buyItem(item);

      state.useInventoryItem('energy_drink');

      expect(state.inventoryCounts['energy_drink'], 1);
    });

    test('undiscovered rewards are hidden until the Mod finds them', () async {
      final state = await loadedState();
      final hidden = state.addShopItem(
        name: 'Hidden Relic',
        description: 'Found on an adventure.',
        cost: 20,
      );
      hidden.isDiscovered = false;

      expect(state.discoveredShopItems, isNot(contains(hidden)));
      expect(state.undiscoveredShopItems, contains(hidden));

      state.discoverShopItem(hidden.id);

      expect(state.discoveredShopItems, contains(hidden));
    });
  });

  group('achievements', () {
    test('the first completed task unlocks One Small Step', () async {
      final state = await loadedState();

      state.completeTask(buildTask(difficulty: 0));

      expect(state.unlockedAchievements, contains('first_task'));
      // 5 gold for the easy task, plus the 25 gold achievement reward.
      expect(state.gold, 30);
    });

    test('an achievement only pays out once', () async {
      final state = await loadedState();

      state.completeTask(buildTask(title: 'A', difficulty: 0));
      final goldAfterFirst = state.gold;

      state.completeTask(buildTask(title: 'B', difficulty: 0));

      expect(state.gold, goldAfterFirst + 5);
    });
  });

  group('the Mod', () {
    test('is absent until one is created', () async {
      final state = await loadedState();

      expect(state.hasMod, isFalse);

      state.createMod(name: 'Pip', appearanceId: 'knight');

      expect(state.hasMod, isTrue);
      expect(state.mod!.name, 'Pip');
      expect(state.mod!.appearanceId, 'knight');
    });

    test('spending a stat point requires a banked point', () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'wanderer');

      state.spendStatPoint(ModStat.might);
      expect(state.mod!.mightPoints, 0);

      state.mod!.unspentStatPoints = 1;
      state.spendStatPoint(ModStat.might);
      expect(state.mod!.mightPoints, 1);
    });

    test('resetting all progress keeps the Mod but clears its level',
        () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'scout');
      state.mod!.gainXp(5000);

      state.resetAllProgress();

      expect(state.hasMod, isTrue);
      expect(state.mod!.name, 'Pip');
      expect(state.mod!.level, 1);
      expect(state.mod!.currentVigor, Progression.maxVigor);
      expect(state.gold, 0);
      expect(state.tasks, isEmpty);
      expect(state.sections, hasLength(3));
      expect(state.discoveredShopItems, hasLength(4));
      expect(state.undiscoveredShopItems, hasLength(8));
    });
  });

  group('persistence', () {
    test('a new GameState reloads what the previous one saved', () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'scholar');
      state.addTask(buildTask(title: 'Stretch'));
      state.addShopItem(
        name: 'Long Bath',
        description: 'Soak for an hour.',
        cost: 40,
      );
      state.gold = 123;
      state.completeTask(state.tasks.first);
      await state.pendingSave;

      final reloaded = await loadedState();

      expect(reloaded.mod!.name, 'Pip');
      expect(reloaded.mod!.appearanceId, 'scholar');
      expect(reloaded.tasks, hasLength(1));
      expect(reloaded.tasks.first.title, 'Stretch');
      expect(reloaded.tasks.first.isDone, isTrue);
      expect(reloaded.tasks.first.streak, 1);
      expect(reloaded.shopItems, hasLength(state.shopItems.length));
      expect(reloaded.gold, state.gold);
    });

    test('section types survive a reload', () async {
      final state = await loadedState();
      state.addSection('Errands', TaskType.todo);
      await state.pendingSave;

      final reloaded = await loadedState();

      expect(reloaded.sections.map((section) => section.type), [
        TaskType.habit,
        TaskType.daily,
        TaskType.todo,
        TaskType.todo,
      ]);
    });

    test('habit counters and neglect survive a reload', () async {
      final state = await loadedState();
      final task = buildTask(sectionId: 'habits');
      state.addTask(task);
      state.scoreHabitUp(task);
      await state.pendingSave;

      final reloaded = await loadedState();

      expect(reloaded.tasks.first.upCount, 1);
    });

    test('tasks pointing at a missing section fall back to the first one',
        () async {
      final state = await loadedState();
      state.addTask(buildTask(sectionId: 'deleted-section'));
      await state.pendingSave;

      final reloaded = await loadedState();

      expect(reloaded.tasks.first.sectionId, reloaded.sections.first.id);
    });
  });

  group('adventures', () {
    test('a resting Mod cannot be sent out', () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'wanderer');
      state.mod!.currentVigor = 0;

      expect(state.sendModOnAdventure(), isFalse);
      expect(state.isModOut, isFalse);
    });

    test('sending picks a seed that every platform can generate', () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'wanderer');

      expect(state.sendModOnAdventure(), isTrue);
      expect(state.adventure.seed, greaterThanOrEqualTo(0));
      expect(state.adventure.seed, lessThan(0x7fffffff));
    });

    test('sending twice is refused', () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'wanderer');

      expect(state.sendModOnAdventure(), isTrue);
      expect(state.sendModOnAdventure(), isFalse);
      expect(state.isModOut, isTrue);
    });

    test('nothing happens until a tick of real time has passed', () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'wanderer');

      final start = DateTime(2026, 3, 1, 8);
      state.sendModOnAdventure(now: start);

      expect(state.advanceAdventure(now: start.add(const Duration(minutes: 10))), isFalse);
      expect(state.adventure.log, isEmpty);
    });

    test('recalling pays out the pack and brings the Mod home', () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'wanderer');
      state.takeMessages();

      final start = DateTime(2026, 3, 1, 8);
      state.sendModOnAdventure(now: start);

      // Six hours is twelve ticks, well within a full Vigor tank.
      state.advanceAdventure(now: start.add(const Duration(hours: 6)));

      expect(state.adventure.log, isNotEmpty);

      final goldBefore = state.gold;
      final pendingGold = state.adventure.pendingGold;
      final pendingXp = state.adventure.pendingXp;

      expect(state.recallMod(now: start.add(const Duration(hours: 6))), isTrue);
      expect(state.isModOut, isFalse);
      expect(state.gold, goldBefore + pendingGold);
      expect(state.lifetimeXp, pendingXp);
      expect(state.adventure.hasHaul, isFalse);
    });

    test('recalling a Skip Token puts a copy in inventory', () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'wanderer');
      state.takeMessages();

      final start = DateTime(2026, 3, 1, 8);
      state.sendModOnAdventure(now: start);
      state.adventure.pendingItemIds.add(ShopItem.skipTokenId);

      expect(state.recallMod(now: start), isTrue);
      expect(state.inventory, [ShopItem.skipTokenId]);
    });
  });

  group('messages', () {
    test('are queued for the UI and drained once', () async {
      final state = await loadedState();
      state.createMod(name: 'Pip', appearanceId: 'wanderer');

      final messages = state.takeMessages();

      expect(messages, hasLength(1));
      expect(messages.first, contains('Pip'));
      expect(state.takeMessages(), isEmpty);
    });
  });
}

TaskType taskTypeOf(GameState state, String sectionId) {
  return state.taskTypeFor(buildTask(sectionId: sectionId));
}
