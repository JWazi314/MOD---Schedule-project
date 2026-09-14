import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quest_tracker/pages/mod_hub_page.dart';
import 'package:quest_tracker/state/game_state.dart';
import 'package:quest_tracker/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameState> pumpHub(
  WidgetTester tester, {
  ModHubTab tab = ModHubTab.character,
}) async {
  final state = GameState();
  await state.load();
  state.createMod(name: 'Pip', appearanceId: 'wanderer');
  state.takeMessages();

  await tester.pumpWidget(
    ChangeNotifierProvider<GameState>.value(
      value: state,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: ModHubPage(initialTab: tab)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return state;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('the hub opens on the character sheet', (tester) async {
    await pumpHub(tester);

    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Might'), findsOneWidget);
    expect(find.text('Send out'), findsNothing);
  });

  testWidgets('the Adventure tab shows dispatch', (tester) async {
    await pumpHub(tester);

    await tester.tap(find.byKey(const ValueKey('mod-hub-adventure')));
    await tester.pumpAndSettle();

    expect(find.text('Send out'), findsOneWidget);
    expect(find.text('Might'), findsNothing);
  });

  testWidgets('the Stats tab shows the numbers', (tester) async {
    await pumpHub(tester);

    await tester.tap(find.byKey(const ValueKey('mod-hub-stats')));
    await tester.pumpAndSettle();

    expect(find.text('Completion Rate'), findsOneWidget);
    expect(find.text('Might'), findsNothing);
  });

  testWidgets('the adventure strip on the sheet opens that tab', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpHub(tester);

    final strip = find.textContaining('Send Pip out');
    await tester.ensureVisible(strip);
    await tester.tap(strip);
    await tester.pumpAndSettle();

    expect(find.text('Send out'), findsOneWidget);
  });
}
