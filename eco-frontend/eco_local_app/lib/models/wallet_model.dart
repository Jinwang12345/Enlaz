import 'transaction_model.dart';

class WalletModel {
  final double balance;
  final String currency;
  final List<TransactionModel> transactions;

  WalletModel({
    required this.balance,
    required this.currency,
    required this.transactions,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] ?? 'USD',
      transactions: (json['transactions'] as List?)
              ?.map((t) => TransactionModel.fromJson(t))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'currency': currency,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }
}
