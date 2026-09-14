import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/calendar.dart';
import '../game/task_value.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/payout_burst.dart';

/// A month of scheduled work, with filters for each task type.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _month;
  late DateTime _selected;
  final Set<TaskType> _visible = {TaskType.todo, TaskType.daily};

  @override
  void initState() {
    super.initState();
    final now = Calendar.dateOnly(DateTime.now());
    _month = DateTime(now.year, now.month);
    _selected = now;
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      final days = Calendar.daysInMonth(_month);
      if (_selected.month != _month.month || _selected.year != _month.year) {
        _selected = DateTime(_month.year, _month.month, 1);
      } else if (_selected.day > days) {
        _selected = DateTime(_month.year, _month.month, days);
      }
    });
  }

  void _toggle(TaskType type) {
    setState(() {
      if (_visible.contains(type)) {
        if (_visible.length == 1) {
          return;
        }
        _visible.remove(type);
      } else {
        _visible.add(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final today = Calendar.dateOnly(DateTime.now());

    TaskType typeOf(Task task) => gameState.taskTypeFor(task);

    final dayItems = [
      ...Calendar.datedItemsOn(
        tasks: gameState.tasks,
        typeOf: typeOf,
        day: _selected,
        visible: _visible,
      ),
      ...Calendar.habits(
        tasks: gameState.tasks,
        typeOf: typeOf,
        visible: _visible,
      ),
    ];

    final undated = Calendar.undatedTodos(
      tasks: gameState.tasks,
      typeOf: typeOf,
      visible: _visible,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      Calendar.monthTitle(_month),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed: () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  IconButton(
                    tooltip: 'Jump to today',
                    onPressed: () {
                      setState(() {
                        _month = DateTime(today.year, today.month);
                        _selected = today;
                      });
                    },
                    icon: const Icon(Icons.today),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in Calendar.scheduleOrder)
                    FilterChip(
                      label: Text(type.label),
                      avatar: Icon(type.icon, size: 16),
                      selected: _visible.contains(type),
                      onSelected: (_) => _toggle(type),
                      selectedColor: _typeColor(type).withAlpha(50),
                      checkmarkColor: _typeColor(type),
                      side: BorderSide(
                        color: _visible.contains(type)
                            ? _typeColor(type)
                            : AppTheme.border,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _WeekdayHeader(),
                    const SizedBox(height: 6),
                    Expanded(
                      child: _MonthGrid(
                        month: _month,
                        selected: _selected,
                        today: today,
                        tasks: gameState.tasks,
                        typeOf: typeOf,
                        visible: _visible,
                        onSelect: (day) {
                          setState(() {
                            _selected = day;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                _dayHeading(_selected, today),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                flex: 2,
                child: ListView(
                  children: [
                    if (dayItems.isEmpty && undated.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Nothing scheduled for this day.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    for (final type in Calendar.scheduleOrder) ...[
                      ..._typedRows(
                        items: dayItems
                            .where((item) => item.type == type)
                            .toList(),
                        type: type,
                        day: _selected,
                        today: today,
                        gameState: gameState,
                      ),
                    ],
                    if (undated.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'To-Dos with no due date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final item in undated)
                        _DayTaskRow(
                          item: item,
                          day: _selected,
                          today: today,
                          gameState: gameState,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<Widget> _typedRows({
    required List<CalendarItem> items,
    required TaskType type,
    required DateTime day,
    required DateTime today,
    required GameState gameState,
  }) {
    if (items.isEmpty) {
      return const [];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 6),
        child: Text(
          type.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _typeColor(type),
          ),
        ),
      ),
      for (final item in items)
        _DayTaskRow(
          item: item,
          day: day,
          today: today,
          gameState: gameState,
        ),
    ];
  }

  static String _dayHeading(DateTime day, DateTime today) {
    final stamp = '${day.year}-${day.month}-${day.day}';
    if (Calendar.sameDay(day, today)) {
      return 'Today, $stamp';
    }
    return stamp;
  }
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in Calendar.weekdayLabels)
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final DateTime today;
  final List<Task> tasks;
  final TaskType Function(Task) typeOf;
  final Set<TaskType> visible;
  final ValueChanged<DateTime> onSelect;

  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.today,
    required this.tasks,
    required this.typeOf,
    required this.visible,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final blanks = Calendar.leadingBlanks(month);
    final days = Calendar.daysInMonth(month);
    final cells = blanks + days;
    final rows = (cells / 7).ceil();

    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: row < rows - 1 ? 4 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(child: _cell(row * 7 + col, blanks, days)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _cell(int index, int blanks, int days) {
    final dayNumber = index - blanks + 1;
    if (dayNumber < 1 || dayNumber > days) {
      return const SizedBox.expand();
    }

    final day = DateTime(month.year, month.month, dayNumber);
    final items = Calendar.datedItemsOn(
      tasks: tasks,
      typeOf: typeOf,
      day: day,
      visible: visible,
    );

    final isSelected = Calendar.sameDay(day, selected);
    final isToday = Calendar.sameDay(day, today);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: isSelected ? AppTheme.surface : AppTheme.surfaceDark,
        borderRadius: AppTheme.borderRadius,
        child: InkWell(
          borderRadius: AppTheme.borderRadius,
          onTap: () => onSelect(day),
          child: SizedBox.expand(
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
              decoration: BoxDecoration(
                borderRadius: AppTheme.borderRadius,
                border: Border.all(
                  color: isSelected
                      ? Colors.amber
                      : isToday
                      ? AppTheme.accentBlue
                      : AppTheme.border,
                  width: isSelected || isToday ? 1.8 : 1,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _DayCellBody(
                    dayNumber: dayNumber,
                    isToday: isToday,
                    boxes: _cellBoxes(
                      items: items,
                      day: day,
                      today: today,
                    ),
                    maxHeight: constraints.maxHeight,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CellBox {
  final String label;
  final TaskType type;
  final bool done;
  final bool overflow;

  const _CellBox({
    required this.label,
    required this.type,
    this.done = false,
    this.overflow = false,
  });
}

List<_CellBox> _cellBoxes({
  required List<CalendarItem> items,
  required DateTime day,
  required DateTime today,
}) {
  return [
    for (final type in [TaskType.todo, TaskType.daily])
      for (final item in items.where((item) => item.type == type))
        _CellBox(
          label: item.task.title,
          type: type,
          done: Calendar.showsAsDone(item, day, today),
        ),
  ];
}

class _DayCellBody extends StatelessWidget {
  static const double _dayNumberHeight = 16;
  static const double _chipHeight = 16;
  static const double _chipGap = 2;

  final int dayNumber;
  final bool isToday;
  final List<_CellBox> boxes;
  final double maxHeight;

  const _DayCellBody({
    required this.dayNumber,
    required this.isToday,
    required this.boxes,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final room = maxHeight - _dayNumberHeight - _chipGap;
    final maxChips = room < _chipHeight ? 0 : (room / (_chipHeight + _chipGap)).floor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _dayNumberHeight,
          child: Text(
            '$dayNumber',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              height: 1.0,
              color: isToday ? AppTheme.accentBlue : Colors.white,
            ),
          ),
        ),
        if (boxes.isEmpty)
          const SizedBox.shrink()
        else if (maxChips <= 0 && room >= 10)
          _TypeDots(boxes: boxes)
        else if (maxChips > 0) ...[
          const SizedBox(height: _chipGap),
          for (final box in _visibleBoxes(maxChips))
            Padding(
              padding: const EdgeInsets.only(bottom: _chipGap),
              child: _TaskChip(box: box),
            ),
        ],
      ],
    );
  }

  List<_CellBox> _visibleBoxes(int maxChips) {
    if (boxes.length <= maxChips) {
      return boxes;
    }

    final hidden = boxes.length - (maxChips - 1);
    return [
      ...boxes.take(maxChips - 1),
      _CellBox(
        label: '+$hidden',
        type: boxes[maxChips - 1].type,
        overflow: true,
      ),
    ];
  }
}

class _TaskChip extends StatelessWidget {
  final _CellBox box;

  const _TaskChip({required this.box});

  @override
  Widget build(BuildContext context) {
    final color = box.overflow ? Colors.white54 : _typeColor(box.type);

    return Tooltip(
      message: box.label,
      waitDuration: const Duration(milliseconds: 400),
      child: SizedBox(
        height: _DayCellBody._chipHeight,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withAlpha(box.done || box.overflow ? 28 : 70),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: color.withAlpha(box.done || box.overflow ? 90 : 200),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                box.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.1,
                  color: box.done ? Colors.white38 : Colors.white,
                  decoration: box.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeDots extends StatelessWidget {
  final List<_CellBox> boxes;

  const _TypeDots({required this.boxes});

  @override
  Widget build(BuildContext context) {
    final counts = <TaskType, int>{};
    for (final box in boxes) {
      counts[box.type] = (counts[box.type] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          for (final type in Calendar.scheduleOrder)
            if ((counts[type] ?? 0) > 0) ...[
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: _typeColor(type).withAlpha(180),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                '${counts[type]}',
                style: TextStyle(
                  fontSize: 9,
                  height: 1.0,
                  color: _typeColor(type),
                ),
              ),
              const SizedBox(width: 4),
            ],
        ],
      ),
    );
  }
}

class _DayTaskRow extends StatelessWidget {
  final CalendarItem item;
  final DateTime day;
  final DateTime today;
  final GameState gameState;

  const _DayTaskRow({
    required this.item,
    required this.day,
    required this.today,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    final done = Calendar.showsAsDone(item, day, today);
    final canAct = item.type == TaskType.habit ||
        item.type == TaskType.todo ||
        Calendar.sameDay(day, today);
    final payout = identical(gameState.latestPayout?.task, item.task)
        ? gameState.latestPayout
        : null;
    final splitHabit = item.type == TaskType.habit &&
        item.task.isPositive &&
        item.task.isNegative;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: _typeColor(item.type).withAlpha(160)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.type == TaskType.habit && item.task.isNegative)
                IconButton(
                  tooltip: 'I slipped up',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () => gameState.scoreHabitDown(item.task),
                  icon: const Icon(
                    Icons.remove,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
              Expanded(
                child: Text(
                  item.task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: splitHabit ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? Colors.white54 : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                TaskValue.difficultyLabel(item.task.difficulty),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              if (canAct) _action(item),
            ],
          ),
          if (payout != null) ...[
            const SizedBox(height: 4),
            Center(child: PayoutBurst(payout: payout)),
          ],
        ],
      ),
    );
  }

  Widget _action(CalendarItem item) {
    switch (item.type) {
      case TaskType.habit:
        if (!item.task.isPositive) {
          return const SizedBox.shrink();
        }
        return IconButton(
          tooltip: 'I did this',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
          onPressed: () => gameState.scoreHabitUp(item.task),
          icon: const Icon(Icons.add, color: Colors.green, size: 18),
        );
      case TaskType.daily:
      case TaskType.todo:
        return IconButton(
          tooltip: item.task.isDone ? 'Already done' : 'Complete',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
          onPressed: item.task.isDone
              ? null
              : () => gameState.completeTask(item.task),
          icon: Icon(
            item.task.isDone ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
            color: item.task.isDone ? Colors.white38 : Colors.white70,
          ),
        );
    }
  }
}

Color _typeColor(TaskType type) {
  switch (type) {
    case TaskType.habit:
      return const Color(0xFF8E7CC3);
    case TaskType.daily:
      return AppTheme.accentBlue;
    case TaskType.todo:
      return Colors.amber;
  }
}
