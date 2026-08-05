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

  @override
  Widget build(BuildContext context) {
    return Card(
      // Information on the card format
      color: const Color.fromARGB(255, 41, 24, 2),
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),

        side: BorderSide(
          color: isDone ? const Color.fromARGB(255, 51, 255, 0) : Colors.amber,
          width: 1.4,
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

                borderRadius: BorderRadius.circular(10),
                hoverColor: Colors.white.withValues(alpha: 0.08),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,

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

            const SizedBox(width: 250),

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
