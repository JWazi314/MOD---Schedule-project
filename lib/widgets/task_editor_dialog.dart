import 'package:flutter/material.dart';

import '../game/task_value.dart';
import '../models/checklist_item.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import '../state/game_state.dart';
import '../theme.dart';

const List<String> _dayLabels = ['M', 'T', 'W', 'Th', 'F', 'St', 'Sn'];

/// Opens the add or edit form. Pass [task] to edit, or leave it null to add a
/// new one to [sectionId].
Future<void> showTaskEditor(
  BuildContext context, {
  required GameState gameState,
  required String sectionId,
  Task? task,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return TaskEditorDialog(
        gameState: gameState,
        sectionId: sectionId,
        task: task,
      );
    },
  );
}

/// One form for all three task types.
///
/// The type comes from whichever section is selected, so the shown fields
/// change as soon as the section dropdown does: repeat days for a Daily, a
/// due date for a To-Do, direction toggles for a Habit.
class TaskEditorDialog extends StatefulWidget {
  final GameState gameState;
  final String sectionId;
  final Task? task;

  const TaskEditorDialog({
    super.key,
    required this.gameState,
    required this.sectionId,
    this.task,
  });

  @override
  State<TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<TaskEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late String _description;
  late String _sectionId;
  late String _groupId;
  late int _difficulty;
  late List<int> _repeatDays;
  late DateTime? _dueDate;
  late bool _isPositive;
  late bool _isNegative;
  late List<_PartDraft> _parts;

  int _nextPartId = 0;
  String? _directionError;

  bool get _isEditing => widget.task != null;

  TaskType get _type {
    return widget.gameState.sectionById(_sectionId)?.type ?? TaskType.daily;
  }

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    _title = task?.title ?? '';
    _description = task?.description ?? '';
    _sectionId = task?.sectionId ?? widget.sectionId;
    _groupId = task?.groupId ?? '';
    _difficulty = task?.difficulty ?? 0;
    _repeatDays = List<int>.from(task?.repeatDays ?? const <int>[]);
    _dueDate = task?.dueDate;
    _isPositive = task?.isPositive ?? true;
    _isNegative = task?.isNegative ?? false;

