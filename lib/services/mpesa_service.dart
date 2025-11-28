import 'dart:convert';
import 'package:http/http.dart' as http;

class MpesaService {
  final String backendUrl;

  MpesaService({required this.backendUrl});

  Future<Map<String, dynamic>> initiateDeposit({
    required String phoneNumber,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/initiateMpesa'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phoneNumber,
          'amount': amount.toInt(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to initiate M-Pesa: ${response.body}');
      }
    } catch (e) {
      throw Exception('M-Pesa request failed: $e');
    }
  }

  Future<Map<String, dynamic>> initiateWithdrawal({
    required String phoneNumber,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/withdrawMpesa'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phoneNumber,
          'amount': amount.toInt(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to initiate withdrawal: ${response.body}');
      }
    } catch (e) {
      throw Exception('Withdrawal request failed: $e');
    }
  }
}
