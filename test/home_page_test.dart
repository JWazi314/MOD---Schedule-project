import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quest_tracker/app.dart';
import 'package:quest_tracker/game/calendar.dart';
import 'package:quest_tracker/game/task_value.dart';
import 'package:quest_tracker/models/checklist_item.dart';
import 'package:quest_tracker/models/task.dart';
import 'package:quest_tracker/models/task_type.dart';
import 'package:quest_tracker/pages/home_page.dart';
import 'package:quest_tracker/state/game_state.dart';
import 'package:quest_tracker/theme.dart';
import 'package:quest_tracker/widgets/quest_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps a page in the Provider and theme the real app supplies.
Widget wrapPage(GameState gameState, Widget child) {
  return ChangeNotifierProvider<GameState>.value(
    value: gameState,
    child: MaterialApp(theme: AppTheme.dark(), home: child),
  );
}

/// Gives the board room for all of its columns at once.
void useWideWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<GameState> loadedState({bool withMod = true}) async {
  final state = GameState();
  await state.load();

  if (withMod) {
    state.createMod(name: 'Pip', appearanceId: 'wanderer');
    state.takeMessages();
  }

  return state;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TaskValue.nextRoll = () => 0.5;
  });

  tearDown(TaskValue.resetRoll);

  testWidgets('the quest board shows sections and their tasks', (tester) async {
    final gameState = await loadedState();
    gameState.addTask(
      Task(title: 'Workout', difficulty: 1, sectionId: 'dailies'),
    );

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('Task Sections'), findsOneWidget);
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Dailies'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
  });

  testWidgets('an empty section explains itself in its own terms',
      (tester) async {
    final gameState = await loadedState();

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    expect(find.textContaining('No habits here yet'), findsOneWidget);
    expect(find.textContaining('No dailies here yet'), findsOneWidget);
  });

  testWidgets('the app bar switches to the shop', (tester) async {
    final gameState = await loadedState();

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();

    expect(find.text('Reward Shop'), findsOneWidget);
    expect(find.text('Cheat Meal'), findsOneWidget);
  });

  testWidgets('the app bar switches to the calendar', (tester) async {
    final gameState = await loadedState();

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Calendar'));
    await tester.pumpAndSettle();

    expect(find.text(Calendar.monthTitle(DateTime.now())), findsOneWidget);
    expect(find.text('Habits'), findsOneWidget);
  });

  testWidgets('the Mod hub can switch to the adventure tab', (tester) async {
    final gameState = await loadedState();

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mod'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('mod-hub-adventure')));
    await tester.pumpAndSettle();

    expect(find.text('Send out'), findsOneWidget);
    expect(find.text('Recall'), findsNothing);
  });

  testWidgets('the app bar switches to the Mod page', (tester) async {
    final gameState = await loadedState();

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mod'));
    await tester.pumpAndSettle();

    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Might'), findsOneWidget);
    expect(find.byKey(const ValueKey('mod-hub-adventure')), findsOneWidget);
    expect(find.byKey(const ValueKey('mod-hub-stats')), findsOneWidget);
  });

  testWidgets('completing a Daily from the board pays out', (tester) async {
    final gameState = await loadedState();
    gameState.addTask(
      Task(title: 'Workout', difficulty: 1, sectionId: 'dailies'),
    );

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await tester.pumpAndSettle();

    expect(gameState.tasks.first.isDone, isTrue);
    expect(gameState.gold, greaterThan(0));
    expect(find.byKey(const ValueKey('task-payout')), findsOneWidget);
    expect(find.textContaining('XP'), findsOneWidget);
  });

  testWidgets('a Habit gets plus and minus instead of a checkbox',
      (tester) async {
    final gameState = await loadedState();
    gameState.addTask(
      Task(
        title: 'Read',
        difficulty: 1,
        sectionId: 'habits',
        isPositive: true,
        isNegative: true,
      ),
    );

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
    expect(find.byTooltip('I did this'), findsOneWidget);
    expect(find.byTooltip('I slipped up'), findsOneWidget);

    await tester.tap(find.byTooltip('I did this'));
    await tester.pumpAndSettle();

    expect(gameState.tasks.first.upCount, 1);
    expect(gameState.tasks.first.isDone, isFalse);
    expect(gameState.gold, greaterThan(0));
  });

  testWidgets('the Habit minus sits to the left of the plus', (tester) async {
    final gameState = await loadedState();
    gameState.addTask(
      Task(
        title: 'Read',
        difficulty: 1,
        sectionId: 'habits',
        isPositive: true,
        isNegative: true,
      ),
    );

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    final minus = tester.getCenter(find.byTooltip('I slipped up'));
    final title = tester.getCenter(find.text('Read'));
    final plus = tester.getCenter(find.byTooltip('I did this'));

    expect(minus.dx, lessThan(title.dx));
    expect(title.dx, lessThan(plus.dx));
    expect(
      (title.dx - minus.dx).abs(),
      closeTo((plus.dx - title.dx).abs(), 12),
    );
  });

  testWidgets('a Daily shows its streak once it has one', (tester) async {
    final gameState = await loadedState();

    final task = Task(title: 'Workout', difficulty: 1, sectionId: 'dailies');
    task.streak = 3;
    gameState.addTask(task);

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('3 day streak'), findsOneWidget);
  });

  testWidgets('the editor offers the fields for the section it opens from',
      (tester) async {
    final gameState = await loadedState();

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add Habit'));
    await tester.pumpAndSettle();

    expect(find.text('Add Habit'), findsWidgets);
    expect(find.text('Directions'), findsOneWidget);
    expect(find.text('Days Repeated'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'Read');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();

    expect(gameState.tasks, hasLength(1));
    expect(gameState.tasks.first.sectionId, 'habits');
  });

  testWidgets('a Daily is scheduled by weekday', (tester) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gameState = await loadedState();

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add Daily'));
    await tester.pumpAndSettle();

    expect(find.text('Days Repeated'), findsOneWidget);
    expect(find.text('Directions'), findsNothing);
    expect(find.text('Due Date'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'Stretch');
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'W'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'W'));
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();

    expect(gameState.tasks.first.repeatDays, [2]);
  });

  testWidgets('a To-Do offers an optional due date', (tester) async {
    // The default test window is too narrow to reach the third column.
    useWideWindow(tester);

    final gameState = await loadedState();

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add To-Do'));
    await tester.pumpAndSettle();

    expect(find.text('Due Date'), findsOneWidget);
    expect(find.text('No due date'), findsOneWidget);
    expect(find.text('Days Repeated'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'File taxes');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();

    expect(gameState.tasks.first.sectionId, 'todos');
    expect(gameState.tasks.first.dueDate, isNull);
    expect(gameState.tasks.first.description, '');
  });

  testWidgets('a task can be given a description', (tester) async {
    final gameState = await loadedState();

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add Daily'));
    await tester.pumpAndSettle();

    expect(find.text('Description'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Stretch');
    await tester.enterText(
      find.byKey(const ValueKey('task-description')),
      'Hold each pose for 20 seconds.',
    );
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();

    expect(gameState.tasks.first.description, 'Hold each pose for 20 seconds.');
    expect(find.text('Hold each pose for 20 seconds.'), findsOneWidget);
  });

  testWidgets('finishing a Daily strikes it through and shows the streak',
      (tester) async {
    final gameState = await loadedState();
    gameState.addTask(
      Task(title: 'Workout', difficulty: 1, sectionId: 'dailies'),
    );

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('1 day streak'), findsNothing);

    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(find.text('1 day streak'), findsOneWidget);

    final title = tester.widget<Text>(find.text('Workout'));
    expect(title.style!.decoration, TextDecoration.lineThrough);
  });

  testWidgets('a Daily has no skip button on the card', (tester) async {
    final gameState = await loadedState();
    gameState.addTask(
      Task(title: 'Workout', difficulty: 1, sectionId: 'dailies'),
    );

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Skip today (3 left)'), findsNothing);
    expect(find.byIcon(Icons.skip_next), findsNothing);
  });

  testWidgets('a column offers a group inside its menu', (tester) async {
    final gameState = await loadedState();

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Section Options').at(1));
    await tester.pumpAndSettle();

    expect(find.text('Add group'), findsOneWidget);
  });

  testWidgets('grips stay hidden until arrange is turned on', (tester) async {
    final gameState = await loadedState();
    gameState.addTask(
      Task(title: 'Workout', difficulty: 1, sectionId: 'dailies'),
    );

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.drag_indicator), findsNothing);

    await tester.tap(find.byTooltip('Section Options').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arrange tasks'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.drag_indicator), findsWidgets);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.drag_indicator), findsNothing);
  });

  testWidgets('adding a section asks what kind it is', (tester) async {
    final gameState = await loadedState();

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add Section'));
    await tester.pumpAndSettle();

    expect(find.text('What goes in here'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Errands');
    await tester.tap(find.text('To-Dos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();

    expect(gameState.sections, hasLength(4));
    expect(gameState.sections.last.name, 'Errands');
    expect(gameState.sections.last.type, TaskType.todo);
  });

  testWidgets('the app bar survives a narrow window without overflowing',
      (tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gameState = await loadedState();

    await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Mod'), findsOneWidget);
  });

  group('task parts', () {
    Task withParts(int count) {
      return Task(
        title: 'Clean the kitchen',
        difficulty: 1,
        sectionId: 'dailies',
        checklist: [
          for (var i = 0; i < count; i++)
            ChecklistItem(id: 'p$i', title: 'Step $i'),
        ],
      );
    }

    testWidgets('are hidden until the card is opened', (tester) async {
      final gameState = await loadedState();
      gameState.addTask(withParts(2));

      await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('0/2'), findsOneWidget);
      expect(find.text('Step 0'), findsNothing);

      await tester.tap(find.byTooltip('Show parts'));
      await tester.pumpAndSettle();

      expect(find.text('Step 0'), findsOneWidget);
      expect(find.text('Step 1'), findsOneWidget);

      await tester.tap(find.byTooltip('Hide parts'));
      await tester.pumpAndSettle();

      expect(find.text('Step 0'), findsNothing);
    });

    testWidgets('a tap on the arrow opens parts without finishing',
        (tester) async {
      final gameState = await loadedState();
      gameState.addTask(withParts(2));

      await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      await tester.tap(find.byTooltip('Show parts'));
      await tester.pumpAndSettle();

      expect(find.text('Step 0'), findsOneWidget);
      expect(gameState.tasks.first.isDone, isFalse);
    });

    testWidgets('holding the arrow finishes the whole task', (tester) async {
      final gameState = await loadedState();
      gameState.addTask(withParts(2));

      await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byTooltip('Show parts')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 950));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(gameState.tasks.first.isDone, isTrue);
      expect(gameState.tasks.first.completedParts, 2);
    });

    testWidgets('a task without parts has nothing to open', (tester) async {
      final gameState = await loadedState();
      gameState.addTask(
        Task(title: 'Workout', difficulty: 1, sectionId: 'dailies'),
      );

      await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Show parts'), findsNothing);
      expect(find.byIcon(Icons.checklist_rtl), findsNothing);
    });

    testWidgets('ticking the last one finishes the task', (tester) async {
      final gameState = await loadedState();
      gameState.addTask(withParts(2));

      await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Show parts'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Step 0'));
      await tester.pumpAndSettle();

      expect(find.text('1/2'), findsOneWidget);
      expect(gameState.tasks.first.isDone, isFalse);

      await tester.tap(find.text('Step 1'));
      await tester.pumpAndSettle();

      expect(gameState.tasks.first.isDone, isTrue);
      expect(find.text('2/2'), findsOneWidget);
    });

    testWidgets('can be added to a Daily from the editor', (tester) async {
      final gameState = await loadedState();

      await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add Daily'));
      await tester.pumpAndSettle();

      expect(find.text('Parts'), findsOneWidget);

      // The parts editor sits below the fold of a short dialog.
      await tester.ensureVisible(find.text('Add part'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add part'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Tidy up');
      await tester.enterText(find.byType(TextFormField).last, 'Dishes');
      await tester.tap(find.text('Add').last);
      await tester.pumpAndSettle();

      final task = gameState.tasks.first;

      expect(task.title, 'Tidy up');
      expect(task.checklist, hasLength(1));
      expect(task.checklist.first.title, 'Dishes');
    });

    testWidgets('a Habit is not offered any', (tester) async {
      final gameState = await loadedState();

      await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add Habit'));
      await tester.pumpAndSettle();

      expect(find.text('Parts'), findsNothing);
      expect(find.text('Add part'), findsNothing);
    });
  });

  group('a finished card', () {
    Color borderOf(WidgetTester tester, String title) {
      final card = tester.widget<Card>(
        find
            .ancestor(of: find.text(title), matching: find.byType(Card))
            .first,
      );

      return (card.shape as RoundedRectangleBorder).side.color;
    }

    testWidgets('drops its difficulty colour for a drab grey', (tester) async {
      final gameState = await loadedState();
      gameState.addTask(
        Task(title: 'Workout', difficulty: 2, sectionId: 'dailies'),
      );

      await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
      await tester.pumpAndSettle();

      final before = borderOf(tester, 'Workout');

      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();

      final after = borderOf(tester, 'Workout');

      expect(after, isNot(before));
      expect(
        HSLColor.fromColor(after).saturation,
        lessThan(HSLColor.fromColor(before).saturation),
      );
      expect(HSLColor.fromColor(after).saturation, lessThan(0.3));
    });

    testWidgets('looks the same whatever difficulty it was', (tester) async {
      final gameState = await loadedState();
      gameState.addTask(
        Task(title: 'Easy one', difficulty: 0, sectionId: 'dailies'),
      );
      gameState.addTask(
        Task(title: 'Hard one', difficulty: 2, sectionId: 'dailies'),
      );

      await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
      await tester.pumpAndSettle();

      for (final checkbox in [0, 0]) {
        await tester.tap(
          find.byIcon(Icons.check_box_outline_blank).at(checkbox),
        );
        await tester.pumpAndSettle();
      }

      expect(borderOf(tester, 'Easy one'), borderOf(tester, 'Hard one'));
    });

    testWidgets('is faded back so the eye skips it', (tester) async {
      final gameState = await loadedState();
      gameState.addTask(
        Task(title: 'Workout', difficulty: 1, sectionId: 'dailies'),
      );

      await tester.pumpWidget(wrapPage(gameState, const QuestHomePage()));
      await tester.pumpAndSettle();

      Opacity fadeOf() {
        return tester.widget<Opacity>(
          find
              .descendant(
                of: find.byType(QuestCard),
                matching: find.byType(Opacity),
              )
              .first,
        );
      }

      expect(fadeOf().opacity, 1);

      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();

      expect(fadeOf().opacity, lessThan(1));
    });
  });

  group('first run', () {
    testWidgets('a new player is sent to Mod creation', (tester) async {
      await tester.pumpWidget(const ModApp());
      await tester.pumpAndSettle();

      expect(find.text('Create Your Mod'), findsOneWidget);
      expect(find.text('Task Sections'), findsNothing);
    });

    testWidgets('naming a Mod opens the quest board', (tester) async {
      await tester.pumpWidget(const ModApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Pip');
      await tester.ensureVisible(find.text('Begin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();

      expect(find.text('Task Sections'), findsOneWidget);
    });

    testWidgets('a Mod needs a name', (tester) async {
      await tester.pumpWidget(const ModApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Begin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();

      expect(find.text('give your Mod a name'), findsOneWidget);
      expect(find.text('Create Your Mod'), findsOneWidget);
    });

    testWidgets('an existing save skips creation', (tester) async {
      final gameState = await loadedState();
      await gameState.pendingSave;

      await tester.pumpWidget(const ModApp());
      await tester.pumpAndSettle();

      expect(find.text('Create Your Mod'), findsNothing);
      expect(find.text('Task Sections'), findsOneWidget);
    });
  });
}
