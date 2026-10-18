import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mod_app/models/task.dart';
import 'package:mod_app/pages/home_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Completing a task awards gold, silver, and XP', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: QuestHomePage(),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state<QuestHomePageState>(
      find.byType(QuestHomePage),
    );

    final task = Task(
      title: 'Workout',
      difficulty: 1,
      repeatDays: [1, 2, 3],
      gold: 10,
      silver: 5,
      xp: 50,
      section: 'Health',
    );

    state.tasks.add(task);
    state.unlockedAchievements.add('first_task');

    state.completeTask(task);

    await tester.pump();

    expect(task.isDone, true);
    expect(task.completedAt, isNotNull);
    expect(state.gold, 10);
    expect(state.silver, 5);
    expect(state.xp, 50);
  });

  testWidgets('Completing the same task twice does not give double rewards', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: QuestHomePage(),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state<QuestHomePageState>(
      find.byType(QuestHomePage),
    );

    final task = Task(
      title: 'Study',
      difficulty: 2,
      repeatDays: [1, 2, 3, 4, 5],
      gold: 15,
      silver: 7,
      xp: 75,
      section: 'School',
    );

    state.tasks.add(task);
    state.unlockedAchievements.add('first_task');

    state.completeTask(task);
    state.completeTask(task);

    await tester.pump();

    expect(state.gold, 15);
    expect(state.silver, 7);
    expect(state.xp, 75);
  });

  testWidgets('Reset day marks completed tasks as incomplete', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: QuestHomePage(),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state<QuestHomePageState>(
      find.byType(QuestHomePage),
    );

    final task1 = Task(
      title: 'Workout',
      difficulty: 1,
      repeatDays: [1],
      gold: 10,
      silver: 5,
      xp: 50,
      section: 'Health',
      isDone: true,
    );

    final task2 = Task(
      title: 'Study',
      difficulty: 1,
      repeatDays: [1],
      gold: 10,
      silver: 5,
      xp: 50,
      section: 'School',
      isDone: true,
    );

    state.tasks.addAll([task1, task2]);

    state.resetDay();

    await tester.pump();

    expect(task1.isDone, false);
    expect(task2.isDone, false);
  });

  testWidgets('Removing a task deletes it from the task list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: QuestHomePage(),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state<QuestHomePageState>(
      find.byType(QuestHomePage),
    );

    final task = Task(
      title: 'Read',
      difficulty: 0,
      repeatDays: [1],
      gold: 5,
      silver: 2,
      xp: 25,
      section: 'Personal',
    );

    state.tasks.add(task);

    expect(state.tasks.length, 1);

    state.removeTask(task);

    await tester.pump();

    expect(state.tasks, isEmpty);
  });

  testWidgets('Saved progress loads gold, silver, XP, and tasks', (
    WidgetTester tester,
  ) async {
    final savedTask = Task(
      title: 'Workout',
      difficulty: 2,
      repeatDays: [1, 3, 5],
      gold: 15,
      silver: 7,
      xp: 75,
      section: 'Health',
      isDone: true,
    );

    SharedPreferences.setMockInitialValues({
      'gold': 100,
      'silver': 50,
      'xp': 300,
      'tasks': jsonEncode([savedTask.toJson()]),
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: QuestHomePage(),
      ),
    );

    await tester.pumpAndSettle();

    final state = tester.state<QuestHomePageState>(
      find.byType(QuestHomePage),
    );

    expect(state.gold, 100);
    expect(state.silver, 50);
    expect(state.xp, 300);

    expect(state.tasks.length, 1);
    expect(state.tasks.first.title, 'Workout');
    expect(state.tasks.first.isDone, true);
  });

  testWidgets('Repeating quests keep a streak until a due day is missed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: QuestHomePage()));
    await tester.pumpAndSettle();

    final state = tester.state<QuestHomePageState>(find.byType(QuestHomePage));
    state.unlockedAchievements.addAll(['first_task', 'on_a_roll']);

    final task = Task(
      title: 'Stretch',
      difficulty: 1,
      repeatDays: const [0, 1, 2, 3, 4, 5, 6],
      gold: 10,
      silver: 5,
      xp: 50,
      section: 'Health',
    );
    state.tasks.add(task);

    state.completeTask(task);
    expect(task.streak, 1);
    expect(state.gold, 10);

    state.resetDay();
    expect(task.isDone, false);
    expect(task.streak, 1);

    state.completeTask(task);
    state.resetDay();
    state.completeTask(task);

    expect(task.streak, 3);
    expect(state.bestStreak, 3);
    expect(state.gold, 32);

    final missed = Task(
      title: 'Run',
      difficulty: 0,
      repeatDays: const [0, 1, 2, 3, 4, 5, 6],
      gold: 5,
      silver: 2,
      xp: 25,
      section: 'Health',
      streak: 4,
    );
    state.tasks.add(missed);
    expect(state.resetDay(), 1);
    expect(missed.streak, 0);
    expect(missed.isDone, false);
  });

  testWidgets('Adding and completing a quest pays gold and an achievement', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: QuestHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Read a chapter');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Read a chapter'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Complete'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Complete'));
    await tester.pump();

    final state = tester.state<QuestHomePageState>(find.byType(QuestHomePage));
    expect(state.gold, 30);
    expect(state.silver, 2);
    expect(state.xp, 25);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('30 gold'), findsOneWidget);
    expect(find.text('2 silver'), findsOneWidget);
  });

  testWidgets('Renaming the player updates the card without throwing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: QuestHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('The name shown on your player card'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Alex'), findsWidgets);

    await tester.tap(find.text('Quests'));
    await tester.pumpAndSettle();
    expect(find.text('Alex'), findsOneWidget);
  });

  testWidgets('A custom reward can be added and bought', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: QuestHomePage()));
    await tester.pumpAndSettle();

    final state = tester.state<QuestHomePageState>(find.byType(QuestHomePage));
    state.gold = 25;
    state.unlockedAchievements.add('treat_yourself');

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add your own reward'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hour of reading');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Hour of reading'), findsOneWidget);
    await tester.tap(find.text('10 gold'));
    await tester.pump();

    expect(state.gold, 15);
    expect(state.inventory, contains('Hour of reading'));

    await tester.tap(find.text('Bag'));
    await tester.pumpAndSettle();
    expect(find.text('Hour of reading'), findsOneWidget);
  });
}