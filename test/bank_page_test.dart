import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quest_tracker/pages/bank_page.dart';
import 'package:quest_tracker/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('simulated deposit flashes as a green credit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: BankPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Money in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Deposit'), findsOneWidget);
    expect(find.text('+\$50.00'), findsOneWidget);
  });
}
