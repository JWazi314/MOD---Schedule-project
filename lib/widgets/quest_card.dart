import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/task_value.dart';
import '../models/checklist_item.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import '../state/game_state.dart';
import '../theme.dart';
import 'payout_burst.dart';

/// The outline a finished task gets. Deliberately drab, so a done card stops
/// competing for attention with the ones still waiting.
const Color _doneGrey = Color(0xFF5C7186);

/// One task on the board.
///
/// The border keeps meaning difficulty, and deepens from muted to vivid as
/// the task goes untouched. The trailing control depends on the type: a
/// checkbox for Dailies and To-Dos, minus and plus for Habits.
class QuestCard extends StatefulWidget {
  final Task task;
  final TaskType type;

  final VoidCallback onComplete;
  final VoidCallback onHabitUp;
  final VoidCallback onHabitDown;
  final ValueChanged<ChecklistItem> onTogglePart;
  final VoidCallback onEdit;
  final bool canDrag;

  const QuestCard({
    super.key,
    required this.task,
    required this.type,
    required this.onComplete,
    required this.onHabitUp,
    required this.onHabitDown,
    required this.onTogglePart,
    required this.onEdit,
    this.canDrag = false,
  });

  @override
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard> {
  bool _isExpanded = false;

  Task get task => widget.task;
  TaskType get type => widget.type;

  bool get _isDone => type != TaskType.habit && task.isDone;

  /// Habits have no parts, and a finished task has nothing left to open.
  bool get _canExpand => type != TaskType.habit && task.hasChecklist;

  Color get _accent {
    if (_isDone) {
      return _doneGrey;
    }
    return TaskValue.cardColor(task.difficulty, task.neglect);
  }

  /// Greys a colour out once the task is finished.
  Color _mute(Color color) => _isDone ? _doneGrey : color;

  @override
  void didUpdateWidget(QuestCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isExpanded && !_canExpand) {
      _isExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final payout = context.select<GameState, TaskPayout?>(
      (state) => identical(state.latestPayout?.task, task)
          ? state.latestPayout
          : null,
    );
    final splitHabit =
        type == TaskType.habit && task.isPositive && task.isNegative;

    return Card(
      color: _isDone ? AppTheme.surfaceDark : AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 6),
      shape: AppTheme.cardShape(
        sideColor: _accent,
        width: _isDone
            ? TaskValue.minBorderWidth
            : TaskValue.borderWidth(task.neglect),
      ),

      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          children: [
            Opacity(
              opacity: _isDone ? 0.6 : 1,
              child: Row(
                children: [
                  if (widget.canDrag) _dragHandle(),
                  if (type == TaskType.habit && task.isNegative) ...[
                    const SizedBox(width: 6),
                    _HabitButton(
                      icon: Icons.remove,
                      color: Colors.redAccent,
                      tooltip: 'I slipped up',
                      onTap: widget.onHabitDown,
                    ),
                    const SizedBox(width: 2),
                  ],
                  Expanded(
                    child: InkWell(
                      onTap: widget.onEdit,
                      borderRadius: AppTheme.borderRadius,
                      hoverColor: _accent.withValues(alpha: 0.2),
                      splashColor: Colors.transparent,
                      highlightColor: _accent,

                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),

                        child: Column(
                          crossAxisAlignment: splitHabit
                              ? CrossAxisAlignment.center
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              textAlign: splitHabit
                                  ? TextAlign.center
                                  : TextAlign.start,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                decoration: _isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: _isDone ? Colors.white54 : null,
                              ),
                            ),
                            if (task.description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                task.description,
                                maxLines: _isExpanded ? 8 : 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: splitHabit
                                    ? TextAlign.center
                                    : TextAlign.start,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.25,
                                  color: _isDone
                                      ? Colors.white38
                                      : Colors.white70,
                                ),
                              ),
                            ],

                            const SizedBox(height: 4),

                            Wrap(
                              alignment: splitHabit
                                  ? WrapAlignment.center
                                  : WrapAlignment.start,
                              spacing: 5,
                              runSpacing: 3,
                              children: _chips(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 2),

                  _trailingControl(),

                  const SizedBox(width: 6),
                ],
              ),
            ),

            if (payout != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: Center(child: PayoutBurst(payout: payout)),
              ),

            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _isExpanded && _canExpand
                  ? Opacity(
                      opacity: _isDone ? 0.6 : 1,
                      child: _checklistPanel(),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checklistPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(color: AppTheme.border, height: 8),

          if (!_isDone)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'Hold the arrow to finish the whole task.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),

          for (final part in task.checklist)
            InkWell(
              borderRadius: AppTheme.borderRadius,
              // A finished task is locked so a stray tap cannot undo it.
              onTap: _isDone ? null : () => widget.onTogglePart(part),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      part.isDone
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                      color: part.isDone ? _mute(Colors.greenAccent) : Colors.white54,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        part.title,
                        style: TextStyle(
                          fontSize: 13,
                          decoration: part.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: part.isDone ? Colors.white54 : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _chips() {
    final chips = <Widget>[
      _TaskChip(
        label: TaskValue.difficultyLabel(task.difficulty),
        color: _mute(TaskValue.cardColor(task.difficulty, 0.9)),
      ),
    ];

    if (_canExpand) {
      chips.add(
        _TaskChip(
          label: '${task.completedParts}/${task.checklist.length}',
          icon: Icons.checklist_rtl,
          color: _mute(AppTheme.accentBlue),
        ),
      );
    }

    switch (type) {
      case TaskType.daily:
        if (task.isSkipped) {
          chips.add(
            const _TaskChip(label: 'Skipped', color: Colors.white54),
          );
        }
        if (task.streak > 0) {
          chips.add(
            _TaskChip(
              label: '${task.streak} day streak',
              icon: Icons.local_fire_department,
              color: _mute(Colors.orangeAccent),
            ),
          );
        }
        if (task.repeatDays.isNotEmpty && task.repeatDays.length < 7) {
          chips.add(
            _TaskChip(
              label: _repeatSummary(task.repeatDays),
              icon: Icons.event_repeat,
              color: Colors.white38,
            ),
          );
        }
        break;

      case TaskType.todo:
        final due = task.dueDate;
        if (due != null) {
          chips.add(
            _TaskChip(
              label: '${due.year}-${due.month}-${due.day}',
              icon: Icons.event,
              color: task.isOverdue
                  ? _mute(Colors.redAccent)
                  : Colors.white38,
            ),
          );
        }
        break;

      case TaskType.habit:
        if (task.isPositive) {
          chips.add(_TaskChip(label: '+${task.upCount}', color: Colors.green));
        }
        if (task.isNegative) {
          chips.add(
            _TaskChip(label: '-${task.downCount}', color: Colors.redAccent),
          );
        }
        break;
    }

    return chips;
  }

  static String _repeatSummary(List<int> days) {
    const labels = ['M', 'T', 'W', 'Th', 'F', 'St', 'Sn'];
    final sorted = List<int>.from(days)..sort();
    return sorted
        .where((day) => day >= 0 && day < labels.length)
        .map((day) => labels[day])
        .join(' ');
  }

  Widget _dragHandle() {
    return Draggable<Task>(
      data: task,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        elevation: 8,
        borderRadius: AppTheme.borderRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: _DragGhost(title: task.title, color: _accent),
        ),
      ),
      childWhenDragging: const Padding(
        padding: EdgeInsets.only(left: 2),
        child: Icon(Icons.drag_indicator, size: 18, color: Colors.white12),
      ),
      child: const Padding(
        padding: EdgeInsets.only(left: 2),
        child: Icon(Icons.drag_indicator, size: 18, color: Colors.white54),
      ),
    );
  }

  Widget _trailingControl() {
    if (_canExpand) {
      return _PullDownControl(
        isExpanded: _isExpanded,
        isDone: _isDone,
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        onHoldComplete: _isDone ? null : widget.onComplete,
      );
    }

    if (type != TaskType.habit) {
      return _CompleteMark(
        isDone: task.isDone,
        onTap: task.isDone ? null : widget.onComplete,
      );
    }

    if (!task.isPositive) {
      return const SizedBox.shrink();
    }

    return _HabitButton(
      icon: Icons.add,
      color: Colors.green,
      tooltip: 'I did this',
      onTap: widget.onHabitUp,
    );
  }
}

/// Boxed down-arrow for checklist tasks. A tap opens the parts; holding
/// it for about a second finishes the whole task.
class _PullDownControl extends StatefulWidget {
  static const Duration holdDuration = Duration(milliseconds: 900);

  final bool isExpanded;
  final bool isDone;
  final VoidCallback onTap;
  final VoidCallback? onHoldComplete;

  const _PullDownControl({
    required this.isExpanded,
    required this.isDone,
    required this.onTap,
    required this.onHoldComplete,
  });

  @override
  State<_PullDownControl> createState() => _PullDownControlState();
}

class _PullDownControlState extends State<_PullDownControl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold;
  bool _heldThrough = false;

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(
      vsync: this,
      duration: _PullDownControl.holdDuration,
    );
    _hold.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          widget.onHoldComplete != null) {
        _heldThrough = true;
        widget.onHoldComplete!();
      }
    });
  }

  @override
  void didUpdateWidget(_PullDownControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDone && !oldWidget.isDone) {
      _hold.value = 0;
    }
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _pointerDown() {
    _heldThrough = false;
    if (widget.onHoldComplete == null) {
      return;
    }
    _hold.forward(from: 0);
  }

  void _pointerEnd({required bool allowTap}) {
    final held = _heldThrough;
    if (_hold.isAnimating) {
      _hold
        ..stop()
        ..value = 0;
    } else if (!held) {
      _hold.value = 0;
    }
    if (allowTap && !held) {
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isDone ? _doneGrey : Colors.white70;

    return Tooltip(
      message: widget.isExpanded ? 'Hide parts' : 'Show parts',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _pointerDown(),
        onPointerUp: (_) => _pointerEnd(allowTap: true),
        onPointerCancel: (_) => _pointerEnd(allowTap: false),
        child: AnimatedBuilder(
          animation: _hold,
          builder: (context, child) {
            final fill = _hold.value;
            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Color.lerp(
                  color.withAlpha(30),
                  Colors.greenAccent.withAlpha(70),
                  fill,
                ),
                borderRadius: AppTheme.borderRadius,
                border: Border.all(
                  color: Color.lerp(color, Colors.greenAccent, fill)!,
                  width: 1.2,
                ),
              ),
              child: child,
            );
          },
          child: AnimatedRotation(
            turns: widget.isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            child: Icon(Icons.expand_more, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}

/// Checkbox that pops green for a beat when the task is ticked off.
class _CompleteMark extends StatefulWidget {
  final bool isDone;
  final VoidCallback? onTap;

  const _CompleteMark({required this.isDone, required this.onTap});

  @override
  State<_CompleteMark> createState() => _CompleteMarkState();
}

class _CompleteMarkState extends State<_CompleteMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.32,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.32,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_controller);
    if (widget.isDone) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(_CompleteMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isDone && widget.isDone) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      customBorder: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
      ),
      hoverColor: Colors.greenAccent.withValues(alpha: 0.15),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final color = widget.isDone
              ? Color.lerp(Colors.greenAccent, _doneGrey, _controller.value)!
              : Colors.white54;
          return ScaleTransition(
            scale: _scale,
            child: Icon(
              widget.isDone ? Icons.check_box : Icons.check_box_outline_blank,
              color: color,
              size: 26,
            ),
          );
        },
      ),
    );
  }
}

class _HabitButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _HabitButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadius,
        ),
        hoverColor: color.withValues(alpha: 0.2),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: AppTheme.borderRadius,
            border: Border.all(color: color, width: 1.2),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _DragGhost extends StatelessWidget {
  final String title;
  final Color color;

  const _DragGhost({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}

class _TaskChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const _TaskChip({required this.label, this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: color.withAlpha(120), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          // Columns get narrow, so a long label shortens rather than
          // overflowing the card.
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
