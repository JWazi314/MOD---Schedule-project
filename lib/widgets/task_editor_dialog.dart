import 'package:flutter/material.dart';

import '../game/progression.dart';
import '../models/task.dart';

class TaskEditorResult {
  final Task? task;
  final bool deleted;

  const TaskEditorResult.save(this.task) : deleted = false;

  const TaskEditorResult.delete() : task = null, deleted = true;
}

Future<TaskEditorResult?> showTaskEditor(
  BuildContext context, {
  Task? existing,
}) {
  return showDialog<TaskEditorResult>(
    context: context,
    builder: (context) => TaskEditorDialog(existing: existing),
  );
}

class TaskEditorDialog extends StatefulWidget {
  final Task? existing;

  const TaskEditorDialog({super.key, this.existing});

  @override
  State<TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<TaskEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late int _difficulty;
  late String _section;
  late List<int> _repeatDays;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
    _difficulty = existing?.difficulty ?? 0;
    _section = existing?.section ?? 'General';
    _repeatDays = List<int>.from(existing?.repeatDays ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _sections {
    final sections = List<String>.from(Task.sections);
    if (!sections.contains(_section)) {
      sections.add(_section);
    }
    return sections;
  }

  TaskPayout get _preview {
    final existing = widget.existing;
    if (existing != null && existing.difficulty == _difficulty) {
      return TaskPayout(existing.gold, existing.silver, existing.xp);
    }
    return TaskPayout.forDifficulty(_difficulty);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final payout = _preview;
    final existing = widget.existing;
    final task = Task(
      title: _titleController.text.trim(),
      difficulty: _difficulty,
      repeatDays: List<int>.from(_repeatDays)..sort(),
      gold: payout.gold,
      silver: payout.silver,
      xp: payout.xp,
      section: _section,
      note: _noteController.text.trim(),
      isDone: existing?.isDone ?? false,
      completedAt: existing?.completedAt,
      streak: existing?.streak ?? 0,
    );

    Navigator.of(context).pop(TaskEditorResult.save(task));
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final editing = widget.existing != null;

    return AlertDialog(
      title: Text(editing ? 'Edit quest' : 'New quest'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: !editing,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Quest name',
                    hintText: 'Morning workout',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a quest name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'Optional',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _section,
                  decoration: const InputDecoration(labelText: 'Section'),
                  items: [
                    for (final section in _sections)
                      DropdownMenuItem(value: section, child: Text(section)),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _section = value);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Difficulty',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Easy')),
                    ButtonSegment(value: 1, label: Text('Medium')),
                    ButtonSegment(value: 2, label: Text('Hard')),
                  ],
                  selected: {_difficulty},
                  onSelectionChanged: (selection) {
                    setState(() => _difficulty = selection.first);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '${preview.gold} gold · ${preview.silver} silver · ${preview.xp} XP',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Repeats',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Leave every day off for a one-time to-do. Selected days become a daily with a streak.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(Task.dayLabels.length, (index) {
                    final selected = _repeatDays.contains(index);
                    return FilterChip(
                      label: Text(Task.dayLabels[index]),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _repeatDays.add(index);
                          } else {
                            _repeatDays.remove(index);
                          }
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (editing)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const TaskEditorResult.delete()),
            child: const Text('Delete'),
          ),
        FilledButton(onPressed: _save, child: Text(editing ? 'Save' : 'Add')),
      ],
    );
  }
}
