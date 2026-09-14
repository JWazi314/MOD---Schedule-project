import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../models/task_section.dart';
import '../models/task_type.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/player_card.dart';
import '../widgets/quest_card.dart';
import '../widgets/task_editor_dialog.dart';
import 'achievements_page.dart';
import 'bank_page.dart';
import 'calendar_page.dart';
import 'inventory_page.dart';
import 'mod_hub_page.dart';
import 'settings_page.dart';
import 'shop_page.dart';

//Home page class (stateful because it tracks which sub page is showing)
class QuestHomePage extends StatefulWidget {
  const QuestHomePage({super.key});

  @override
  State<QuestHomePage> createState() => QuestHomePageState();
}

//Game data lives in GameState. This class only owns navigation and dialogs.
class QuestHomePageState extends State<QuestHomePage> {
  String currentPage = 'quests';
  ModHubTab _modHubTab = ModHubTab.character;
  bool _arranging = false;

  late final GameState _gameState;

  @override
  void initState() {
    super.initState();
    _gameState = context.read<GameState>();
    _gameState.addListener(_drainMessages);
    WidgetsBinding.instance.addPostFrameCallback((_) => _drainMessages());
  }

  @override
  void dispose() {
    _gameState.removeListener(_drainMessages);
    super.dispose();
  }

  // GameState queues player-facing text instead of touching BuildContext, so
  // the messages get shown here once the frame that produced them is done.
  void _drainMessages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final messages = _gameState.takeMessages();
      final messenger = ScaffoldMessenger.maybeOf(context);

      if (messenger == null) {
        return;
      }