    _parts = [
      for (final item in task?.checklist ?? const <ChecklistItem>[])
        _PartDraft(
          id: item.id,
          title: item.title,
          isDone: item.isDone,
        ),
    ];
  }

  @override
  void dispose() {
    for (final part in _parts) {
      part.controller.dispose();
    }
    super.dispose();
  }

  void _addPart() {
    setState(() {
      _parts.add(_PartDraft(id: 'part_${_nextPartId++}_${_freshId()}'));
    });
  }

  void _removePart(_PartDraft part) {
    setState(() {
      _parts.remove(part);
    });
    part.controller.dispose();
  }

  String _freshId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Habits have no parts, so switching a task to one drops them.
  List<ChecklistItem> _buildChecklist() {
    if (_type == TaskType.habit) {
      return <ChecklistItem>[];
    }

    return [
      for (final part in _parts)
        if (part.controller.text.trim().isNotEmpty)
          ChecklistItem(
            id: part.id,
            title: part.controller.text.trim(),
            isDone: part.isDone,
          ),
    ];
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_type == TaskType.habit && !_isPositive && !_isNegative) {
      setState(() {
        _directionError = 'a habit needs a good side, a bad side, or both';
      });
      return;
    }

    _formKey.currentState!.save();

    final gameState = widget.gameState;
    final existing = widget.task;

    if (existing == null) {
      gameState.addTask(
        Task(
          title: _title,
          description: _description,
          difficulty: _difficulty,
          sectionId: _sectionId,
          groupId: _groupId,
          repeatDays: _repeatDays,
          checklist: _buildChecklist(),
          dueDate: _dueDate,
          isPositive: _isPositive,
          isNegative: _isNegative,
        ),
      );
    } else {
      gameState.updateTask(
        existing,
        title: _title,
        description: _description,
        difficulty: _difficulty,
        sectionId: _sectionId,
        groupId: _groupId,
        repeatDays: _repeatDays,
        checklist: _buildChecklist(),
        dueDate: _dueDate,
        isPositive: _isPositive,
        isNegative: _isNegative,
      );
    }

    Navigator.of(context).pop();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.gameState.sections;

    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit ${_type.singularLabel}' : 'Add ${_type.singularLabel}',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: _title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Task Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'enter a task name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value!.trim();
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                key: const ValueKey('task-description'),
                initialValue: _description,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional notes',
                ),
                onSaved: (value) {
                  _description = value?.trim() ?? '';
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _sectionId,
                decoration: const InputDecoration(labelText: 'Section'),
                items: sections.map((section) {
                  return DropdownMenuItem<String>(
                    value: section.id,
                    child: Row(
                      children: [
                        Icon(section.type.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(section.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sectionId = value;
                      _groupId = '';
                      _directionError = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 8),

              Text(
                _type.description,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),

              if (widget.gameState.sectionById(_sectionId)?.groups.isNotEmpty ??
                  false) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _groupId,
                  decoration: const InputDecoration(labelText: 'Group'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('No group'),
                    ),
                    for (final group
                        in widget.gameState.sectionById(_sectionId)!.groups)
                      DropdownMenuItem<String>(
                        value: group.id,
                        child: Text(group.name),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _groupId = value;
                      });
                    }
                  },
                ),
              ],

              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Difficulty', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 10),

              _DifficultyPicker(
                difficulty: _difficulty,
                onChanged: (value) {
                  setState(() {
                    _difficulty = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              ..._typeFields(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),

        if (_isEditing)
          TextButton(
            onPressed: () {
              widget.gameState.removeTask(widget.task!);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),

        ElevatedButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  List<Widget> _typeFields() {
    switch (_type) {
      case TaskType.daily:
        return [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Days Repeated', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(7, (index) {
              final isSelected = _repeatDays.contains(index);

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
                    borderRadius: AppTheme.borderRadius,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    if (isSelected) {
                      _repeatDays.remove(index);
                    } else {
                      _repeatDays.add(index);
                    }
                  });
                },
                child: Text(_dayLabels[index]),
              );
            }),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pick no days to make it due every day.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          ..._checklistFields(),
        ];

      case TaskType.todo:
        return [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Due Date', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDueDate,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _dueDate == null
                        ? 'No due date'
                        : '${_dueDate!.year}-${_dueDate!.month}-'
                              '${_dueDate!.day}',
                  ),
                ),
              ),
              if (_dueDate != null)
                IconButton(
                  tooltip: 'Clear due date',
                  onPressed: () {
                    setState(() {
                      _dueDate = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Optional. A late To-Do is never punished.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          ..._checklistFields(),
        ];

      case TaskType.habit:
        return [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Directions', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DirectionToggle(
                  label: 'Good',
                  icon: Icons.add,
                  color: Colors.green,
                  isOn: _isPositive,
                  onChanged: (value) {
                    setState(() {
                      _isPositive = value;
                      _directionError = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DirectionToggle(
                  label: 'Bad',
                  icon: Icons.remove,
                  color: Colors.redAccent,
                  isOn: _isNegative,
                  onChanged: (value) {
                    setState(() {
                      _isNegative = value;
                      _directionError = null;
                    });
                  },
                ),
              ),
            ],
          ),
          if (_directionError != null) ...[
            const SizedBox(height: 8),
            Text(
              _directionError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Good pays out when you tap it. Bad costs the Mod some Vigor.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ];
    }
  }

  List<Widget> _checklistFields() {
    return [
      const SizedBox(height: 20),

      Row(
        children: [
          const Expanded(child: Text('Parts', style: TextStyle(fontSize: 16))),
          TextButton.icon(
            onPressed: _addPart,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add part'),
          ),
        ],
      ),

      if (_parts.isEmpty)
        const Text(
          'Optional. Break the task into steps and it finishes itself once '
          'they are all ticked.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),

      for (final part in _parts)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: part.controller,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Step',
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove part',
                onPressed: () => _removePart(part),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
    ];
  }
}

/// One draft row in the parts editor. Kept separate from [ChecklistItem] so
/// an abandoned edit never touches the saved task.
class _PartDraft {
  final String id;
  final TextEditingController controller;
  final bool isDone;

  _PartDraft({required this.id, String title = '', this.isDone = false})
    : controller = TextEditingController(text: title);
}

class _DifficultyPicker extends StatelessWidget {
  final int difficulty;
  final ValueChanged<int> onChanged;

  const _DifficultyPicker({required this.difficulty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        final isSelected = difficulty == index;

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? TaskValue.cardColor(index, 0.85)
                : null,
          ),
          onPressed: () => onChanged(index),
          child: Text(TaskValue.difficultyLabel(index)),
        );
      }),
    );
  }
}

class _DirectionToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isOn;
  final ValueChanged<bool> onChanged;

  const _DirectionToggle({
    required this.label,
    required this.icon,
    required this.color,
    required this.isOn,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppTheme.borderRadius,
      onTap: () => onChanged(!isOn),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isOn ? color.withAlpha(35) : AppTheme.panel,
          borderRadius: AppTheme.borderRadius,
          border: Border.all(
            color: isOn ? color : AppTheme.border,
            width: isOn ? 2 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isOn ? color : Colors.white38),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isOn ? Colors.white : Colors.white54,
                fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
