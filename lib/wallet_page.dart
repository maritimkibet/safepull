import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  bool _loading = false;
  String _message = '';

  final String backendBaseUrl = 'https://07c0-41-90-172-40.ngrok-free.app';

  Future<void> _deposit() async {
    final phone = _phoneController.text.trim();
    final amount = _amountController.text.trim();

    if (phone.isEmpty || amount.isEmpty) {
      setState(() => _message = 'Please enter both phone and amount');
      return;
    }

    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/initiateMpesa'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone, 'amount': amount}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _message = 'Deposit initiated: ${data['ResponseDescription'] ?? 'Check your phone'}';
        });
      } else {
        final err = json.decode(response.body);
        setState(() {
          _message = 'Deposit failed: ${err['error'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Deposit error: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _withdraw() async {
    final phone = _phoneController.text.trim();
    final amount = _amountController.text.trim();

    if (phone.isEmpty || amount.isEmpty) {
      setState(() => _message = 'Please enter both phone and amount');
      return;
    }

    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/withdrawMpesa'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone, 'amount': amount}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _message = 'Withdrawal initiated: ${data['ResponseDescription'] ?? 'Check your phone'}';
        });
      } else {
        final err = json.decode(response.body);
        setState(() {
          _message = 'Withdrawal failed: ${err['error'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Withdrawal error: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (e.g. 2547XXXXXXXX)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (KES)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: _deposit,
                    child: const Text('Deposit'),
                  ),
                  ElevatedButton(
                    onPressed: _withdraw,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Withdraw'),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Text(
              _message,
              style: TextStyle(
                color: _message.toLowerCase().contains('failed') || _message.toLowerCase().contains('error')
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
