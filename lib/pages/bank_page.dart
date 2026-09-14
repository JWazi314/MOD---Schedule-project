import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bank_account.dart';
import '../services/bank_service.dart';
import '../theme.dart';

class BankPage extends StatefulWidget {
  const BankPage({super.key});

  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  final TextEditingController _apiUrlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  BankSnapshot? _snapshot;
  Set<String> _seenIds = {};
  Set<String> _newIds = {};
  bool _hasLoadedOnce = false;
  String? _error;
  bool _loading = true;
  bool _usingDemo = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndFetch();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _apiUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _apiUrlController.text = prefs.getString('bankApiUrl') ?? '';
    _tokenController.text = prefs.getString('bankApiToken') ?? '';
    await _fetchSnapshot(isFirstLoad: true);
  }

  BankService _currentService() {
    final apiUrl = _apiUrlController.text.trim();
    if (apiUrl.isEmpty) {
      return DemoBankService.instance;
    }

    return HttpBankService(
      apiUrl: apiUrl,
      accessToken: _tokenController.text,
    );
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (_apiUrlController.text.trim().isEmpty) {
      return;
    }

    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _fetchSnapshot();
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bankApiUrl', _apiUrlController.text.trim());
    await prefs.setString('bankApiToken', _tokenController.text.trim());
    _seenIds = {};
    _hasLoadedOnce = false;
    await _fetchSnapshot(isFirstLoad: true);
  }

  Future<void> _fetchSnapshot({bool isFirstLoad = false}) async {
    final usingDemo = _apiUrlController.text.trim().isEmpty;

    try {
      final snapshot = await _currentService().fetchSnapshot();
      if (!mounted) {
        return;
      }

      final currentIds = snapshot.transactions.map((tx) => tx.id).toSet();
      final newIds = !_hasLoadedOnce || isFirstLoad
          ? <String>{}
          : currentIds.difference(_seenIds);

      setState(() {
        _snapshot = snapshot;
        _newIds = newIds;
        _seenIds = currentIds;
        _hasLoadedOnce = true;
        _error = null;
        _loading = false;
        _usingDemo = usingDemo;
      });
      _startPolling();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
        _usingDemo = usingDemo;
      });
    }
  }

  Future<void> _simulateDeposit() async {
    DemoBankService.instance.simulateDeposit();
    await _fetchSnapshot();
  }

  Future<void> _simulateSpend() async {
    DemoBankService.instance.simulateSpend();
    await _fetchSnapshot();
  }

  String _formatMoney(double amount, {required String currency}) {
    final symbol = currency == 'USD' ? '\$' : '$currency ';
    return '$symbol${amount.abs().toStringAsFixed(2)}';
  }

  String _formatSignedMoney(double amount, {required String currency}) {
    final prefix = amount >= 0 ? '+' : '-';
    return '$prefix${_formatMoney(amount, currency: currency)}';
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final currency = snapshot?.currency ?? 'USD';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance, color: Colors.green, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'Bank',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _usingDemo
                    ? 'Demo mode. Connect a JSON bank API below, or simulate money moving in and out.'
                    : 'Live API. New deposits flash green and withdrawals flash red.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Bank API connection'),
                children: [
                  TextField(
                    controller: _apiUrlController,
                    decoration: const InputDecoration(
                      labelText: 'API URL',
                      hintText: 'https://your-server.com/bank',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _tokenController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Optional access token',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text('Save & Refresh'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Expected JSON: { "balance": 100.00, "currency": "USD", '
                    '"transactions": [{ "id": "1", "amount": 50, '
                    '"type": "credit", "description": "Paycheck", '
                    '"date": "2026-09-02T12:00:00Z" }] }',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null && snapshot == null)
                Card(
                  color: AppTheme.surface,
                  shape: AppTheme.cardShape(sideColor: Colors.red),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                )
              else if (snapshot != null) ...[
                Card(
                  color: AppTheme.surface,
                  shape: AppTheme.cardShape(
                    sideColor: Colors.green,
                    width: 1.6,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Balance',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatMoney(snapshot.balance, currency: currency),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_usingDemo) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _simulateDeposit,
                          child: const Text('Money in'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _simulateSpend,
                          child: const Text('Money out'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 18),
                const Text(
                  'Transactions',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: snapshot.transactions.isEmpty
                      ? const Text(
                          'No transactions yet.',
                          style: TextStyle(color: Colors.white54),
                        )
                      : ListView.builder(
                          itemCount: snapshot.transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = snapshot.transactions[index];
                            return _TransactionRow(
                              key: ValueKey(transaction.id),
                              transaction: transaction,
                              isNew: _newIds.contains(transaction.id),
                              amountText: _formatSignedMoney(
                                transaction.amount,
                                currency: currency,
                              ),
                              dateText: _formatDate(transaction.date),
                            );
                          },
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionRow extends StatefulWidget {
  final BankTransaction transaction;
  final bool isNew;
  final String amountText;
  final String dateText;

  const _TransactionRow({
    super.key,
    required this.transaction,
    required this.isNew,
    required this.amountText,
    required this.dateText,
  });

  @override
  State<_TransactionRow> createState() => _TransactionRowState();
}

class _TransactionRowState extends State<_TransactionRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _flash;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _flash = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isNew) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.transaction.isCredit;
    final accent = isCredit ? Colors.greenAccent : Colors.redAccent;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final flashColor = accent.withValues(alpha: _flash.value * 0.35);

        return Transform.scale(
          scale: widget.isNew ? _scale.value : 1,
          child: Card(
            color: Color.alphaBlend(flashColor, AppTheme.surface),
            margin: const EdgeInsets.only(bottom: 10),
            shape: AppTheme.cardShape(
              sideColor: Color.alphaBlend(
                accent.withValues(alpha: widget.isNew ? 0.9 : 0.55),
                AppTheme.border,
              ),
              width: widget.isNew ? 2.2 : 1.4,
            ),
            child: child,
          ),
        );
      },
      child: ListTile(
        leading: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: accent,
        ),
        title: Text(
          widget.transaction.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(widget.dateText),
        trailing: Text(
          widget.amountText,
          style: TextStyle(
            color: accent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
