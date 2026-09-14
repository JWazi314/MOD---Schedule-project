import 'package:flutter_test/flutter_test.dart';
import 'package:quest_tracker/models/checklist_item.dart';
import 'package:quest_tracker/models/task.dart';

void main() {
  test('Task is created correctly', () {
    final task = Task(
      title: 'Workout',
      difficulty: 2,
      repeatDays: [1, 3, 5],
      sectionId: 'health',
    );

    expect(task.title, 'Workout');
    expect(task.description, '');
    expect(task.difficulty, 2);
    expect(task.repeatDays, [1, 3, 5]);
    expect(task.sectionId, 'health');
    expect(task.neglect, 0);
    expect(task.streak, 0);
    expect(task.isDone, false);
    expect(task.completedAt, null);
    expect(task.dueDate, null);
    expect(task.isPositive, true);
    expect(task.isNegative, false);
    expect(task.upCount, 0);
    expect(task.downCount, 0);
  });

  test('Task converts to JSON correctly', () {
    final task = Task(
      title: 'Study',
      difficulty: 2,
      repeatDays: [2, 4],
      sectionId: 'school',
      neglect: 0.4,
      streak: 3,
      isDone: true,
    );

    final json = task.toJson();

    expect(json['title'], 'Study');
    expect(json['description'], '');
    expect(json['difficulty'], 2);
    expect(json['repeatDays'], [2, 4]);
    expect(json['sectionId'], 'school');
    expect(json['neglect'], 0.4);
    expect(json['streak'], 3);
    expect(json['isDone'], true);
  });

  test('Task restores correctly from JSON', () {
    final json = {
      'title': 'Read',
      'difficulty': 1,
      'repeatDays': [1, 2, 3],
      'sectionId': 'personal',
      'neglect': 0.25,
      'streak': 5,
      'isDone': true,
      'completedAt': '2026-08-10T18:00:00.000',
      'dueDate': '2026-08-12T00:00:00.000',
    };

    final task = Task.fromJson(json);

    expect(task.title, 'Read');
    expect(task.difficulty, 1);
    expect(task.repeatDays, [1, 2, 3]);
    expect(task.sectionId, 'personal');
    expect(task.neglect, 0.25);
    expect(task.streak, 5);
    expect(task.isDone, true);
    expect(task.completedAt, DateTime.parse('2026-08-10T18:00:00.000'));
    expect(task.dueDate, DateTime.parse('2026-08-12T00:00:00.000'));
  });

  test('Task fromJson uses default values when data is missing', () {
    final task = Task.fromJson({});

    expect(task.title, '');
    expect(task.description, '');
    expect(task.difficulty, 0);
    expect(task.repeatDays, <int>[]);
    // Tasks saved before sections existed land in Main Tasks.
    expect(task.sectionId, 'main');
    expect(task.neglect, 0);
    expect(task.streak, 0);
    expect(task.isDone, false);
    expect(task.completedAt, null);
    expect(task.dueDate, null);
    expect(task.isPositive, true);
    expect(task.isNegative, false);
  });

  test('a saved reward from an older version is simply ignored', () {
    final task = Task.fromJson({
      'title': 'Old Task',
      'difficulty': 1,
      'gold': 10,
      'silver': 5,
      'xp': 50,
    });

    expect(task.title, 'Old Task');
    expect(task.difficulty, 1);
    expect(task.neglect, 0);
  });

  test('neglect out of range is clamped on the way in', () {
    expect(Task.fromJson({'neglect': 3.2}).neglect, 1);
    expect(Task.fromJson({'neglect': -1.0}).neglect, 0);
  });

  test('Task can be converted to JSON and restored without losing data', () {
    final original = Task(
      title: 'No Fast Food',
      description: 'Skip the drive-through.',
      difficulty: 2,
      repeatDays: [1, 2, 3, 4, 5],
      sectionId: 'habits',
      neglect: 0.6,
      streak: 9,
      isDone: true,
      completedAt: DateTime(2026, 8, 10, 18, 30),
      dueDate: DateTime(2026, 8, 20),
      isPositive: false,
      isNegative: true,
      upCount: 4,
      downCount: 7,
    );

    final restored = Task.fromJson(original.toJson());

    expect(restored.title, original.title);
    expect(restored.description, original.description);
    expect(restored.difficulty, original.difficulty);
    expect(restored.repeatDays, original.repeatDays);
    expect(restored.sectionId, original.sectionId);
    expect(restored.neglect, original.neglect);
    expect(restored.streak, original.streak);
    expect(restored.isDone, original.isDone);
    expect(restored.completedAt, original.completedAt);
    expect(restored.dueDate, original.dueDate);
    expect(restored.isPositive, original.isPositive);
    expect(restored.isNegative, original.isNegative);
    expect(restored.upCount, original.upCount);
    expect(restored.downCount, original.downCount);
  });

  group('checklists', () {
    Task withParts(List<bool> done) {
      return Task(
        title: 'Clean the kitchen',
        difficulty: 1,
        sectionId: 'dailies',
        checklist: [
          for (var i = 0; i < done.length; i++)
            ChecklistItem(id: 'p$i', title: 'Step $i', isDone: done[i]),
        ],
      );
    }

    test('a task without parts reports none', () {
      final task = Task(title: 'Run', difficulty: 1, sectionId: 'dailies');

      expect(task.hasChecklist, isFalse);
      expect(task.completedParts, 0);
      expect(task.allPartsDone, isFalse);
    });

    test('progress counts only the ticked parts', () {
      final task = withParts([true, false, true]);

      expect(task.hasChecklist, isTrue);
      expect(task.completedParts, 2);
      expect(task.allPartsDone, isFalse);
    });

    test('every part ticked reads as all done', () {
      expect(withParts([true, true]).allPartsDone, isTrue);
    });

    test('ticking and clearing move every part at once', () {
      final task = withParts([false, true, false]);

      task.tickEveryPart();
      expect(task.allPartsDone, isTrue);

      task.clearChecklist();
      expect(task.completedParts, 0);
      expect(task.hasChecklist, isTrue);
    });

    test('parts survive a round trip through JSON', () {
      final restored = Task.fromJson(withParts([true, false]).toJson());

      expect(restored.checklist, hasLength(2));
      expect(restored.checklist.first.id, 'p0');
      expect(restored.checklist.first.title, 'Step 0');
      expect(restored.checklist.first.isDone, isTrue);
      expect(restored.checklist.last.isDone, isFalse);
    });

    test('a task saved before parts existed loads without any', () {
      final task = Task.fromJson({'title': 'Old', 'difficulty': 1});

      expect(task.checklist, isEmpty);
    });
  });

  group('isDueOn', () {
    test('a Daily with no chosen days is due every day', () {
      final task = Task(title: 'Water', difficulty: 0, sectionId: 'dailies');

      for (var day = 12; day <= 18; day++) {
        expect(task.isDueOn(DateTime(2026, 1, day)), isTrue);
      }
    });

    test('a Daily is only due on the weekdays it was given', () {
      // repeatDays is 0 for Monday, so [0, 2] is Monday and Wednesday.
      final task = Task(
        title: 'Gym',
        difficulty: 1,
        sectionId: 'dailies',
        repeatDays: [0, 2],
      );

      // 2026-01-12 is a Monday.
      expect(task.isDueOn(DateTime(2026, 1, 12)), isTrue);
      expect(task.isDueOn(DateTime(2026, 1, 13)), isFalse);
      expect(task.isDueOn(DateTime(2026, 1, 14)), isTrue);
      expect(task.isDueOn(DateTime(2026, 1, 18)), isFalse);
    });
  });

  group('isOverdue', () {
    test('is false without a due date', () {
      final task = Task(title: 'Someday', difficulty: 0, sectionId: 'todos');

      expect(task.isOverdue, isFalse);
    });

    test('is true once the due date has passed', () {
      final task = Task(
        title: 'Taxes',
        difficulty: 2,
        sectionId: 'todos',
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
      );

      expect(task.isOverdue, isTrue);
    });

    test('a finished To-Do is never overdue', () {
      final task = Task(
        title: 'Taxes',
        difficulty: 2,
        sectionId: 'todos',
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        isDone: true,
      );

      expect(task.isOverdue, isFalse);
    });
  });
}
