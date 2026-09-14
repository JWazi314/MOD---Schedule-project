import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../game/adventure_engine.dart';
import '../game/daily_rollover.dart';
import '../game/progression.dart';
import '../game/task_value.dart';
import '../models/achievement.dart';
import '../models/adventure.dart';
import '../models/checklist_item.dart';
import '../models/mod_character.dart';
import '../models/shop_item.dart';
import '../models/task.dart';
import '../models/task_section.dart';
import '../models/task_type.dart';
import 'save_data.dart';

/// Owns every piece of game state and all persistence.
///
/// Pages read this through Provider and call methods on it rather than
/// reaching into each other. Nothing here touches BuildContext: player-facing
/// messages are queued in [takeMessages] for the UI to drain.
class GameState extends ChangeNotifier {
  static const int maxSections = 6;
  static const int maxGroupsPerSection = 6;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  ModCharacter? _mod;
  ModCharacter? get mod => _mod;
  bool get hasMod => _mod != null;

  int gold = 0;
  int silver = 0;

  /// Total experience ever earned. The Mod's own [ModCharacter.xp] resets on
  /// level up, so achievements track this instead.
  int lifetimeXp = 0;

  int totalCompletedTasks = 0;
  int totalHardTasksCompleted = 0;

  List<Task> tasks = [];
  List<TaskSection> sections = defaultSections();

  /// When the last daily rollover was processed. Null means this save has
  /// never rolled over, so the first load just starts the clock.
  DateTime? lastRolloverAt;

  /// Where the Mod is and what it is carrying.
  AdventureState adventure = AdventureState();

  List<ShopItem> shopItems = defaultShopItems();

  /// Purchased items, stored as shop item IDs. Duplicates are allowed.
  List<String> inventory = [];

  Set<String> unlockedAchievements = {};
  Set<String> completedDays = {};

  final List<String> _messages = [];

  TaskPayout? _latestPayout;
  int _payoutToken = 0;

  /// The most recent gold / silver / XP award, so the board can flash it
  /// next to the task that just paid out.
  TaskPayout? get latestPayout => _latestPayout;

  /// Returns and clears any queued player-facing messages.
  List<String> takeMessages() {
    if (_messages.isEmpty) {
      return const [];
    }
    final drained = List<String>.from(_messages);
    _messages.clear();
    return drained;
  }

  void _queueMessage(String message) {
    _messages.add(message);
  }

  // ---------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------