      for (final message in messages) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }

  void showPage(String page) {
    setState(() {
      switch (page) {
        case 'adventure':
          currentPage = 'mod';
          _modHubTab = ModHubTab.adventure;
        case 'statistics':
          currentPage = 'mod';
          _modHubTab = ModHubTab.stats;
        case 'mod':
          currentPage = 'mod';
          _modHubTab = ModHubTab.character;
        default:
          currentPage = page;
      }
    });
  }

  // ---------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------

  Future<void> showSectionEditor({TaskSection? section}) async {
    final gameState = context.read<GameState>();
    final isEditing = section != null;

    if (!isEditing && gameState.sections.length >= GameState.maxSections) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can have up to ${GameState.maxSections} sections.',
          ),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    var sectionName = section?.name ?? '';
    var sectionType = section?.type ?? TaskType.daily;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Section' : 'Add Section'),

              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        initialValue: sectionName,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Section Name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'enter a section name';
                          }

                          if (gameState.sectionNameAlreadyExists(
                            value,
                            ignoredSectionId: section?.id,
                          )) {
                            return 'that section already exists';
                          }

                          return null;
                        },
                        onSaved: (value) {
                          sectionName = value!.trim();
                        },
                      ),

                      const SizedBox(height: 20),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'What goes in here',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 10),

                      RadioGroup<TaskType>(
                        groupValue: sectionType,
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              sectionType = value;
                            });
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: TaskType.values.map((type) {
                            return RadioListTile<TaskType>(
                              value: type,
                              contentPadding: EdgeInsets.zero,
                              title: Row(
                                children: [
                                  Icon(type.icon, size: 18),
                                  const SizedBox(width: 8),
                                  Text(type.label),
                                ],
                              ),
                              subtitle: Text(
                                type.description,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    formKey.currentState!.save();

                    if (isEditing) {
                      gameState.updateSection(
                        section,
                        name: sectionName,
                        type: sectionType,
                      );
                    } else {
                      gameState.addSection(sectionName, sectionType);
                    }

                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteSection(TaskSection section) async {
    final gameState = context.read<GameState>();

    if (gameState.sections.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to keep at least one section.')),
      );

      return;
    }

    final sectionTasks = gameState.tasksForSection(section.id);

    final replacementSection = gameState.sections.firstWhere(
      (savedSection) => savedSection.id != section.id,
    );

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete ${section.name}?'),
          content: Text(
            sectionTasks.isEmpty
                ? 'This will remove the empty section.'
                : '${sectionTasks.length} task${sectionTasks.length == 1 ? '' : 's'} '
                      'will be moved to ${replacementSection.name}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    gameState.deleteSection(section);
  }

  Future<void> _showGroupEditor(
    TaskSection section, {
    TaskGroup? group,
  }) async {
    final gameState = context.read<GameState>();
    if (group == null &&
        section.groups.length >= GameState.maxGroupsPerSection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A column can have up to ${GameState.maxGroupsPerSection} groups.',
          ),
        ),
      );
      return;
    }

    var name = group?.name ?? '';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(group == null ? 'Add group' : 'Rename group'),
          content: TextFormField(
            initialValue: name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Group name',
              hintText: 'Home, School…',
            ),
            onChanged: (value) => name = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(group == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );

    if (saved != true || name.trim().isEmpty) {
      return;
    }

    if (group == null) {
      gameState.addGroup(section, name);
    } else {
      gameState.updateGroup(section, group, name: name);
    }
  }

  // ---------------------------------------------------------------------
  // Pages
  // ---------------------------------------------------------------------

  // function allows us to return the bottom part of the page while keeping the original app bar in the scaffold.  Creates a seemless single page system instead of full new loading pages.
  Widget getCurrentPage() {
    if (currentPage == 'shop') {
      return const ShopPage();
    } else if (currentPage == 'inventory') {
      return const InventoryPage();
    } else if (currentPage == 'settings') {
      return const SettingsPage();
    } else if (currentPage == 'achievements') {
      return const AchievementsPage();
    } else if (currentPage == 'bank') {
      return const BankPage();
    } else if (currentPage == 'mod') {
      return ModHubPage(
        initialTab: _modHubTab,
        onTabChanged: (tab) {
          _modHubTab = tab;
        },
      );
    } else if (currentPage == 'calendar') {
      return const CalendarPage();
    } else {
      return buildQuestBoard();
    }
  }

  //the section showing tasks along with the players information
  Widget buildQuestBoard() {
    final gameState = context.watch<GameState>();
    final sections = gameState.sections;

    return Center(
      //Constrained area for the task section columns.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (sections.length * 320.0 + 40).clamp(650.0, 1600.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Controls for creating more task sections.
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Task Sections',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  if (_arranging)
                    TextButton(
                      onPressed: () => setState(() => _arranging = false),
                      child: const Text('Done'),
                    ),

                  IconButton(
                    tooltip: sections.length >= GameState.maxSections
                        ? 'Maximum of ${GameState.maxSections} Sections'
                        : 'Add Section',
                    onPressed: sections.length >= GameState.maxSections
                        ? null
                        : () => showSectionEditor(),
                    icon: const Icon(
                      Icons.add_circle_outline_outlined,
                      size: 28,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const double minimumColumnWidth = 300;
                    const double columnSpacing = 14;

                    final availableColumnWidth =
                        (constraints.maxWidth -
                            (columnSpacing * (sections.length - 1))) /
                        sections.length;

                    final columnWidth =
                        availableColumnWidth < minimumColumnWidth
                        ? minimumColumnWidth
                        : availableColumnWidth;

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: sections.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(width: columnSpacing);
                      },
                      itemBuilder: (context, index) {
                        final TaskSection section = sections[index];

                        return SizedBox(
                          width: columnWidth,
                          child: _SectionColumn(
                            section: section,
                            tasks: gameState.tasksForSection(section.id),
                            gameState: gameState,
                            arranging: _arranging,
                            canDelete: sections.length > 1,
                            onToggleArrange: () {
                              setState(() => _arranging = !_arranging);
                            },
                            onAddTask: () => showTaskEditor(
                              context,
                              gameState: gameState,
                              sectionId: section.id,
                            ),
                            onEditTask: (task) => showTaskEditor(
                              context,
                              gameState: gameState,
                              sectionId: section.id,
                              task: task,
                            ),
                            onEditSection: () =>
                                showSectionEditor(section: section),
                            onDeleteSection: () => deleteSection(section),
                            onAddGroup: () => _showGroupEditor(section),
                            onEditGroup: (group) =>
                                _showGroupEditor(section, group: group),
                          ),
                        );
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
    final gameState = context.watch<GameState>();

    return Scaffold(
      drawerEnableOpenDragGesture: true,
      drawerScrimColor: Colors.black.withValues(alpha: 0.45),

      drawer: Drawer(
        width: 330,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: PlayerCard(
          onOpenModPage: () {
            Navigator.of(context).pop();
            showPage('mod');
          },
          onOpenAdventure: () {
            Navigator.of(context).pop();
            showPage('adventure');
          },
        ),
      ),

      appBar: AppBar(
        toolbarHeight: 50,
        titleSpacing: 0,
        leadingWidth: 60,
        backgroundColor: AppTheme.surfaceDark,

        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: 'Open Player Sidebar',
              color: Colors.amber,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: const Icon(Icons.account_circle, size: 33),
            );
          },
        ),

        // Narrow windows cannot fit the logo, the Shop tab, and every action
        // icon at once, so the title scrolls instead of painting over them.
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: AppTheme.borderRadius,
                      hoverColor: Colors.white.withAlpha(1),
                      splashColor: Colors.white.withAlpha(60),
                      highlightColor: Colors.white.withAlpha(25),
                      onTap: () {
                        showPage('quests');
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
                      showPage('shop');
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
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            tooltip: 'Reset Dailies',
            onPressed: gameState.resetDay,
          ),
          IconButton(
            icon: const Icon(Icons.person_4),
            color: gameState.isModOut ? Colors.amber : Colors.green,
            tooltip: 'Mod',
            onPressed: () {
              showPage('mod');
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            color: Colors.white,
            tooltip: 'Calendar',
            onPressed: () {
              showPage('calendar');
            },
          ),
          IconButton(
            icon: const Icon(Icons.backpack),
            tooltip: 'Inventory',
            color: Colors.white,
            onPressed: () {
              showPage('inventory');
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            color: Colors.amber,
            tooltip: 'Achievements',
            onPressed: () {
              showPage('achievements');
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance),
            color: Colors.white,
            tooltip: 'Bank',
            onPressed: () {
              showPage('bank');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            color: Colors.white,
            tooltip: 'Settings',
            onPressed: () {
              showPage('settings');
            },
          ),
        ],
      ),
      body: getCurrentPage(),
    );
  }
}

/// One column of the board. Which controls its cards show comes from
/// [TaskSection.type].
class _SectionColumn extends StatelessWidget {
  final TaskSection section;
  final List<Task> tasks;
  final GameState gameState;
  final bool arranging;
  final bool canDelete;

  final VoidCallback onToggleArrange;
  final VoidCallback onAddTask;
  final ValueChanged<Task> onEditTask;
  final VoidCallback onEditSection;
  final VoidCallback onDeleteSection;
  final VoidCallback onAddGroup;
  final ValueChanged<TaskGroup> onEditGroup;

  const _SectionColumn({
    required this.section,
    required this.tasks,
    required this.gameState,
    required this.arranging,
    required this.canDelete,
    required this.onToggleArrange,
    required this.onAddTask,
    required this.onEditTask,
    required this.onEditSection,
    required this.onDeleteSection,
    required this.onAddGroup,
    required this.onEditGroup,
  });

  String get _emptyMessage {
    switch (section.type) {
      case TaskType.habit:
        return 'No habits here yet. Add one you want to build or break.';
      case TaskType.daily:
        return 'No dailies here yet. Add something you want to do on a '
            'schedule.';
      case TaskType.todo:
        return 'No to-dos here yet. Add a one-off you need to get done.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(
          color: arranging ? Colors.amber.shade600 : AppTheme.border,
          width: arranging ? 2 : 1.5,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(section.type.icon, color: Colors.amber),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  section.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              IconButton(
                tooltip: 'Add ${section.type.singularLabel}',
                onPressed: onAddTask,
                icon: const Icon(Icons.add_circle_outline_outlined, size: 26),
              ),

              PopupMenuButton<String>(
                tooltip: 'Section Options',
                onSelected: (value) {
                  if (value == 'arrange') {
                    onToggleArrange();
                  } else if (value == 'edit') {
                    onEditSection();
                  } else if (value == 'group') {
                    onAddGroup();
                  } else if (value == 'delete') {
                    onDeleteSection();
                  }
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'arrange',
                      child: Text(
                        arranging ? 'Done arranging' : 'Arrange tasks',
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem<String>(
                      value: 'group',
                      enabled: section.groups.length <
                          GameState.maxGroupsPerSection,
                      child: const Text('Add group'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      enabled: canDelete,
                      child: const Text('Delete'),
                    ),
                  ];
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (!arranging && tasks.isEmpty && section.groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Text(
          _emptyMessage,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
        ),
      );
    }

    final ungrouped = gameState.tasksForSection(section.id, groupId: '');

    return ListView(
      children: [
        if (arranging && section.groups.isNotEmpty)
          _dropHeader(
            label: 'No group',
            groupId: '',
            index: ungrouped.length,
          ),
        ..._taskSlots(ungrouped, ''),
        if (arranging && ungrouped.isNotEmpty) _endLane('', ungrouped.length),
        for (final group in section.groups) ...[
          _dropHeader(
            label: group.name,
            groupId: group.id,
            index: gameState
                .tasksForSection(section.id, groupId: group.id)
                .length,
            group: group,
          ),
          ..._taskSlots(
            gameState.tasksForSection(section.id, groupId: group.id),
            group.id,
          ),
          if (arranging &&
              gameState
                  .tasksForSection(section.id, groupId: group.id)
                  .isEmpty)
            _emptyLane(group.id)
          else if (arranging)
            _endLane(
              group.id,
              gameState.tasksForSection(section.id, groupId: group.id).length,
            ),
        ],
        if (arranging && section.groups.isEmpty && ungrouped.isEmpty)
          _emptyLane(''),
      ],
    );
  }

  List<Widget> _taskSlots(List<Task> slice, String groupId) {
    return [
      for (var i = 0; i < slice.length; i++)
        _DropSlot(
          arranging: arranging,
          onAccept: (task) {
            gameState.placeTask(
              task,
              sectionId: section.id,
              groupId: groupId,
              index: i,
            );
          },
          child: _card(slice[i]),
        ),
    ];
  }

  Widget _dropHeader({
    required String label,
    required String groupId,
    required int index,
    TaskGroup? group,
  }) {
    final header = Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          if (group != null)
            PopupMenuButton<String>(
              tooltip: 'Group options',
              onSelected: (value) {
                if (value == 'rename') {
                  onEditGroup(group);
                } else if (value == 'delete') {
                  gameState.deleteGroup(section, group);
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem<String>(
                    value: 'rename',
                    child: Text('Rename'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ];
              },
            ),
        ],
      ),
    );

    if (!arranging) {
      return header;
    }

    return _DropSlot(
      arranging: true,
      hint: 'Move here',
      onAccept: (task) {
        gameState.placeTask(
          task,
          sectionId: section.id,
          groupId: groupId,
          index: index,
        );
      },
      child: header,
    );
  }

  Widget _endLane(String groupId, int index) {
    return _DropSlot(
      arranging: true,
      hint: 'Move here',
      onAccept: (task) {
        gameState.placeTask(
          task,
          sectionId: section.id,
          groupId: groupId,
          index: index,
        );
      },
      child: const SizedBox(height: 18),
    );
  }

  Widget _emptyLane(String groupId) {
    return _DropSlot(
      arranging: true,
      hint: 'Drop tasks here',
      onAccept: (task) {
        gameState.placeTask(
          task,
          sectionId: section.id,
          groupId: groupId,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Text(
          'Drop tasks here',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
        ),
      ),
    );
  }

  Widget _card(Task task) {
    return QuestCard(
      key: ValueKey(task.id),
      task: task,
      type: section.type,
      canDrag: arranging,
      onComplete: () => gameState.completeTask(task),
      onHabitUp: () => gameState.scoreHabitUp(task),
      onHabitDown: () => gameState.scoreHabitDown(task),
      onTogglePart: (part) => gameState.toggleChecklistItem(task, part),
      onEdit: () => onEditTask(task),
    );
  }
}

class _DropSlot extends StatelessWidget {
  final bool arranging;
  final ValueChanged<Task> onAccept;
  final Widget child;
  final String? hint;

  const _DropSlot({
    required this.arranging,
    required this.onAccept,
    required this.child,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    if (!arranging) {
      return child;
    }

    return DragTarget<Task>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadius,
            border: hovering
                ? Border.all(color: Colors.amber.shade400, width: 1.5)
                : Border.all(color: Colors.transparent),
            color: hovering ? Colors.amber.withValues(alpha: 0.12) : null,
          ),
          child: hint != null && hovering
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        hint!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.amber.shade200,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    child,
                  ],
                )
              : child,
        );
      },
    );
  }
}
