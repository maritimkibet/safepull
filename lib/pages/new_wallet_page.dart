import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/wallet_service.dart';
import '../services/mpesa_service.dart';
import '../models/transaction_model.dart';

class NewWalletPage extends StatefulWidget {
  const NewWalletPage({super.key});

  @override
  State<NewWalletPage> createState() => _NewWalletPageState();
}

class _NewWalletPageState extends State<NewWalletPage> {
  final WalletService _walletService = WalletService();
  final MpesaService _mpesaService = MpesaService(
    backendUrl: 'http://localhost:3000', // Change to your backend URL
  );

  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _deposit() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 10) {
      _showError('Minimum deposit is KES 10');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check deposit limit
      final canDeposit = await _walletService.canDeposit(
        userProvider.user!.uid,
        amount,
      );

      if (!canDeposit) {
        _showError('Daily deposit limit exceeded');
        setState(() => _isLoading = false);
        return;
      }

      // Initiate M-Pesa STK Push
      final response = await _mpesaService.initiateDeposit(
        phoneNumber: userProvider.user!.phoneNumber,
        amount: amount,
      );

      final checkoutRequestId = response['CheckoutRequestID'];

      // Create pending transaction
      await _walletService.createDepositTransaction(
        userProvider.user!.uid,
        amount,
        checkoutRequestId,
      );

      _showSuccess('M-Pesa prompt sent! Check your phone.');
      _amountController.clear();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _withdraw() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 100) {
      _showError('Minimum withdrawal is KES 100');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check withdrawal limit and balance
      final canWithdraw = await _walletService.canWithdraw(
        userProvider.user!.uid,
        amount,
      );

      if (!canWithdraw) {
        _showError('Cannot withdraw. Check balance and daily limit.');
        setState(() => _isLoading = false);
        return;
      }

      // Create withdrawal transaction (deducts from balance)
      await _walletService.createWithdrawalTransaction(
        userProvider.user!.uid,
        amount,
      );

      // Initiate M-Pesa B2C
      await _mpesaService.initiateWithdrawal(
        phoneNumber: userProvider.user!.phoneNumber,
        amount: amount,
      );

      _showSuccess('Withdrawal initiated! You will receive KES ${amount.toStringAsFixed(2)} shortly.');
      _amountController.clear();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Wallet')),
            body: const Center(child: Text('Please sign in')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0B1321),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1C2942),
            title: const Text('Wallet'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Balance Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1C2942), Color(0xFF2A4365)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Available Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'KES ${user.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Amount Input
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Amount (KES)',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.money, color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Amount Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickAmountButton(
                      amount: 100,
                      onTap: () => _amountController.text = '100',
                    ),
                    _QuickAmountButton(
                      amount: 500,
                      onTap: () => _amountController.text = '500',
                    ),
                    _QuickAmountButton(
                      amount: 1000,
                      onTap: () => _amountController.text = '1000',
                    ),
                    _QuickAmountButton(
                      amount: 5000,
                      onTap: () => _amountController.text = '5000',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Deposit Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _deposit,
                    icon: const Icon(Icons.add_circle),
                    label: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('DEPOSIT', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Withdraw Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _withdraw,
                    icon: const Icon(Icons.remove_circle),
                    label: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('WITHDRAW', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Limits Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2942),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Limits',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _LimitRow(
                        label: 'Deposit Limit',
                        value: 'KES ${user.dailyDepositLimit.toStringAsFixed(0)}',
                      ),
                      _LimitRow(
                        label: 'Withdrawal Limit',
                        value: 'KES ${user.dailyWithdrawalLimit.toStringAsFixed(0)}',
                      ),
                      _LimitRow(
                        label: 'Min Deposit',
                        value: 'KES 10',
                      ),
                      _LimitRow(
                        label: 'Min Withdrawal',
                        value: 'KES 100',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Transactions
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<TransactionModel>>(
                  stream: _walletService.watchTransactions(user.uid, limit: 10),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final transactions = snapshot.data!;

                    if (transactions.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return _TransactionTile(transaction: transaction);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

class _QuickAmountButton extends StatelessWidget {
  final int amount;
  final VoidCallback onTap;

  const _QuickAmountButton({required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2942),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          '$amount',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  final String label;
  final String value;

  const _LimitRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionTile({required this.transaction});

  IconData _getIcon() {
    switch (transaction.type) {
      case TransactionType.deposit:
        return Icons.add_circle;
      case TransactionType.withdrawal:
        return Icons.remove_circle;
      case TransactionType.bet:
        return Icons.casino;
      case TransactionType.win:
        return Icons.emoji_events;
      case TransactionType.refund:
        return Icons.refresh;
      case TransactionType.referralBonus:
        return Icons.card_giftcard;
    }
  }

  Color _getColor() {
    switch (transaction.type) {
      case TransactionType.deposit:
      case TransactionType.win:
      case TransactionType.refund:
      case TransactionType.referralBonus:
        return Colors.greenAccent;
      case TransactionType.withdrawal:
      case TransactionType.bet:
        return Colors.redAccent;
    }
  }

  String _getSign() {
    switch (transaction.type) {
      case TransactionType.deposit:
      case TransactionType.win:
      case TransactionType.refund:
      case TransactionType.referralBonus:
        return '+';
      case TransactionType.withdrawal:
      case TransactionType.bet:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2942),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_getIcon(), color: _getColor()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? transaction.type.toString().split('.').last,
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  transaction.createdAt.toString().substring(0, 16),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${_getSign()}KES ${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: _getColor(),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
