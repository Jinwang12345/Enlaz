import 'bonus_template_model.dart';

class UserBonusModel {
  final String id;
  final String userId;
  final String bonusTemplateId;
  final String? campaignId;
  final String status;
  final String qrToken;
  final String purchasedAt;
  final BonusTemplateModel? template;

  UserBonusModel({
    required this.id,
    required this.userId,
    required this.bonusTemplateId,
    this.campaignId,
    required this.status,
    required this.qrToken,
    required this.purchasedAt,
    this.template,
  });

  factory UserBonusModel.fromJson(Map<String, dynamic> json) {
    final templateJson = json['template'];
    return UserBonusModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      userId: json['user_id'] as String? ?? '',
      bonusTemplateId: json['bonus_template_id'] as String? ?? '',
      campaignId: json['campaign_id'] as String?,
      status: json['status'] as String? ?? 'active',
      qrToken: json['qr_token'] as String? ?? '',
      purchasedAt: json['purchased_at'] as String? ?? '',
      template: templateJson != null
          ? BonusTemplateModel.fromJson(templateJson as Map<String, dynamic>)
          : null,
    );
  }

  /// True when the bonus is still usable.
  bool get isActive => status == 'active';

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'bonus_template_id': bonusTemplateId,
        'campaign_id': campaignId,
        'status': status,
        'qr_token': qrToken,
        'purchased_at': purchasedAt,
        if (template != null) 'template': template!.toJson(),
      };
}
