import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quest_tracker/game/calendar.dart';
import 'package:quest_tracker/game/task_value.dart';
import 'package:quest_tracker/models/task.dart';
import 'package:quest_tracker/pages/calendar_page.dart';
import 'package:quest_tracker/state/game_state.dart';
import 'package:quest_tracker/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameState> pumpCalendar(WidgetTester tester) async {
  final state = GameState();
  await state.load();
  state.createMod(name: 'Pip', appearanceId: 'wanderer');
  state.takeMessages();

  await tester.pumpWidget(
    ChangeNotifierProvider<GameState>.value(
      value: state,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: CalendarPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return state;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TaskValue.nextRoll = () => 0.5;
  });

  tearDown(TaskValue.resetRoll);

  testWidgets('the current month is on the page', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpCalendar(tester);

    expect(find.text(Calendar.monthTitle(DateTime.now())), findsOneWidget);
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Dailies'), findsOneWidget);
    expect(find.text('To-Dos'), findsOneWidget);
  });

  testWidgets('a Daily for today shows up in the selected day list',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = await pumpCalendar(tester);
    state.addTask(
      Task(title: 'Drink water', difficulty: 0, sectionId: 'dailies'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Drink water'), findsWidgets);
  });

  testWidgets('Habits stay off the month until that filter is turned on',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = await pumpCalendar(tester);
    state.addTask(
      Task(title: 'Drink water', difficulty: 0, sectionId: 'dailies'),
    );
    state.addTask(Task(title: 'Read', difficulty: 0, sectionId: 'habits'));
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsNothing);
    expect(find.text('Drink water'), findsWidgets);

    await tester.tap(find.widgetWithText(FilterChip, 'Habits'));
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsWidgets);
  });

  testWidgets('a To-Do appears on its due date when that day is opened',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final dueDay = now.day == 1 ? 2 : 1;

    final state = await pumpCalendar(tester);
    state.addTask(
      Task(
        title: 'File taxes',
        difficulty: 2,
        sectionId: 'todos',
        dueDate: DateTime(now.year, now.month, dueDay),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('$dueDay').first);
    await tester.pumpAndSettle();

    expect(find.text('File taxes'), findsWidgets);
  });

  testWidgets('day cells show tasks as type boxes', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = await pumpCalendar(tester);
    state.addTask(
      Task(title: 'Water plants', difficulty: 0, sectionId: 'dailies'),
    );
    state.addTask(Task(title: 'Read', difficulty: 0, sectionId: 'habits'));
    state.addTask(
      Task(
        title: 'Pay rent',
        difficulty: 1,
        sectionId: 'todos',
        dueDate: Calendar.dateOnly(DateTime.now()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Water plants'), findsWidgets);
    expect(find.text('Pay rent'), findsWidgets);
    expect(find.text('1 habit'), findsNothing);
    expect(
      tester.getTopLeft(find.text('To-Dos').at(1)).dy,
      lessThan(tester.getTopLeft(find.text('Dailies').at(1)).dy),
    );
  });

  testWidgets('completing a Daily from the day list shows the payout',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = await pumpCalendar(tester);
    state.addTask(
      Task(title: 'Drink water', difficulty: 0, sectionId: 'dailies'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Complete').first);
    await tester.pumpAndSettle();

    expect(state.tasks.first.isDone, isTrue);
    expect(find.byKey(const ValueKey('task-payout')), findsOneWidget);
    expect(find.text('+25 XP'), findsOneWidget);
  });
}
