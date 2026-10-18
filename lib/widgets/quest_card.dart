import 'package:flutter/material.dart';

import '../models/task.dart';

class QuestCard extends StatelessWidget {
  final Task task;
  final bool isDone;
  final bool scheduledToday;
  final VoidCallback onComplete;
  final VoidCallback onEdit;

  const QuestCard({
    super.key,
    required this.task,
    required this.isDone,
    required this.scheduledToday,
    required this.onComplete,
    required this.onEdit,
  });

  Color get _accent {
    if (isDone) {
      return const Color(0xFF2F6B4F);
    }
    switch (task.difficulty) {
      case 1:
        return const Color(0xFFC4841D);
      case 2:
        return const Color(0xFFB23A48);
      default:
        return const Color(0xFF3D8B6E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = isDone ? scheme.onSurface.withValues(alpha: 0.55) : scheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: _accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: muted,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _MetaChip(icon: Icons.folder_outlined, label: task.section),
                          _MetaChip(
                            icon: Icons.speed,
                            label: task.difficultyLabel,
                            color: _accent,
                          ),
                          if (task.isTodo)
                            const _MetaChip(icon: Icons.task_alt, label: 'To-do')
                          else if (!scheduledToday)
                            const _MetaChip(icon: Icons.event, label: 'Later'),
                          if (task.streak > 0)
                            _MetaChip(
                              icon: Icons.local_fire_department,
                              label: '${task.streak}',
                              color: const Color(0xFFC4841D),
                            ),
                        ],
                      ),
                      if (!task.isTodo) ...[
                        const SizedBox(height: 8),
                        Text(
                          _scheduleLabel(task),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _Payout(icon: Icons.monetization_on, label: '${task.gold}', color: const Color(0xFFC4A35A)),
                          _Payout(icon: Icons.toll, label: '${task.silver}', color: const Color(0xFF8D8D8D)),
                          _Payout(icon: Icons.star, label: '${task.xp}', color: const Color(0xFF2F6B4F)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: isDone ? 'Completed' : 'Complete',
                onPressed: isDone ? null : onComplete,
                icon: Icon(
                  isDone ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isDone ? const Color(0xFF2F6B4F) : scheme.onSurfaceVariant,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _scheduleLabel(Task task) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final days = task.repeatDays
      .where((day) => day >= 0 && day < names.length)
      .map((day) => names[day]);
  if (days.isEmpty) {
    return 'Repeats';
  }
  return days.join(' · ');
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetaChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: tint),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: tint, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _Payout extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Payout({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
