import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/wallet_model.dart';
import '../../models/transaction_model.dart';

class WalletService {
  final String baseUrl = 'http://localhost:8005';

  Future<WalletModel?> fetchWallet(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return WalletModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<double?> topUp(String token, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet/topup'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['new_balance'] as num).toDouble();
    }
    return null;
  }

  Future<double?> sendMoney(String token, String recipientEmail, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet/send'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'recipient_email': recipientEmail,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['new_balance'] as num).toDouble();
    }
    return null;
  }

  Future<double?> pay(String token, double amount, String merchant) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet/pay'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'amount': amount,
        'merchant': merchant,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['new_balance'] as num).toDouble();
    }
    return null;
  }

  Future<List<TransactionModel>> fetchTransactions(String token, {int limit = 20, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet/transactions?limit=$limit&offset=$offset'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((t) => TransactionModel.fromJson(t)).toList();
    }
    return [];
  }
}
