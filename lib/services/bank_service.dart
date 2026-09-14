import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/bank_account.dart';

abstract class BankService {
  Future<BankSnapshot> fetchSnapshot();
}

class HttpBankService implements BankService {
  final String apiUrl;
  final String? accessToken;
  final http.Client client;

  HttpBankService({
    required this.apiUrl,
    this.accessToken,
    http.Client? client,
  }) : client = client ?? http.Client();

  @override
  Future<BankSnapshot> fetchSnapshot() async {
    final headers = <String, String>{'Accept': 'application/json'};
    final token = accessToken?.trim();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await client.get(Uri.parse(apiUrl), headers: headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Bank API returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Bank API must return a JSON object.');
    }

    return BankSnapshot.fromJson(Map<String, dynamic>.from(decoded));
  }
}

class DemoBankService implements BankService {
  DemoBankService._() {
    _reset();
  }

  static final DemoBankService instance = DemoBankService._();

  late double _balance;
  late List<BankTransaction> _transactions;
  int _nextId = 4;

  void _reset() {
    _balance = 1847.32;
    _transactions = [
      BankTransaction(
        id: 'demo-1',
        description: 'Paycheck',
        amount: 1200.00,
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      BankTransaction(
        id: 'demo-2',
        description: 'Groceries',
        amount: -64.18,
        date: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      ),
      BankTransaction(
        id: 'demo-3',
        description: 'Coffee',
        amount: -5.65,
        date: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
    _nextId = 4;
  }

  void simulateDeposit({
    double amount = 50,
    String description = 'Deposit',
  }) {
    _balance += amount.abs();
    _transactions.insert(
      0,
      BankTransaction(
        id: 'demo-${_nextId++}',
        description: description,
        amount: amount.abs(),
        date: DateTime.now(),
      ),
    );
  }

  void simulateSpend({
    double amount = 12.50,
    String description = 'Purchase',
  }) {
    _balance -= amount.abs();
    _transactions.insert(
      0,
      BankTransaction(
        id: 'demo-${_nextId++}',
        description: description,
        amount: -amount.abs(),
        date: DateTime.now(),
      ),
    );
  }

  @override
  Future<BankSnapshot> fetchSnapshot() async {
    return BankSnapshot(
      balance: _balance,
      currency: 'USD',
      transactions: List<BankTransaction>.from(_transactions),
    );
  }
}