  Future<void> load() async {
    final data = await SaveData.load();

    if (data != null) {
      _applySnapshot(data);
    }

    // Rollover first, so missed Dailies eat the Vigor before the adventure
    // gets a chance to spend it.
    final rolloverChanged = _runRollover();
    final adventureChanged = _advanceAdventure(commit: false);

    _isLoaded = true;
    _checkAchievements(save: false);

    if (rolloverChanged || adventureChanged) {
      _commit();
    } else {
      notifyListeners();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': SaveData.currentSchemaVersion,
      'gold': gold,
      'silver': silver,
      'lifetimeXp': lifetimeXp,
      'totalCompletedTasks': totalCompletedTasks,
      'totalHardTasksCompleted': totalHardTasksCompleted,
      'completedDays': completedDays.toList(),
      'achievements': unlockedAchievements.toList(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'sections': sections.map((section) => section.toJson()).toList(),
      'lastRolloverAt': lastRolloverAt?.toIso8601String(),
      'inventory': inventory,
      'shopItems': shopItems.map((item) => item.toJson()).toList(),
      'mod': _mod?.toJson(),
      'adventure': adventure.toJson(),
    };
  }

  void _applySnapshot(Map<String, dynamic> data) {
    gold = (data['gold'] as num?)?.toInt() ?? 0;
    silver = (data['silver'] as num?)?.toInt() ?? 0;
    lifetimeXp = (data['lifetimeXp'] as num?)?.toInt() ?? 0;
    totalCompletedTasks = (data['totalCompletedTasks'] as num?)?.toInt() ?? 0;
    totalHardTasksCompleted =
        (data['totalHardTasksCompleted'] as num?)?.toInt() ?? 0;

    completedDays = _stringSet(data['completedDays']);
    unlockedAchievements = _stringSet(data['achievements']);

    tasks = _mapList(data['tasks']).map(Task.fromJson).toList();
    _ensureTaskIds();

    final loadedSections = _mapList(data['sections'])
        .map(TaskSection.fromJson)
        .where(
          (section) =>
              section.id.trim().isNotEmpty && section.name.trim().isNotEmpty,
        )
        .toList();

    if (loadedSections.isNotEmpty) {
      sections = loadedSections;
    }

    // Tasks whose section disappeared fall back to the first one.
    final validSectionIds = sections.map((section) => section.id).toSet();
    final defaultSectionId = sections.first.id;
    for (final task in tasks) {
      if (!validSectionIds.contains(task.sectionId)) {
        task.sectionId = defaultSectionId;
      }
    }
    _repairGroupIds();

    final rolloverJson = data['lastRolloverAt'];
    lastRolloverAt = rolloverJson is String
        ? DateTime.tryParse(rolloverJson)
        : null;

    final loadedShopItems = _mapList(data['shopItems'])
        .map(ShopItem.fromJson)
        .where((item) => item.id.trim().isNotEmpty)
        .toList();

    if (loadedShopItems.isNotEmpty) {
      shopItems = loadedShopItems;
    }
    _ensureSeededShopItems();

    inventory = _stringList(data['inventory']);

    final modJson = data['mod'];
    if (modJson is Map) {
      _mod = ModCharacter.fromJson(Map<String, dynamic>.from(modJson));
    }

    final adventureJson = data['adventure'];
    if (adventureJson is Map) {
      adventure = AdventureState.fromJson(
        Map<String, dynamic>.from(adventureJson),
      );
    }
  }

  Future<void> _pendingSave = Future<void>.value();

  /// Resolves once the most recent write has landed. Tests await this instead
  /// of racing the fire-and-forget saves that mutations kick off.
  Future<void> get pendingSave => _pendingSave;

  void _commit() {
    notifyListeners();
    _pendingSave = SaveData.save(toJson());
  }

  static Set<String> _stringSet(Object? value) {
    return _stringList(value).toSet();
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

  // ---------------------------------------------------------------------
  // Daily rollover
  // ---------------------------------------------------------------------

  Map<String, TaskType> get _sectionTypes {
    return {for (final section in sections) section.id: section.type};
  }

  /// Closes out any days that passed while the app was shut. Returns whether
  /// anything changed and needs saving.
  bool _runRollover({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final last = lastRolloverAt;

    if (last == null) {
      lastRolloverAt = currentTime;
      return true;
    }

    final outcome = DailyRollover.run(
      tasks: tasks,
      sectionTypes: _sectionTypes,
      lastRolloverAt: last,
      now: currentTime,
    );

    if (!outcome.didRun) {
      return false;
    }

    lastRolloverAt = currentTime;

    final mod = _mod;

    if (mod != null) {
      if (outcome.vigorLost > 0) {
        mod.drainVigor(outcome.vigorLost);
      }

      // Quiet days let the Mod get its energy back, which is the only thing
      // that refills the adventure tank without finishing something.
      if (outcome.restfulDays > 0) {
        mod.restoreVigor(
          Progression.vigorRecoveredPerDay(mod.vigor) * outcome.restfulDays,
        );
      }
    }

    if (outcome.missedDailies > 0) {
      final count = outcome.missedDailies;
      final plural = count == 1 ? 'Daily' : 'Dailies';
      final name = _mod?.name ?? 'Your Mod';

      _queueMessage(
        '$count $plural went unfinished. $name lost '
        '${outcome.vigorLost} Vigor.',
      );
    }

    return true;
  }

  /// Test seam for the rollover, which otherwise only runs on load.
  @visibleForTesting
  bool runRolloverAt(DateTime now) => _runRollover(now: now);

  // ---------------------------------------------------------------------
  // Adventures
  // ---------------------------------------------------------------------

  bool get isModOut => adventure.isOut;

  /// Whether the Mod has the energy for at least one more event.
  bool get canAffordAdventureTick =>
      (_mod?.currentVigor ?? 0) >= Progression.vigorPerTick;

  /// Sends the Mod out. Refuses if it is already gone or too worn down.
  bool sendModOnAdventure({DateTime? now}) {
    final mod = _mod;

    if (mod == null || adventure.isOut || mod.isResting) {
      return false;
    }

    // Web compiles shifts to 32-bit JS ops, so `1 << 32` is 0 there and
    // nextInt throws. Stay inside a range every target accepts.
    adventure.dispatch(
      seed: Random().nextInt(0x7fffffff),
      now: now ?? DateTime.now(),
    );

    _queueMessage('${mod.name} sets out.');
    _commit();
    return true;
  }

  /// Replays whatever happened since the last tick. Safe to call as often as
  /// you like: it is a no-op until a full tick of real time has passed.
  bool advanceAdventure({DateTime? now}) => _advanceAdventure(now: now);

  bool _advanceAdventure({DateTime? now, bool commit = true}) {
    final mod = _mod;

    if (mod == null || !adventure.isOut) {
      return false;
    }

    final outcome = AdventureEngine.run(
      adventure: adventure,
      modName: mod.name,
      availableVigor: mod.currentVigor,
      might: mod.might,
      fortune: mod.fortune,
      undiscoveredItems: undiscoveredShopItems,
      repeatableFinds: repeatableAdventureFinds,
      now: now ?? DateTime.now(),
    );

    if (!outcome.didRun) {
      return false;
    }

    mod.drainVigor(outcome.vigorSpent);

    // Both of these only fire on the tick that crosses the line, so the live
    // ticker cannot repeat them.
    if (outcome.ranOutOfVigor) {
      _queueMessage(
        '${mod.name} ran out of energy and made camp. '
        'Finish something to send it on its way.',
      );
    } else if (outcome.packFilled) {
      _queueMessage("${mod.name}'s pack is full. Recall it to collect.");
    }

    if (commit) {
      _commit();
    }

    return true;
  }

  /// Brings the Mod home and hands over everything in its pack.
  bool recallMod({DateTime? now}) {
    final mod = _mod;

    if (mod == null || !adventure.isOut) {
      return false;
    }

    // Catch up first, so recalling never throws away time already earned.
    _advanceAdventure(now: now, commit: false);

    final foundGold = adventure.pendingGold;
    final foundXp = adventure.pendingXp;
    final foundItems = List<String>.from(adventure.pendingItemIds);

    adventure.clearHaul();

    gold += foundGold;
    lifetimeXp += foundXp;

    final levelUp = mod.gainXp(foundXp);

    for (final itemId in foundItems) {
      _discoverShopItem(itemId);
      if (itemId == ShopItem.skipTokenId) {
        inventory.add(itemId);
      }
    }

    _queueMessage(_haulSummary(mod.name, foundGold, foundXp, foundItems));

    if (levelUp.levelsGained > 0) {
      _queueMessage('${mod.name} reached level ${mod.level}!');
    }

    _checkAchievements(save: false);
    _commit();
    return true;
  }

  static String _haulSummary(
    String name,
    int foundGold,
    int foundXp,
    List<String> foundItems,
  ) {
    if (foundGold == 0 && foundXp == 0 && foundItems.isEmpty) {
      return '$name is home empty handed.';
    }

    final parts = <String>[
      if (foundGold > 0) '$foundGold Gold',
      if (foundXp > 0) '$foundXp XP',
      if (foundItems.isNotEmpty)
        '${foundItems.length} find${foundItems.length == 1 ? '' : 's'}',
    ];

    return '$name is home with ${parts.join(', ')}.';
  }

  Timer? _liveTicker;

  /// Keeps an adventure moving while the app is open. Only the running app
  /// starts this; tests drive time explicitly so the suite has no live timers.
  void startLiveTicks() {
    _liveTicker ??= Timer.periodic(
      const Duration(minutes: 1),
      (_) => _advanceAdventure(),
    );
  }

  @override
  void dispose() {
    _liveTicker?.cancel();
    _liveTicker = null;
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // The Mod
  // ---------------------------------------------------------------------

  void createMod({required String name, required String appearanceId}) {
    _mod = ModCharacter(name: name.trim(), appearanceId: appearanceId);
    _queueMessage('${_mod!.name} is ready for adventure.');
    _commit();
  }

  void updateModIdentity({String? name, String? appearanceId}) {
    final mod = _mod;
    if (mod == null) {
      return;
    }

    if (name != null && name.trim().isNotEmpty) {
      mod.name = name.trim();
    }
    if (appearanceId != null) {
      mod.appearanceId = appearanceId;
    }

    _commit();
  }

  void spendStatPoint(ModStat stat) {
    final mod = _mod;
    if (mod == null || !mod.spendStatPoint(stat)) {
      return;
    }
    _commit();
  }

  // ---------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------

  TaskSection? sectionById(String id) {
    for (final section in sections) {
      if (section.id == id) {
        return section;
      }
    }
    return null;
  }

  TaskType taskTypeFor(Task task) {
    return sectionById(task.sectionId)?.type ?? TaskType.daily;
  }

  void _ensureReserve(Task task) {
    if (task.hasReserve) {
      return;
    }

    final raw = TaskValue.payoutFor(task, token: ++_payoutToken);
    task.reservedGold = Progression.applyGoldMultiplier(
      raw.gold,
      _mod?.fortune ?? 0,
    );
    task.reservedSilver = raw.silver;
    task.reservedXp = Progression.applyXpMultiplier(raw.xp, _mod?.focus ?? 0);
  }

  int _partSliver(int reserved, int paid, int parts) {
    if (reserved <= paid) {
      return 0;
    }
    final chunk = max(1, reserved ~/ max(1, parts));
    return min(chunk, reserved - paid);
  }

  void _grant({
    required Task task,
    required int goldAmount,
    required int silverAmount,
    required int xpAmount,
    required bool countAsCompletion,
    required bool restoreVigor,
  }) {
    if (goldAmount <= 0 && silverAmount <= 0 && xpAmount <= 0) {
      return;
    }

    gold += goldAmount;
    silver += silverAmount;
    lifetimeXp += xpAmount;

    _latestPayout = TaskPayout(
      task: task,
      gold: goldAmount,
      silver: silverAmount,
      xp: xpAmount,
      token: ++_payoutToken,
    );

    if (countAsCompletion) {
      totalCompletedTasks++;
      if (task.difficulty == 2) {
        totalHardTasksCompleted++;
      }
    }

    final date = DateTime.now();
    completedDays.add('${date.year}-${date.month}-${date.day}');

    final mod = _mod;
    if (mod != null) {
      final result = mod.gainXp(xpAmount);
      if (restoreVigor) {
        mod.restoreVigor(5);
      }

      if (result.leveledUp) {
        _queueMessage(
          '${mod.name} reached level ${mod.level}! '
          '+${result.statPointsGained} stat point'
          '${result.statPointsGained == 1 ? '' : 's'}',
        );
      }
    }
  }

  void _awardFor(Task task, {required bool countAsCompletion}) {
    _ensureReserve(task);
    _grant(
      task: task,
      goldAmount: max(0, task.reservedGold - task.paidGold),
      silverAmount: max(0, task.reservedSilver - task.paidSilver),
      xpAmount: max(0, task.reservedXp - task.paidXp),
      countAsCompletion: countAsCompletion,
      restoreVigor: true,
    );
    task.clearReserve();
  }

  void completeTask(Task task) {
    final type = taskTypeFor(task);

    // Habits are never "done"; they are tapped instead.
    if (task.isDone || type == TaskType.habit) {
      return;
    }

    // Rewards read neglect before completing clears it.
    _awardFor(task, countAsCompletion: true);

    task.isDone = true;
    task.isSkipped = false;
    task.completedAt = DateTime.now();
    task.neglect = TaskValue.afterCompletion(task.neglect);

    // Ticking the task off is a statement that the whole thing is done, so
    // the parts follow rather than being left half filled.
    task.tickEveryPart();

    if (type == TaskType.daily) {
      task.streak++;
    }

    _checkAchievements(save: false);
    _commit();
  }

  /// Ticks one part of a task off. Finishing the last part finishes the task.
  void toggleChecklistItem(Task task, ChecklistItem item) {
    // A finished task is locked, so a stray tap cannot un-complete it and
    // hand out the reward twice.
    if (task.isDone || taskTypeFor(task) == TaskType.habit) {
      return;
    }

    item.isDone = !item.isDone;

    if (item.isDone && task.allPartsDone) {
      completeTask(task);
      return;
    }

    if (item.isDone) {
      _ensureReserve(task);
      final parts = max(1, task.checklist.length);
      final goldBit = _partSliver(task.reservedGold, task.paidGold, parts);
      final silverBit = _partSliver(
        task.reservedSilver,
        task.paidSilver,
        parts,
      );
      final xpBit = _partSliver(task.reservedXp, task.paidXp, parts);
      task.paidGold += goldBit;
      task.paidSilver += silverBit;
      task.paidXp += xpBit;
      _grant(
        task: task,
        goldAmount: goldBit,
        silverAmount: silverBit,
        xpAmount: xpBit,
        countAsCompletion: false,
        restoreVigor: false,
      );
    } else if (task.hasReserve) {
      final parts = max(1, task.checklist.length);
      final goldBit = min(
        task.paidGold,
        _partSliver(task.reservedGold, 0, parts),
      );
      final silverBit = min(
        task.paidSilver,
        _partSliver(task.reservedSilver, 0, parts),
      );
      final xpBit = min(task.paidXp, _partSliver(task.reservedXp, 0, parts));
      task.paidGold -= goldBit;
      task.paidSilver -= silverBit;
      task.paidXp -= xpBit;
      gold = max(0, gold - goldBit);
      silver = max(0, silver - silverBit);
      lifetimeXp = max(0, lifetimeXp - xpBit);
    }

    _commit();
  }

  /// Tapping the plus on a good habit.
  void scoreHabitUp(Task task) {
    if (taskTypeFor(task) != TaskType.habit || !task.isPositive) {
      return;
    }

    // Habit taps pay out but do not count toward completion achievements,
    // which would otherwise be a button-mashing exercise.
    _awardFor(task, countAsCompletion: false);

    task.upCount++;
    task.neglect = TaskValue.afterCompletion(task.neglect);

    _checkAchievements(save: false);
    _commit();
  }

  /// Tapping the minus on a bad habit. Costs Vigor, never gold or levels.
  void scoreHabitDown(Task task) {
    if (taskTypeFor(task) != TaskType.habit || !task.isNegative) {
      return;
    }

    task.downCount++;
    task.neglect = TaskValue.afterMiss(
      task.neglect,
      TaskValue.missedDailyStep,
    );

    final penalty = TaskValue.vigorPenalty(task.difficulty);
    _mod?.drainVigor(penalty);

    _commit();
  }

  void addTask(Task task) {
    if (task.id.isEmpty) {
      task.id = createId();
    }
    if (task.sortOrder == 0) {
      task.sortOrder = _nextSortOrder(task.sectionId, task.groupId);
    }
    tasks.add(task);
    _commit();
  }

  /// Applies an edit in place so streaks, neglect, and habit counts survive.
  void updateTask(
    Task task, {
    required String title,
    required int difficulty,
    required String sectionId,
    required List<int> repeatDays,
    required DateTime? dueDate,
    required bool isPositive,
    required bool isNegative,
    String? description,
    String? groupId,
    List<ChecklistItem>? checklist,
  }) {
    final sectionChanged = task.sectionId != sectionId;
    final oldGroup = task.groupId;
    task.title = title.trim();
    if (description != null) {
      task.description = description.trim();
    }
    task.difficulty = difficulty;
    task.sectionId = sectionId;
    task.repeatDays = List<int>.from(repeatDays);
    task.dueDate = dueDate;
    task.isPositive = isPositive;
    task.isNegative = isNegative;
    if (groupId != null || sectionChanged) {
      final nextGroup = groupId ?? '';
      final section = sectionById(sectionId);
      task.groupId = section?.groupById(nextGroup) == null ? '' : nextGroup;
      if (sectionChanged || task.groupId != oldGroup) {
        task.sortOrder = _nextSortOrder(sectionId, task.groupId);
      }
    }

    if (checklist != null) {
      task.checklist = List<ChecklistItem>.from(checklist);
    }

    _commit();
  }

  void removeTask(Task task) {
    tasks.remove(task);
    _commit();
  }

  /// Clears completion on Dailies only. To-Dos stay done and Habits have no
  /// completed state to clear.
  void resetDay() {
    for (final task in tasks) {
      if (taskTypeFor(task) != TaskType.daily) {
        continue;
      }
      task.isDone = false;
      task.isSkipped = false;
      task.completedAt = null;
      task.clearChecklist();
      task.clearReserve();
    }
    _commit();
  }

  List<Task> skippableDailies({DateTime? now}) {
    final today = now ?? DateTime.now();
    return tasks
        .where(
          (task) =>
              taskTypeFor(task) == TaskType.daily &&
              !task.isDone &&
              task.isDueOn(today),
        )
        .toList();
  }

  int get skipTokenCount => inventoryCounts[ShopItem.skipTokenId] ?? 0;

  /// Spends one Skip Token to mark a Daily skipped for today. Streak holds;
  /// no gold or XP is paid.
  bool skipDaily(Task task, {DateTime? now}) {
    if (taskTypeFor(task) != TaskType.daily || task.isDone) {
      return false;
    }
    if (!task.isDueOn(now ?? DateTime.now())) {
      return false;
    }
    if (skipTokenCount <= 0) {
      _queueMessage('You need a Skip Token.');
      notifyListeners();
      return false;
    }

    final tokenAt = inventory.indexOf(ShopItem.skipTokenId);
    if (tokenAt < 0) {
      return false;
    }
    inventory.removeAt(tokenAt);

    task.isDone = true;
    task.isSkipped = true;
    task.completedAt = DateTime.now();
    task.tickEveryPart();
    task.clearReserve();
    _queueMessage('${task.title} was skipped.');
    _commit();
    return true;
  }

  // ---------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------

  bool sectionNameAlreadyExists(String name, {String? ignoredSectionId}) {
    final cleanedName = name.trim().toLowerCase();

    return sections.any(
      (section) =>
          section.id != ignoredSectionId &&
          section.name.trim().toLowerCase() == cleanedName,
    );
  }

  int _idSeq = 0;

  String createId() {
    _idSeq++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idSeq';
  }

  void addSection(String name, TaskType type) {
    if (sections.length >= maxSections) {
      return;
    }
    sections.add(TaskSection(id: createId(), name: name.trim(), type: type));
    _commit();
  }

  void updateSection(
    TaskSection section, {
    required String name,
    required TaskType type,
  }) {
    section.name = name.trim();
    section.type = type;
    _commit();
  }

  void deleteSection(TaskSection section) {
    if (sections.length <= 1) {
      return;
    }

    final replacement = sections.firstWhere(
      (candidate) => candidate.id != section.id,
    );

    for (final task in tasks.where((task) => task.sectionId == section.id)) {
      task.sectionId = replacement.id;
      task.groupId = '';
    }

    sections.remove(section);
    _commit();
  }

  List<Task> tasksForSection(String sectionId, {String? groupId}) {
    final matches = tasks.where((task) {
      if (task.sectionId != sectionId) {
        return false;
      }
      if (groupId != null && task.groupId != groupId) {
        return false;
      }
      return true;
    }).toList();
    matches.sort((a, b) {
      final byGroup = a.groupId.compareTo(b.groupId);
      if (byGroup != 0) {
        return byGroup;
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return matches;
  }

  void reorderTasks({
    required String sectionId,
    required String groupId,
    required int oldIndex,
    required int newIndex,
  }) {
    final slice = tasksForSection(sectionId, groupId: groupId);
    if (oldIndex < 0 || oldIndex >= slice.length) {
      return;
    }
    placeTask(
      slice[oldIndex],
      sectionId: sectionId,
      groupId: groupId,
      index: newIndex,
    );
  }

  /// Puts [task] in a section/group at [index]. Used by arrange-mode drops
  /// so a card can leave its list and land in another group or column.
  void placeTask(
    Task task, {
    required String sectionId,
    String groupId = '',
    int? index,
  }) {
    final destSection = sectionById(sectionId);
    if (destSection == null) {
      return;
    }

    final destGroup = destSection.groupById(groupId) == null ? '' : groupId;
    final fromSectionId = task.sectionId;
    final fromGroupId = task.groupId;

    if (fromSectionId == sectionId && fromGroupId == destGroup) {
      final slice = tasksForSection(sectionId, groupId: destGroup);
      final oldIndex = slice.indexWhere((item) => item.id == task.id);
      if (oldIndex < 0) {
        return;
      }
      var dest = (index ?? slice.length).clamp(0, slice.length);
      if (dest == oldIndex || dest == oldIndex + 1) {
        return;
      }
      slice.removeAt(oldIndex);
      if (dest > oldIndex) {
        dest -= 1;
      }
      slice.insert(dest.clamp(0, slice.length), task);
      _reindex(slice);
      _commit();
      return;
    }

    task.sectionId = sectionId;
    task.groupId = destGroup;

    final destSlice = tasksForSection(sectionId, groupId: destGroup)
        .where((item) => item.id != task.id)
        .toList();
    final dest = (index ?? destSlice.length).clamp(0, destSlice.length);
    destSlice.insert(dest, task);
    _reindex(destSlice);
    _reindex(tasksForSection(fromSectionId, groupId: fromGroupId));
    _commit();
  }

  void _reindex(List<Task> slice) {
    for (var i = 0; i < slice.length; i++) {
      slice[i].sortOrder = i;
    }
  }

  bool groupNameAlreadyExists(
    TaskSection section,
    String name, {
    String? ignoredGroupId,
  }) {
    final cleaned = name.trim().toLowerCase();
    return section.groups.any(
      (group) =>
          group.id != ignoredGroupId &&
          group.name.trim().toLowerCase() == cleaned,
    );
  }

  TaskGroup? addGroup(TaskSection section, String name) {
    if (section.groups.length >= maxGroupsPerSection) {
      return null;
    }
    final cleaned = name.trim();
    if (cleaned.isEmpty || groupNameAlreadyExists(section, cleaned)) {
      return null;
    }
    final group = TaskGroup(id: createId(), name: cleaned);
    section.groups.add(group);
    _commit();
    return group;
  }

  void updateGroup(TaskSection section, TaskGroup group, {required String name}) {
    final cleaned = name.trim();
    if (cleaned.isEmpty ||
        groupNameAlreadyExists(section, cleaned, ignoredGroupId: group.id)) {
      return;
    }
    group.name = cleaned;
    _commit();
  }

  void deleteGroup(TaskSection section, TaskGroup group) {
    for (final task in tasks) {
      if (task.sectionId == section.id && task.groupId == group.id) {
        task.groupId = '';
      }
    }
    section.groups.remove(group);
    _commit();
  }

  void _ensureTaskIds() {
    var order = 0;
    for (final task in tasks) {
      if (task.id.isEmpty) {
        task.id = createId();
      }
      if (task.sortOrder == 0) {
        task.sortOrder = order++;
      }
    }
  }

  void _repairGroupIds() {
    for (final task in tasks) {
      final section = sectionById(task.sectionId);
      if (section == null || section.groupById(task.groupId) == null) {
        task.groupId = '';
      }
    }
  }

  int _nextSortOrder(String sectionId, String groupId) {
    var highest = -1;
    for (final task in tasks) {
      if (task.sectionId == sectionId && task.groupId == groupId) {
        highest = max(highest, task.sortOrder);
      }
    }
    return highest + 1;
  }

  // ---------------------------------------------------------------------
  // Shop and inventory
  // ---------------------------------------------------------------------

  List<ShopItem> get discoveredShopItems {
    return shopItems.where((item) => item.isDiscovered).toList();
  }

  List<ShopItem> get undiscoveredShopItems {
    return shopItems.where((item) => !item.isDiscovered).toList();
  }

  /// Items the Mod can keep finding as copies, even after the shop lists them.
  List<ShopItem> get repeatableAdventureFinds {
    final skip = shopItemById(ShopItem.skipTokenId);
    return skip == null ? const [] : [skip];
  }

  void _ensureSeededShopItems() {
    final existing = shopItems.map((item) => item.id).toSet();
    if (!existing.contains(ShopItem.skipTokenId)) {
      shopItems.add(skipTokenItem());
    }
  }

  ShopItem? shopItemById(String id) {
    for (final item in shopItems) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  bool shopItemNameAlreadyExists(String name, {String? ignoredItemId}) {
    final cleanedName = name.trim().toLowerCase();

    return shopItems.any(
      (item) =>
          item.id != ignoredItemId &&
          item.name.trim().toLowerCase() == cleanedName,
    );
  }

  ShopItem addShopItem({
    required String name,
    required String description,
    required int cost,
    String iconId = 'reward',
  }) {
    final item = ShopItem(
      id: createId(),
      name: name.trim(),
      description: description.trim(),
      cost: cost,
      iconId: iconId,
      isUserCreated: true,
    );

    shopItems.add(item);
    _commit();
    return item;
  }

  void updateShopItem(
    ShopItem item, {
    required String name,
    required String description,
    required int cost,
    required String iconId,
  }) {
    item.name = name.trim();
    item.description = description.trim();
    item.cost = cost;
    item.iconId = iconId;
    _commit();
  }

  void deleteShopItem(ShopItem item) {
    shopItems.remove(item);
    inventory.removeWhere((id) => id == item.id);
    _commit();
  }

  /// Unlocks an item the Mod turned up on an adventure.
  void discoverShopItem(String itemId) {
    if (_discoverShopItem(itemId)) {
      _commit();
    }
  }

  bool _discoverShopItem(String itemId) {
    final item = shopItemById(itemId);
    if (item == null || item.isDiscovered) {
      return false;
    }

    item.isDiscovered = true;
    _queueMessage('${item.name} was discovered and added to the shop!');
    return true;
  }

  void buyItem(ShopItem item) {
    if (gold < item.cost) {
      return;
    }

    gold -= item.cost;
    inventory.add(item.id);
    _queueMessage('${item.name} was added to inventory!');
    _commit();
  }

  void useInventoryItem(String itemId, {Task? skipTask}) {
    if (itemId == ShopItem.skipTokenId) {
      if (skipTask != null) {
        skipDaily(skipTask);
      }
      return;
    }

    final index = inventory.indexOf(itemId);
    if (index == -1) {
      return;
    }

    inventory.removeAt(index);
    final item = shopItemById(itemId);
    _queueMessage('Used ${item?.name ?? 'item'}.');
    _commit();
  }

  /// Inventory grouped by item ID, with how many of each are held.
  Map<String, int> get inventoryCounts {
    final counts = <String, int>{};
    for (final id in inventory) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  // ---------------------------------------------------------------------
  // Achievements
  // ---------------------------------------------------------------------

  void _checkAchievements({bool save = true}) {
    final requirements = <String, bool>{
      'first_task': totalCompletedTasks >= 1,
      'getting_serious': totalCompletedTasks >= 10,
      'task_master': totalCompletedTasks >= 25,
      'rising_star': lifetimeXp >= 500,
      'hard_worker': totalHardTasksCompleted >= 5,
      'dedicated': completedDays.length >= 7,
    };

    var unlockedSomething = false;

    for (final entry in requirements.entries) {
      if (!entry.value || unlockedAchievements.contains(entry.key)) {
        continue;
      }

      final achievement = achievements.firstWhere(
        (candidate) => candidate.id == entry.key,
      );

      unlockedAchievements.add(entry.key);
      gold += achievement.reward;
      unlockedSomething = true;

      _queueMessage(
        'Achievement Unlocked: ${achievement.title}! '
        '+${achievement.reward} Gold',
      );
    }

    if (unlockedSomething && save) {
      _commit();
    }
  }

  // ---------------------------------------------------------------------
  // Resets
  // ---------------------------------------------------------------------

  void resetAllProgress() {
    tasks.clear();
    sections = defaultSections();
    shopItems = defaultShopItems();
    inventory.clear();
    unlockedAchievements.clear();
    completedDays.clear();

    gold = 0;
    silver = 0;
    lifetimeXp = 0;
    totalCompletedTasks = 0;
    totalHardTasksCompleted = 0;
    lastRolloverAt = DateTime.now();
    adventure = AdventureState();

    _mod?.resetProgress();

    _commit();
  }
}
