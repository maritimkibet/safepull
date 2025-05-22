import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MpesaPaymentPage extends StatefulWidget {
  const MpesaPaymentPage({super.key});

  @override
  State<MpesaPaymentPage> createState() => _MpesaPaymentPageState();
}

class _MpesaPaymentPageState extends State<MpesaPaymentPage> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  bool _loading = false;
  String _response = '';

  Future<void> initiateMpesaPayment() async {
    final phone = _phoneController.text.trim();
    final amount = _amountController.text.trim();

    if (phone.isEmpty || amount.isEmpty) {
      setState(() {
        _response = 'Enter both phone number and amount';
      });
      return;
    }

    setState(() {
      _loading = true;
      _response = '';
    });

    final url = Uri.parse('https://<your-cloud-function-url>/initiateMpesa');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: '{"phone": "$phone", "amount": $amount}',
      );

      setState(() {
        _response = res.statusCode == 200
            ? 'Payment prompt sent to $phone'
            : 'Failed: ${res.body}';
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
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
      appBar: AppBar(title: const Text('M-Pesa Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (2547XXXXXXXX)',
              ),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : initiateMpesaPayment,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Pay with M-Pesa'),
            ),
            const SizedBox(height: 20),
            Text(_response, style: const TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
