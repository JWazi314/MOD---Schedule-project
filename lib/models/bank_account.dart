class BankTransaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;

  const BankTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
  });

  bool get isCredit => amount > 0;

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    final rawAmount = (json['amount'] as num?)?.toDouble() ?? 0;
    final type = json['type']?.toString().toLowerCase().trim();
    double amount = rawAmount;

    if (type == 'debit' ||
        type == 'withdrawal' ||
        type == 'expense' ||
        type == 'out') {
      amount = -rawAmount.abs();
    } else if (type == 'credit' ||
        type == 'deposit' ||
        type == 'income' ||
        type == 'in') {
      amount = rawAmount.abs();
    }

    return BankTransaction(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? 'Transaction',
      amount: amount,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class BankSnapshot {
  final double balance;
  final String currency;
  final List<BankTransaction> transactions;

  const BankSnapshot({
    required this.balance,
    required this.currency,
    required this.transactions,
  });

  factory BankSnapshot.fromJson(Map<String, dynamic> json) {
    final rawTransactions = json['transactions'];
    final transactions = <BankTransaction>[];

    if (rawTransactions is List) {
      for (final item in rawTransactions) {
        if (item is Map<String, dynamic>) {
          transactions.add(BankTransaction.fromJson(item));
        } else if (item is Map) {
          transactions.add(
            BankTransaction.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));

    return BankSnapshot(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      transactions: transactions,
    );
  }
}
