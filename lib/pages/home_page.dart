import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/player_card.dart';
import '../widgets/quest_card.dart';
import 'inventory_page.dart';
import 'shop_page.dart';
import '../models/task.dart';
import 'settings_page.dart';
import 'statistics_page.dart';
import 'achievements_page.dart';

//Home page class (stateful due to changing variables while app runs)
class QuestHomePage extends StatefulWidget {
  // this function is the constructor for the page itself
  const QuestHomePage({super.key});

  //overrides needed setstate, and now points at the QuestHomePageState class for the data.
  @override
  State<QuestHomePage> createState() => QuestHomePageState();
}

//the state of the page itself is here, this is where variables are held and changed, the homepage class itself displays the changed data.
class QuestHomePageState extends State<QuestHomePage> {
  int silver = 0;
  int gold = 0;
  int xp = 0;
  int totalCompletedTasks = 0;
  int totalHardTasksCompleted = 0;

  String currentPage = 'quests';

  List<Task> tasks = [];
  List<String> inventory = [];
  Set<String> unlockedAchievements = {};
  Set<String> completedDays = {};

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final taskData = tasks.map((task) => task.toJson()).toList();

    await prefs.setInt('gold', gold);
    await prefs.setInt('silver', silver);
    await prefs.setInt('xp', xp);
    await prefs.setString('tasks', jsonEncode(taskData));
    await prefs.setStringList('inventory', inventory);
    await prefs.setStringList(
      'achievements',
      unlockedAchievements.toList(),
    );
    await prefs.setInt('totalCompletedTasks', totalCompletedTasks);
    await prefs.setInt('totalHardTasksCompleted', totalHardTasksCompleted);
    await prefs.setStringList(
      'completedDays',
      completedDays.toList(),
    );
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTasks = prefs.getString('tasks');
    List<Task> loadedTasks = [];

    if (savedTasks != null) {
      try {
        final decodedTasks = jsonDecode(savedTasks) as List<dynamic>;
        loadedTasks = decodedTasks
            .whereType<Map>()
            .map((item) => Task.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } catch (error) {
        debugPrint('Failed to load saved tasks: $error');
      }
    }

    if (!mounted) {
      return;
    }

    final savedAchievements =
      prefs.getStringList('achievements') ?? [];

    final savedCompletedDays =
      prefs.getStringList('completedDays') ?? [];

    setState(() {
      gold = prefs.getInt('gold') ?? 0;
      silver = prefs.getInt('silver') ?? 0;
      xp = prefs.getInt('xp') ?? 0;
      tasks = loadedTasks;
      inventory = prefs.getStringList('inventory') ?? [];
      
      unlockedAchievements = savedAchievements.toSet();

      totalCompletedTasks =
          prefs.getInt('totalCompletedTasks') ?? 0;
      totalHardTasksCompleted =
          prefs.getInt('totalHardTasksCompleted') ?? 0;

      completedDays = savedCompletedDays.toSet();

    });
    checkAchievements();
  }

  void completeTask(Task task) {
    if (task.isDone) {
      return;
    }

    setState(() {
      task.isDone = true;
      task.completedAt = DateTime.now();

      gold += task.gold;
      silver += task.silver;
      xp += task.xp;

      totalCompletedTasks++;
      if (task.difficulty == 2) {
        totalHardTasksCompleted++;
      }

      final date = task.completedAt!;
      completedDays.add('${date.year}-${date.month}-${date.day}');
    });

    checkAchievements();
    saveProgress();
  }

  void removeTask(Task task) {
    setState(() {
      tasks.remove(task);
    });
    saveProgress();
  }

