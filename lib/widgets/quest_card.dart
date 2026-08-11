import 'package:flutter/material.dart';
import '../models/task.dart';

class QuestCard extends StatelessWidget {
  final Task task;
  final bool isDone;

  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const QuestCard({
    super.key,
    required this.task,
    required this.isDone,

    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  Color taskColor(Task task) {
    if (task.difficulty == 0) {
      return Colors.green;
    } else if (task.difficulty == 1) {
      return Colors.amber;
    } else if (task.difficulty == 2) {
      return Colors.red;
    }

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      // Information on the card format
      color: const Color.fromARGB(50, 50, 50, 50),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),

        side: BorderSide(
          color: isDone
              ? const Color.fromARGB(255, 51, 255, 0)
              : taskColor(task),
          width: 1.8,
        ),
      ),

      //info and functionality inside the card

      //left side
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onEdit,

                borderRadius: BorderRadius.circular(20),
                hoverColor: taskColor(task).withValues(alpha: 0.2),
                splashColor: Colors.transparent,
                highlightColor: taskColor(task),

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 14,
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 14),

                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Wrap(spacing: 12, runSpacing: 4, children: []),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            //Right side of the questCard
            InkWell(
              onTap: isDone ? null : onComplete,

              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),

              hoverColor: Colors.greenAccent.withValues(alpha: 0.15),

              child: Icon(
                isDone ? Icons.check_box : Icons.check_box_outline_blank,
                color: isDone ? Colors.greenAccent : Colors.white54,
                size: 40,
              ),
            ),

            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
