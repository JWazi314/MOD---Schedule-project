import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quest_tracker/models/shop_item.dart';
import 'package:quest_tracker/models/task.dart';
import 'package:quest_tracker/pages/inventory_page.dart';
import 'package:quest_tracker/state/game_state.dart';
import 'package:quest_tracker/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameState> pumpInventory(
  WidgetTester tester, {
  bool withToken = true,
}) async {
  tester.view.physicalSize = const Size(1100, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final gameState = GameState();
  await gameState.load();
  gameState.createMod(name: 'Pip', appearanceId: 'wanderer');
  gameState.addTask(
    Task(title: 'Workout', difficulty: 1, sectionId: 'dailies'),
  );
  if (withToken) {
    gameState.gold = 55;
    gameState.buyItem(gameState.shopItemById(ShopItem.skipTokenId)!);
  }
  gameState.takeMessages();

  await tester.pumpWidget(
    ChangeNotifierProvider<GameState>.value(
      value: gameState,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: InventoryPage()),
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

  testWidgets('the paperdoll and bag show even when the bag is empty',
      (tester) async {
    await pumpInventory(tester, withToken: false);

    expect(find.text('Pip'), findsOneWidget);
    expect(find.text('Bags'), findsOneWidget);
    expect(find.byTooltip('Head'), findsOneWidget);
    expect(find.byTooltip('Chest'), findsOneWidget);
    expect(find.textContaining('bag is empty'), findsOneWidget);
  });

  testWidgets('using a Skip Token asks which Daily to skip', (tester) async {
    final gameState = await pumpInventory(tester);

    await tester.tap(find.byKey(const ValueKey('bag-skip_token')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use'));
    await tester.pumpAndSettle();

    expect(find.text('Skip which Daily?'), findsOneWidget);
    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();

    expect(gameState.tasks.first.isSkipped, isTrue);
    expect(gameState.inventory, isEmpty);
  });
}
