import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/progression.dart';
import '../models/custom_reward.dart';
import '../models/task.dart';
import '../widgets/player_card.dart';
import '../widgets/quest_card.dart';
import '../widgets/task_editor_dialog.dart';
import 'achievements_page.dart';
import 'inventory_page.dart';
import 'settings_page.dart';
import 'shop_page.dart';
import 'statistics_page.dart';

class QuestHomePage extends StatefulWidget {
  const QuestHomePage({super.key});

  @override
  State<QuestHomePage> createState() => QuestHomePageState();
}

class QuestHomePageState extends State<QuestHomePage> {
  int silver = 0;
  int gold = 0;
  int xp = 0;
  int totalCompletedTasks = 0;
  int totalHardTasksCompleted = 0;
  int bestStreak = 0;
  int rewardsBought = 0;
  String playerName = 'User';
  String currentPage = 'quests';
  String boardFilter = 'today';

  List<Task> tasks = [];
  List<String> inventory = [];
  List<CustomReward> customRewards = [];
  Set<String> unlockedAchievements = {};
  Set<String> completedDays = {};

  static const _pages = ['quests', 'shop', 'inventory', 'statistics', 'achievements'];

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  int get activeStreak {
    var highest = 0;
    for (final task in tasks) {
      if (task.streak > highest) {
        highest = task.streak;
      }
    }
    return highest;
  }

  ProgressRecord get _record {
    return ProgressRecord(
      totalCompletedTasks: totalCompletedTasks,
      totalHardTasksCompleted: totalHardTasksCompleted,
      xp: xp,
      completedDays: completedDays.length,
      bestStreak: bestStreak,
      rewardsBought: rewardsBought,
    );
  }

  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('gold', gold);
    await prefs.setInt('silver', silver);
    await prefs.setInt('xp', xp);
    await prefs.setString(
      'tasks',
      jsonEncode(tasks.map((task) => task.toJson()).toList()),
    );
    await prefs.setStringList('inventory', inventory);
    await prefs.setStringList('achievements', unlockedAchievements.toList());
    await prefs.setInt('totalCompletedTasks', totalCompletedTasks);
    await prefs.setInt('totalHardTasksCompleted', totalHardTasksCompleted);
    await prefs.setStringList('completedDays', completedDays.toList());
    await prefs.setInt('bestStreak', bestStreak);
    await prefs.setInt('rewardsBought', rewardsBought);
    await prefs.setString('playerName', playerName);
    await prefs.setString(
      'customRewards',
      jsonEncode(customRewards.map((reward) => reward.toJson()).toList()),
    );
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTasks = prefs.getString('tasks');
    final loadedTasks = <Task>[];

    if (savedTasks != null) {
      try {
        final decodedTasks = jsonDecode(savedTasks) as List<dynamic>;
        loadedTasks.addAll(
          decodedTasks
              .whereType<Map>()
              .map((item) => Task.fromJson(Map<String, dynamic>.from(item))),
        );
      } catch (error) {
        debugPrint('Failed to load saved tasks: $error');
      }
    }

