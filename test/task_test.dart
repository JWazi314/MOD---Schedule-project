import 'package:flutter_test/flutter_test.dart';
import 'package:mod_app/models/task.dart';

void main() {
  test('Task is created correctly', () {
    final task = Task(
      title: 'Workout',
      difficulty: 2,
      repeatDays: [1, 3, 5],
      gold: 10,
      silver: 5,
      xp: 20,
      section: 'Health',
    );

    expect(task.title, 'Workout');
    expect(task.difficulty, 2);
    expect(task.repeatDays, [1, 3, 5]);
    expect(task.gold, 10);
    expect(task.silver, 5);
    expect(task.xp, 20);
    expect(task.section, 'Health');
    expect(task.isDone, false);
    expect(task.completedAt, null);
  });

  test('Task converts to JSON correctly', () {
    final task = Task(
      title: 'Study',
      difficulty: 3,
      repeatDays: [2, 4],
      gold: 15,
      silver: 8,
      xp: 30,
      section: 'School',
      isDone: true,
    );

    final json = task.toJson();

    expect(json['title'], 'Study');
    expect(json['difficulty'], 3);
    expect(json['repeatDays'], [2, 4]);
    expect(json['gold'], 15);
    expect(json['silver'], 8);
    expect(json['xp'], 30);
    expect(json['section'], 'School');
    expect(json['isDone'], true);
  });

  test('Task restores correctly from JSON', () {
    final json = {
      'title': 'Read',
      'difficulty': 1,
      'repeatDays': [1, 2, 3],
      'gold': 5,
      'silver': 2,
      'xp': 10,
      'section': 'Personal',
      'isDone': true,
      'completedAt': '2026-08-10T18:00:00.000',
    };

    final task = Task.fromJson(json);

    expect(task.title, 'Read');
    expect(task.difficulty, 1);
    expect(task.repeatDays, [1, 2, 3]);
    expect(task.gold, 5);
    expect(task.silver, 2);
    expect(task.xp, 10);
    expect(task.section, 'Personal');
    expect(task.isDone, true);
    expect(task.completedAt, DateTime.parse('2026-08-10T18:00:00.000'));
  });

  test('Task fromJson uses default values when data is missing', () {
    final task = Task.fromJson({});

    expect(task.title, '');
    expect(task.difficulty, 0);
    expect(task.repeatDays, []);
    expect(task.gold, 0);
    expect(task.silver, 0);
    expect(task.xp, 0);
    expect(task.section, 'General');
    expect(task.isDone, false);
    expect(task.completedAt, null);
  });

  test('Task can be converted to JSON and restored without losing data', () {
    final original = Task(
      title: 'No Fast Food',
      difficulty: 3,
      repeatDays: [1, 2, 3, 4, 5],
      gold: 25,
      silver: 10,
      xp: 50,
      section: 'Habits',
      isDone: true,
      completedAt: DateTime(2026, 8, 10, 18, 30),
      note: 'Skip the drive-through',
      streak: 4,
    );

    final restored = Task.fromJson(original.toJson());

    expect(restored.title, original.title);
    expect(restored.difficulty, original.difficulty);
    expect(restored.repeatDays, original.repeatDays);
    expect(restored.gold, original.gold);
    expect(restored.silver, original.silver);
    expect(restored.xp, original.xp);
    expect(restored.section, original.section);
    expect(restored.isDone, original.isDone);
    expect(restored.completedAt, original.completedAt);
    expect(restored.note, original.note);
    expect(restored.streak, original.streak);
  });

  test('Task fromJson keeps older saves that have no streak or note', () {
    final task = Task.fromJson({
      'title': 'Read',
      'difficulty': 0,
      'repeatDays': [0],
      'gold': 5,
      'silver': 2,
      'xp': 25,
      'section': 'Personal',
      'isDone': false,
    });

    expect(task.note, '');
    expect(task.streak, 0);
    expect(task.showsOnTodayBoard(DateTime(2026, 10, 19)), true);
    expect(task.showsOnTodayBoard(DateTime(2026, 10, 20)), false);
  });
}