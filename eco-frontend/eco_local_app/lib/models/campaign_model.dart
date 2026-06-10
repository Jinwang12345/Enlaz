class CampaignModel {
  final String id;
  final String name;
  final String? description;
  final double totalBudget;
  final double remainingBudget;
  final int maxBonusesPerUser;
  final String startDate;
  final String endDate;
  final String status;

  CampaignModel({
    required this.id,
    required this.name,
    this.description,
    required this.totalBudget,
    required this.remainingBudget,
    required this.maxBonusesPerUser,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      totalBudget: (json['total_budget'] as num?)?.toDouble() ?? 0.0,
      remainingBudget: (json['remaining_budget'] as num?)?.toDouble() ?? 0.0,
      maxBonusesPerUser: json['max_bonuses_per_user'] as int? ?? 999,
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'total_budget': totalBudget,
        'remaining_budget': remainingBudget,
        'max_bonuses_per_user': maxBonusesPerUser,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
      };
}
