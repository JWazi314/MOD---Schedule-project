import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quest_tracker/game/progression.dart';
import 'package:quest_tracker/pages/adventure_page.dart';
import 'package:quest_tracker/state/game_state.dart';
import 'package:quest_tracker/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameState> pumpAdventure(WidgetTester tester) async {
  final gameState = GameState();
  await gameState.load();
  gameState.createMod(name: 'Pip', appearanceId: 'wanderer');
  gameState.takeMessages();

  await tester.pumpWidget(
    ChangeNotifierProvider<GameState>.value(
      value: gameState,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: AdventurePage()),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return gameState;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('a Mod at home can be sent out', (tester) async {
    final gameState = await pumpAdventure(tester);

    expect(find.text('Send out'), findsOneWidget);
    expect(find.text('Recall'), findsNothing);
    expect(find.textContaining('Nothing has happened yet'), findsOneWidget);

    await tester.tap(find.text('Send out'));
    await tester.pumpAndSettle();

    expect(gameState.isModOut, isTrue);
    expect(find.text('Recall'), findsOneWidget);
    expect(find.text('Send out'), findsNothing);
    expect(find.text('Pip is out'), findsOneWidget);
  });

  testWidgets('a resting Mod cannot leave', (tester) async {
    final gameState = GameState();
    await gameState.load();
    gameState.createMod(name: 'Pip', appearanceId: 'wanderer');
    gameState.mod!.currentVigor = 0;
    gameState.takeMessages();

    await tester.pumpWidget(
      ChangeNotifierProvider<GameState>.value(
        value: gameState,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: AdventurePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Too worn out to leave'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Too worn out to leave'),
    );
    expect(button.onPressed, isNull);
    expect(gameState.isModOut, isFalse);
  });

  testWidgets('recalling after a trip brings the Mod home', (tester) async {
    final gameState = await pumpAdventure(tester);

    final start = DateTime.now().subtract(const Duration(hours: 6));
    gameState.sendModOnAdventure(now: start);
    gameState.advanceAdventure(now: DateTime.now());
    await tester.pumpAndSettle();

    expect(find.text('Recall'), findsOneWidget);
    expect(gameState.adventure.log, isNotEmpty);

    await tester.tap(find.text('Recall'));
    await tester.pumpAndSettle();

    expect(gameState.isModOut, isFalse);
    expect(find.text('Send out'), findsOneWidget);
    expect(find.textContaining('Pip is home'), findsOneWidget);
  });

  testWidgets('a camped Mod can still be recalled', (tester) async {
    final gameState = await pumpAdventure(tester);

    gameState.mod!.currentVigor = Progression.vigorPerTick - 1;
    gameState.sendModOnAdventure(now: DateTime(2026, 3, 1, 8));
    await tester.pumpAndSettle();

    expect(find.text('Recall'), findsOneWidget);
    expect(find.textContaining('Camped'), findsWidgets);
  });
}
