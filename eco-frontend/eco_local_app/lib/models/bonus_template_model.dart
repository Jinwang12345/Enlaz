class BonusTemplateModel {
  final String id;
  final String title;
  final double costPrice;
  final double spendingValue;
  final String expirationDate;

  BonusTemplateModel({
    required this.id,
    required this.title,
    required this.costPrice,
    required this.spendingValue,
    required this.expirationDate,
  });

  factory BonusTemplateModel.fromJson(Map<String, dynamic> json) {
    return BonusTemplateModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] as String? ?? 'Bono',
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      spendingValue: (json['spending_value'] as num?)?.toDouble() ?? 0.0,
      expirationDate: json['expiration_date'] as String? ?? '',
    );
  }

  /// Human-readable savings label, e.g. "Ahorro +10€"
  String get savingsLabel {
    final savings = spendingValue - costPrice;
    return 'Ahorro +${savings.toStringAsFixed(0)}€';
  }

  /// Human-readable description, e.g. "Pagas 10€ y consigues 20€"
  String get description =>
      'Pagas ${costPrice.toStringAsFixed(0)}€ y consigues '
      '${spendingValue.toStringAsFixed(0)}€';

  /// Formatted expiration, e.g. "Válido hasta 12 Oct"
  String get formattedExpiration {
    try {
      final dt = DateTime.parse(expirationDate);
      const months = [
        '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return 'Válido hasta ${dt.day} ${months[dt.month]}';
    } catch (_) {
      return expirationDate;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'cost_price': costPrice,
        'spending_value': spendingValue,
        'expiration_date': expirationDate,
      };
}
