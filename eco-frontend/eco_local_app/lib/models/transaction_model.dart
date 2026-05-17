class TransactionModel {
  final String id;
  final double amount;
  final String type;
  final String description;
  final String? counterparty;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    this.counterparty,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? json['_id'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] ?? 'unknown',
      description: json['description'] ?? '',
      counterparty: json['counterparty'],
      date: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'description': description,
      'counterparty': counterparty,
      'created_at': date.toIso8601String(),
    };
  }
}