  void editTask(Task oldTask) {
    //Step 1: For a form I'll use a key, it acts as the remote control
    final formKey = GlobalKey<FormState>();

    //Step 2: constructor for all passed info
    String taskTitle = oldTask.title;
    String taskSection = oldTask.section;
    int selectDifficulty = oldTask.difficulty;
    List<int> selectedRepeatDays = List<int>.from(oldTask.repeatDays);

    final List<String> dayLabels = ['M', 'T', 'W', 'Th', 'F', 'St', 'Sn'];

    int baseGold = oldTask.gold;
    int baseSilver = oldTask.silver;
    int baseXP = oldTask.xp;

    //Step 3: use showdialog global function to make a popup in the middle over the current scaffold
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          //the two lines under this are needed to make the builder stateful (has changing information inside of it since we are actively changing task information)
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Task',
              ), // 3 parts to this alert dialog a title, the content (the actual form), then the final actions like a add task or cancel button.
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    TextFormField(
                      initialValue: oldTask.title,
                      decoration: const InputDecoration(labelText: 'Task Name'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'enter a task name';
                        }
                        return null;
                      },

                      onSaved: (value) {
                        taskTitle = value!.trim();
                      },
                    ),

                    const SizedBox(height: 20),

                    const Align(
                      alignment: Alignment.centerLeft,

                      child: Text('Difficulty', style: TextStyle(fontSize: 16)),
                    ),

                    const SizedBox(height: 10),

                    // Buttons for selectedDifficulty
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectDifficulty == 0
                                ? Colors.green
                                : null,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              selectDifficulty = 0;
                              baseGold = 5;
                              baseSilver = 2;
                              baseXP = 25;
                            });
                          },
                          child: const Text('Easy'),
                        ),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectDifficulty == 1
                                ? Colors.orange
                                : null,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              selectDifficulty = 1;
                              baseGold = 10;
                              baseSilver = 5;
                              baseXP = 50;
                            });
                          },
                          child: const Text('Medium'),
                        ),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectDifficulty == 2
                                ? Colors.red
                                : null,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              selectDifficulty = 2;
                              baseGold = 15;
                              baseSilver = 7;
                              baseXP = 75;
                            });
                          },
                          child: const Text('Hard'),
                        ),
                      ],
                    ),
                    //End-- SelectedDifficulty
                    const SizedBox(height: 10),

                    const Align(
                      alignment: Alignment.centerLeft,

                      child: Text(
                        'Days Repeated',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(7, (index) {
                        final bool isSelected = selectedRepeatDays.contains(
                          index,
                        );

                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? Colors.green
                                : Colors.grey.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),

                          onPressed: () {
                            setDialogState(() {
                              if (selectedRepeatDays.contains(index)) {
                                selectedRepeatDays.remove(index);
                              } else {
                                selectedRepeatDays.add(index);
                              }
                            });
                          },
                          child: Text(dayLabels[index]),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),

                TextButton(
                  onPressed: () {
                    removeTask(oldTask);
                    Navigator.of(context).pop();
                  },
                  child: const Text("Delete"),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      final updatedTask = Task(
                        title: taskTitle,
                        difficulty: selectDifficulty,
                        repeatDays: selectedRepeatDays,
                        gold: baseGold,
                        silver: baseSilver,
                        xp: baseXP,
                        section: taskSection,
                        isDone: oldTask.isDone,
                        completedAt: oldTask.completedAt,
                      );

                      setState(() {
                        final int index = tasks.indexOf(oldTask);
                        tasks[index] = updatedTask;
                      });
                      saveProgress();

                      Navigator.of(context).pop();
                    }
                  },

                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // UNFINSIHED Function for adding a task.
  void addTask() {
    //Step 1: For a form I'll use a key, it acts as the remote control
    final formKey = GlobalKey<FormState>();

    //Step 2: constructor for all passed info
    String taskTitle = '';
    String taskSection = 'General';
    int selectDifficulty = 0;
    List<int> selectedRepeatDays = [];
    final List<String> dayLabels = ['M', 'T', 'W', 'Th', 'F', 'St', 'Sn'];

    int baseGold = 5;
    int baseSilver = 2;
    int baseXP = 25;

    //Step 3: use showdialog global function to make a popup in the middle over the current scaffold
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          //the two lines under this are needed to make the builder stateful (has changing information inside of it since we are actively changing task information)
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add Task',
              ), // 3 parts to this alert dialog a title, the content (the actual form), then the final actions like a add task or cancel button.
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Task Name'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'enter a task name';
                        }
                        return null;
                      },

                      onSaved: (value) {
                        taskTitle = value!.trim();
                      },
                    ),

                    const SizedBox(height: 20),

                    const Align(
                      alignment: Alignment.centerLeft,

                      child: Text('Difficulty', style: TextStyle(fontSize: 16)),
                    ),

                    const SizedBox(height: 10),

                    // Buttons for selectedDifficulty
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectDifficulty == 0
                                ? Colors.green
                                : null,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              selectDifficulty = 0;
                              baseGold = 5;
                              baseSilver = 2;
                              baseXP = 25;
                            });
                          },
                          child: const Text('Easy'),
                        ),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectDifficulty == 1
                                ? Colors.orange
                                : null,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              selectDifficulty = 1;
                              baseGold = 10;
                              baseSilver = 5;
                              baseXP = 50;
                            });
                          },
                          child: const Text('Medium'),
                        ),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectDifficulty == 2
                                ? Colors.red
                                : null,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              selectDifficulty = 2;
                              baseGold = 15;
                              baseSilver = 7;
                              baseXP = 75;
                            });
                          },
                          child: const Text('Hard'),
                        ),
                      ],
                    ),
                    //End-- SelectedDifficulty
                    const SizedBox(height: 10),

                    const Align(
                      alignment: Alignment.centerLeft,

                      child: Text(
                        'Days Repeated',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(7, (index) {
                        final bool isSelected = selectedRepeatDays.contains(
                          index,
                        );

                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? Colors.green
                                : Colors.grey.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),

                          onPressed: () {
                            setDialogState(() {
                              if (selectedRepeatDays.contains(index)) {
                                selectedRepeatDays.remove(index);
                              } else {
                                selectedRepeatDays.add(index);
                              }
                            });
                          },
                          child: Text(dayLabels[index]),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      final newTask = Task(
                        title: taskTitle,
                        difficulty: selectDifficulty,
                        repeatDays: selectedRepeatDays,
                        gold: baseGold,
                        silver: baseSilver,
                        xp: baseXP,
                        section: taskSection,
                      );

                      setState(() {
                        tasks.add(newTask);
                      });
                      saveProgress();
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  void checkAchievements() {
    final Map<String, bool> requirements = {
      'first_task': totalCompletedTasks >= 1,
      'getting_serious': totalCompletedTasks >= 10,
      'task_master': totalCompletedTasks >= 25,
      'rising_star': xp >= 500,
      'hard_worker': totalHardTasksCompleted >= 5,
      'dedicated': completedDays.length >= 7,
    };

    bool unlockedSomething = false;

    for (final entry in requirements.entries) {
      if (entry.value && !unlockedAchievements.contains(entry.key)) {
        final achievement = achievements.firstWhere(
          (achievement) => achievement.id == entry.key,
        );

        setState(() {
          unlockedAchievements.add(entry.key);
          gold += achievement.reward;
        });

        unlockedSomething = true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Achievement Unlocked: ${achievement.title}! '
              '+${achievement.reward} Gold',
            ),
          ),
        );
      }
    }

    if (unlockedSomething) {
      saveProgress();
    }
  }

  //test function to reset day and check variable counts
  void resetDay() {
    int taskamount = tasks.length;
    setState(() {
      for (int i = 0; i < taskamount; i++) {
        tasks[i].isDone = false;
        tasks[i].completedAt = null;
      }
    });
    saveProgress();
  }

  void resetAllProgress() {
    setState(() {
      tasks.clear();
      inventory.clear();
      unlockedAchievements.clear();
      completedDays.clear();
      gold = 0;
      silver = 0;
      xp = 0;
      totalCompletedTasks = 0;
      totalHardTasksCompleted = 0;
      currentPage = 'quests';
    });
    saveProgress();
  }

  void buyItem(int cost, String title) {
    if (gold < cost) {
      return;
    }

    setState(() {
      gold -= cost;
      inventory.add(title);
    });
    saveProgress();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title was added to inventory!')));
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Used $title.')));
  }

  // function allows us to return the bottom part of the page while keeping the original app bar in the scaffold.  Creates a seemless single page system instead of full new loading pages.
  Widget getCurrentPage() {
    if (currentPage == 'shop') {
      return ShopPage(silver: silver, gold: gold, onBuy: buyItem);
    } else if (currentPage == 'inventory') {
      return InventoryPage(inventory: inventory, onUse: useInventoryItem);
    } else if (currentPage == 'statistics') {
      return StatisticsPage(tasks: tasks, gold: gold, silver: silver, xp: xp);
    } else if (currentPage == 'settings') {
      return SettingsPage(onResetDay: resetDay, onResetAll: resetAllProgress);
    } else if (currentPage == 'achievements') {
      return AchievementsPage(
        unlockedAchievements: unlockedAchievements,
      );
    }
    
    else {
      return buildQuestBoard();
    }
  }

  //the section showing tasks along with the players information
  Widget buildQuestBoard() {
    return Center(
      //constrained box with player information (Player card)
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlayerCard(gold: gold, silver: silver, xp: xp),

              const SizedBox(height: 24),

              // A row that makes outputs the 'maintask text' along with the add task option.
              Row(
                children: [
                  Icon(Icons.star, color: Colors.yellow),
                  SizedBox(width: 8),
                  Text(
                    'Main Tasks',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      addTask();
                    },
                    icon: const Icon(
                      Icons.add_circle_outline_outlined,
                      size: 28,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Task task = tasks[index];

                    return QuestCard(
                      task: task,
                      isDone: task.isDone,

                      onComplete: () {
                        completeTask(task);
                      },

                      onEdit: () {
                        editTask(task);
                      },

                      onDelete: () {
                        removeTask(task);
                      },
                    );
                  },
                ),
              ),

              //test card just for practice
              Card(
                color: const Color.fromARGB(255, 192, 191, 194),

                child: Padding(
                  padding: const EdgeInsets.all(14),

                  child: Text(
                    'UNDER DEVELOPMENT',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //use over ride again and finally make the scaffold for the whole page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        titleSpacing: 0,
        leadingWidth: 60,
        backgroundColor: const Color.fromARGB(255, 49, 44, 44),
        title: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    hoverColor: Colors.white.withAlpha(1),
                    splashColor: Colors.white.withAlpha(60),
                    highlightColor: Colors.white.withAlpha(25),
                    onTap: () {
                      setState(() {
                        currentPage = 'quests';
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Image.asset(
                        'media/modLogo.png',
                        height: 38,
                        width: 100,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(height: 38, width: 100);
                        },
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, 4),
                  child: Container(
                    height: 3,
                    width: 100,
                    color: currentPage == 'quests'
                        ? Colors.white
                        : Colors.white.withAlpha(45),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 5),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    overlayColor: Colors.white.withAlpha(35),
                  ),
                  icon: const Icon(Icons.store, size: 30),
                  label: const Text('Shop', style: TextStyle(fontSize: 25)),
                  onPressed: () {
                    setState(() {
                      currentPage = 'shop';
                    });
                  },
                ),
                Transform.translate(
                  offset: const Offset(0, 5),
                  child: Container(
                    height: 3,
                    width: 100,
                    color: currentPage == 'shop' ? Colors.white : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            tooltip: 'Reset Day',
            onPressed: resetDay,
          ),
          IconButton(
            icon: const Icon(Icons.backpack),
            tooltip: 'Inventory',
            color: Colors.white,
            onPressed: () {
              setState(() {
                currentPage = 'inventory';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            color: Colors.white,
            tooltip: 'Statistics',
            onPressed: () {
              setState(() {
                currentPage = 'statistics';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            color: Colors.amber,
            tooltip: 'Achievements',
            onPressed: () {
              setState(() {
                currentPage = 'achievements';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            color: Colors.white,
            tooltip: 'Settings',
            onPressed: () {
              setState(() {
                currentPage = 'settings';
              });
            },
          ),
        ],
      ),
      body: getCurrentPage(),
    );
  }
}
