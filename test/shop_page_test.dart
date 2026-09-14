import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quest_tracker/pages/shop_page.dart';
import 'package:quest_tracker/state/game_state.dart';
import 'package:quest_tracker/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameState> pumpShop(WidgetTester tester, {int gold = 0}) async {
  final gameState = GameState();
  await gameState.load();
  gameState.gold = gold;

  await tester.pumpWidget(
    ChangeNotifierProvider<GameState>.value(
      value: gameState,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: ShopPage()),
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

  testWidgets('the default rewards are listed with their prices',
      (tester) async {
    await pumpShop(tester);

    expect(find.text('Cheat Meal'), findsOneWidget);
    expect(find.text('100 gold'), findsOneWidget);
    expect(find.text('Gaming Night'), findsOneWidget);
    expect(find.text('Energy Drink'), findsOneWidget);
    expect(find.text('Skip Token'), findsOneWidget);
  });

  testWidgets('a reward can be added through the dialog', (tester) async {
    final gameState = await pumpShop(tester);

    await tester.tap(find.byTooltip('Add Reward'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reward Name'),
      'Long Bath',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Soak for an hour.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cost in gold'),
      '40',
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    final added = gameState.shopItems.last;
    expect(added.name, 'Long Bath');
    expect(added.cost, 40);
    await tester.scrollUntilVisible(find.text('Long Bath'), 80);
    expect(find.text('Long Bath'), findsOneWidget);
  });

  testWidgets('a duplicate reward name is rejected', (tester) async {
    final gameState = await pumpShop(tester);

    await tester.tap(find.byTooltip('Add Reward'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reward Name'),
      'Cheat Meal',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('that reward already exists'), findsOneWidget);
    expect(gameState.discoveredShopItems, hasLength(4));
  });

  testWidgets('a non-numeric price is rejected', (tester) async {
    await pumpShop(tester);

    await tester.tap(find.byTooltip('Add Reward'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reward Name'),
      'Nap',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cost in gold'),
      'free',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('enter a whole number'), findsOneWidget);
  });

  testWidgets('a reward can be edited from its menu', (tester) async {
    final gameState = await pumpShop(tester);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reward Name'),
      'Bigger Cheat Meal',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(gameState.shopItemById('cheat_meal')!.name, 'Bigger Cheat Meal');
    expect(find.text('Bigger Cheat Meal'), findsOneWidget);
  });

  testWidgets('a reward can be deleted after confirming', (tester) async {
    final gameState = await pumpShop(tester);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Cheat Meal?'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(gameState.shopItemById('cheat_meal'), isNull);
    expect(find.text('Cheat Meal'), findsNothing);
  });

  testWidgets('cancelling the delete dialog keeps the reward', (tester) async {
    final gameState = await pumpShop(tester);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(gameState.shopItemById('cheat_meal'), isNotNull);
  });

  testWidgets('buying is disabled until there is enough gold', (tester) async {
    final gameState = await pumpShop(tester, gold: 50);

    final affordable = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '30 gold'),
    );
    final tooExpensive = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '100 gold'),
    );

    expect(affordable.onPressed, isNotNull);
    expect(tooExpensive.onPressed, isNull);

    await tester.tap(find.widgetWithText(ElevatedButton, '30 gold'));
    await tester.pumpAndSettle();

    expect(gameState.gold, 20);
    expect(gameState.inventory, ['energy_drink']);
  });

  testWidgets('an empty shop explains what to do', (tester) async {
    final gameState = await pumpShop(tester);

    for (final item in List.of(gameState.shopItems)) {
      gameState.deleteShopItem(item);
    }
    await tester.pumpAndSettle();

    expect(find.text('Your shop is empty.'), findsOneWidget);
  });
}
