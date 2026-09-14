import 'package:flutter_test/flutter_test.dart';
import 'package:quest_tracker/models/bank_account.dart';

void main() {
  test('credits stay positive and debits become negative', () {
    final credit = BankTransaction.fromJson({
      'id': '1',
      'amount': 50,
      'type': 'credit',
      'description': 'Paycheck',
      'date': '2026-09-02T12:00:00Z',
    });
    final debit = BankTransaction.fromJson({
      'id': '2',
      'amount': 12.5,
      'type': 'debit',
      'description': 'Coffee',
      'date': '2026-09-02T13:00:00Z',
    });

    expect(credit.isCredit, isTrue);
    expect(credit.amount, 50);
    expect(debit.isCredit, isFalse);
    expect(debit.amount, -12.5);
  });

  test('BankSnapshot parses balance and newest transactions first', () {
    final snapshot = BankSnapshot.fromJson({
      'balance': 100.5,
      'currency': 'USD',
      'transactions': [
        {
          'id': 'old',
          'amount': 10,
          'type': 'in',
          'description': 'Old',
          'date': '2026-09-01T12:00:00Z',
        },
        {
          'id': 'new',
          'amount': 20,
          'type': 'out',
          'description': 'New',
          'date': '2026-09-02T12:00:00Z',
        },
      ],
    });

    expect(snapshot.balance, 100.5);
    expect(snapshot.transactions.first.id, 'new');
    expect(snapshot.transactions.first.amount, -20);
  });
}
