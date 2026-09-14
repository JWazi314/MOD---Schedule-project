import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_tracker/widgets/mod_portrait.dart';

void main() {
  testWidgets('a portrait paints a pixel Mod', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ModPortrait(appearanceId: 'knight', animate: false),
          ),
        ),
      ),
    );

    expect(find.byType(ModPortrait), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('the idle portrait ticks without overflowing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ModPortrait(appearanceId: 'wanderer', size: 96),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
    expect(find.byType(ModPortrait), findsOneWidget);
  });
}
