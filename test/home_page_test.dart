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
}