    final loadedRewards = <CustomReward>[];
    final savedRewards = prefs.getString('customRewards');
    if (savedRewards != null) {
      try {
        final decoded = jsonDecode(savedRewards) as List<dynamic>;
        loadedRewards.addAll(
          decoded
              .whereType<Map>()
              .map((item) => CustomReward.fromJson(Map<String, dynamic>.from(item)))
              .where((reward) => reward.title.isNotEmpty),
        );
      } catch (error) {
        debugPrint('Failed to load custom rewards: $error');
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      gold = prefs.getInt('gold') ?? 0;
      silver = prefs.getInt('silver') ?? 0;
      xp = prefs.getInt('xp') ?? 0;
      tasks = loadedTasks;
      inventory = prefs.getStringList('inventory') ?? [];
      unlockedAchievements = (prefs.getStringList('achievements') ?? []).toSet();
      totalCompletedTasks = prefs.getInt('totalCompletedTasks') ?? 0;
      totalHardTasksCompleted = prefs.getInt('totalHardTasksCompleted') ?? 0;
      completedDays = (prefs.getStringList('completedDays') ?? []).toSet();
      bestStreak = prefs.getInt('bestStreak') ?? 0;
      rewardsBought = prefs.getInt('rewardsBought') ?? 0;
      playerName = prefs.getString('playerName') ?? 'User';
      if (playerName.trim().isEmpty) {
        playerName = 'User';
      }
      customRewards = loadedRewards;
    });
    checkAchievements();
  }

  void completeTask(Task task) {
    if (task.isDone) {
      return;
    }

    var bonus = 0;
    setState(() {
      final granted = collectQuestReward(task);
      bonus = granted - task.gold;
      gold += granted;
      silver += task.silver;
      xp += task.xp;
      totalCompletedTasks++;
      if (task.difficulty == 2) {
        totalHardTasksCompleted++;
      }
      if (task.streak > bestStreak) {
        bestStreak = task.streak;
      }
      final date = task.completedAt!;
      completedDays.add('${date.year}-${date.month}-${date.day}');
    });

    if (bonus > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${task.streak}-day streak. +$bonus gold.')),
      );
    }

    checkAchievements();
    saveProgress();
  }

  void removeTask(Task task) {
    setState(() {
      tasks.remove(task);
    });
    saveProgress();
  }

  Future<void> addTask() async {
    final result = await showTaskEditor(context);
    if (result?.task == null) {
      return;
    }
    setState(() {
      tasks.add(result!.task!);
    });
    saveProgress();
  }

  Future<void> editTask(Task oldTask) async {
    final result = await showTaskEditor(context, existing: oldTask);
    if (result == null) {
      return;
    }
    if (result.deleted) {
      removeTask(oldTask);
      return;
    }
    final updated = result.task;
    if (updated == null) {
      return;
    }
    setState(() {
      final index = tasks.indexOf(oldTask);
      if (index != -1) {
        tasks[index] = updated;
      }
    });
    saveProgress();
  }

  void checkAchievements() {
    final record = _record;
    var unlockedSomething = false;

    for (final achievement in achievements) {
      if (unlockedAchievements.contains(achievement.id)) {
        continue;
      }
      if (!isAchievementEarned(achievement.id, record)) {
        continue;
      }

      setState(() {
        unlockedAchievements.add(achievement.id);
        gold += achievement.reward;
      });
      unlockedSomething = true;

      if (!mounted) {
        continue;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Achievement unlocked: ${achievement.title}. +${achievement.reward} gold.',
          ),
        ),
      );
    }

    if (unlockedSomething) {
      saveProgress();
    }
  }

  int resetDay() {
    var broken = 0;
    setState(() {
      broken = rollOverDay(tasks);
    });
    saveProgress();
    return broken;
  }

  void resetAllProgress() {
    setState(() {
      tasks.clear();
      inventory.clear();
      customRewards.clear();
      unlockedAchievements.clear();
      completedDays.clear();
      gold = 0;
      silver = 0;
      xp = 0;
      totalCompletedTasks = 0;
      totalHardTasksCompleted = 0;
      bestStreak = 0;
      rewardsBought = 0;
      currentPage = 'quests';
    });
    saveProgress();
  }

  void renamePlayer(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() => playerName = trimmed);
    saveProgress();
  }

  void addCustomReward(CustomReward reward) {
    setState(() => customRewards.add(reward));
    saveProgress();
  }

  void deleteCustomReward(CustomReward reward) {
    setState(() => customRewards.remove(reward));
    saveProgress();
  }

  void buyItem(int cost, String title) {
    if (gold < cost) {
      return;
    }

    setState(() {
      gold -= cost;
      inventory.add(title);
      rewardsBought++;
    });
    saveProgress();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title was added to inventory.')),
      );
    }
    checkAchievements();
  }

  void useInventoryItem(String title) {
    final itemIndex = inventory.indexOf(title);
    if (itemIndex == -1) {
      return;
    }

    setState(() {
      inventory.removeAt(itemIndex);
    });
    saveProgress();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Used $title.')),
      );
    }
  }

  List<Task> get _visibleTasks {
    final visible = tasks.where((task) {
      if (boardFilter == 'all') {
        return true;
      }
      return task.showsOnTodayBoard();
    }).toList();

    visible.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      return b.difficulty.compareTo(a.difficulty);
    });
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final navIndex = _pages.indexOf(currentPage);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFC4A35A)),
            SizedBox(width: 8),
            Text('MOD'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFFC4A35A), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$gold',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => setState(() => currentPage = 'settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      floatingActionButton: currentPage == 'quests'
          ? FloatingActionButton.extended(
              onPressed: addTask,
              icon: const Icon(Icons.add),
              label: const Text('Quest'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navIndex < 0 ? 0 : navIndex,
        onDestinationSelected: (index) {
          setState(() => currentPage = _pages[index]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Quests'),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.backpack), label: 'Bag'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Awards'),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    switch (currentPage) {
      case 'shop':
        return ShopPage(
          gold: gold,
          customRewards: customRewards,
          onBuy: buyItem,
          onCreate: addCustomReward,
          onDelete: deleteCustomReward,
        );
      case 'inventory':
        return InventoryPage(inventory: inventory, onUse: useInventoryItem);
      case 'statistics':
        return StatisticsPage(
          tasks: tasks,
          gold: gold,
          silver: silver,
          xp: xp,
          totalCompleted: totalCompletedTasks,
          bestStreak: bestStreak,
          rewardsBought: rewardsBought,
        );
      case 'settings':
        return SettingsPage(
          playerName: playerName,
          onRename: renamePlayer,
          onResetDay: resetDay,
          onResetAll: resetAllProgress,
        );
      case 'achievements':
        return AchievementsPage(unlockedAchievements: unlockedAchievements);
      default:
        return _questBoard();
    }
  }

  Widget _questBoard() {
    final visible = _visibleTasks;
    final dueCount = tasks.where((task) => task.showsOnTodayBoard() && !task.isDone).length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            PlayerCard(
              name: playerName,
              gold: gold,
              silver: silver,
              xp: xp,
              streak: activeStreak,
            ),
            const SizedBox(height: 16),
            Text(
              dueCount == 1 ? '1 quest left today' : '$dueCount quests left today',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'today', label: Text('Today')),
                  ButtonSegment(value: 'all', label: Text('All')),
                ],
                selected: {boardFilter},
                onSelectionChanged: (selection) {
                  setState(() => boardFilter = selection.first);
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Repeating quests build a streak. Every 3rd day pays 2 extra gold.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              const _EmptyQuests()
            else
              for (final task in visible)
                QuestCard(
                  task: task,
                  isDone: task.isDone,
                  scheduledToday: task.showsOnTodayBoard(),
                  onComplete: () => completeTask(task),
                  onEdit: () => editTask(task),
                ),
          ],
        ),
      ),
    );
  }
}

class _EmptyQuests extends StatelessWidget {
  const _EmptyQuests();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.checklist, size: 40, color: Color(0xFF2F6B4F)),
          SizedBox(height: 10),
          Text(
            'Nothing due right now.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text('Add a quest and check it off to earn gold.'),
        ],
      ),
    );
  }
}
