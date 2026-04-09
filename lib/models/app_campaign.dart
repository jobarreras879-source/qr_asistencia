enum AppCampaignType { modal, banner, tooltip, badge }

AppCampaignType _parseCampaignType(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'modal':
      return AppCampaignType.modal;
    case 'banner':
      return AppCampaignType.banner;
    case 'tooltip':
      return AppCampaignType.tooltip;
    case 'badge':
      return AppCampaignType.badge;
    default:
      throw ArgumentError('Tipo de campaña no soportado: $raw');
  }
}

class AppCampaign {
  final int id;
  final AppCampaignType type;
  final String title;
  final String body;
  final String? ctaLabel;
  final String? ctaRoute;
  final String? targetScreen;
  final String? targetKey;
  final int? badgeCount;
  final int priority;
  final int stepOrder;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const AppCampaign({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.ctaRoute,
    required this.targetScreen,
    required this.targetKey,
    required this.badgeCount,
    required this.priority,
    required this.stepOrder,
    required this.startsAt,
    required this.endsAt,
  });

  factory AppCampaign.fromMap(Map<String, dynamic> map) {
    return AppCampaign(
      id: (map['id'] as num).toInt(),
      type: _parseCampaignType(map['type'] as String),
      title: (map['title'] as String?)?.trim() ?? '',
      body: (map['body'] as String?)?.trim() ?? '',
      ctaLabel: (map['ctaLabel'] as String?)?.trim(),
      ctaRoute: (map['ctaRoute'] as String?)?.trim(),
      targetScreen: (map['targetScreen'] as String?)?.trim(),
      targetKey: (map['targetKey'] as String?)?.trim(),
      badgeCount: (map['badgeCount'] as num?)?.toInt(),
      priority: (map['priority'] as num?)?.toInt() ?? 0,
      stepOrder: (map['stepOrder'] as num?)?.toInt() ?? 0,
      startsAt: map['startsAt'] != null
          ? DateTime.tryParse(map['startsAt'] as String)
          : null,
      endsAt: map['endsAt'] != null
          ? DateTime.tryParse(map['endsAt'] as String)
          : null,
    );
  }

  bool get hasCta =>
      (ctaLabel?.isNotEmpty ?? false) && (ctaRoute?.isNotEmpty ?? false);

  bool get isModal => type == AppCampaignType.modal;
  bool get isBanner => type == AppCampaignType.banner;
  bool get isTooltip => type == AppCampaignType.tooltip;
  bool get isBadge => type == AppCampaignType.badge;
}
