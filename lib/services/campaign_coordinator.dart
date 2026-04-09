import '../models/app_campaign.dart';

class CampaignCoordinatorSnapshot {
  final AppCampaign? modal;
  final AppCampaign? banner;
  final List<AppCampaign> tooltips;
  final Map<String, AppCampaign> badges;

  const CampaignCoordinatorSnapshot({
    required this.modal,
    required this.banner,
    required this.tooltips,
    required this.badges,
  });
}

class CampaignCoordinator {
  static CampaignCoordinatorSnapshot build(List<AppCampaign> campaigns) {
    final sorted = [...campaigns]..sort(_compareCampaigns);

    AppCampaign? modal;
    AppCampaign? banner;
    final tooltips = <AppCampaign>[];
    final badges = <String, AppCampaign>{};

    for (final campaign in sorted) {
      if (campaign.isModal && modal == null) {
        modal = campaign;
        continue;
      }

      if (campaign.isBanner && banner == null) {
        banner = campaign;
        continue;
      }

      if (campaign.isTooltip) {
        tooltips.add(campaign);
        continue;
      }

      if (campaign.isBadge &&
          campaign.targetKey != null &&
          campaign.targetKey!.isNotEmpty) {
        badges.putIfAbsent(campaign.targetKey!, () => campaign);
      }
    }

    tooltips.sort((left, right) {
      final stepCompare = left.stepOrder.compareTo(right.stepOrder);
      if (stepCompare != 0) return stepCompare;
      final priorityCompare = right.priority.compareTo(left.priority);
      if (priorityCompare != 0) return priorityCompare;
      return left.id.compareTo(right.id);
    });

    return CampaignCoordinatorSnapshot(
      modal: modal,
      banner: banner,
      tooltips: tooltips,
      badges: badges,
    );
  }

  static int _compareCampaigns(AppCampaign left, AppCampaign right) {
    final typeCompare = _typeRank(left.type).compareTo(_typeRank(right.type));
    if (typeCompare != 0) return typeCompare;

    final priorityCompare = right.priority.compareTo(left.priority);
    if (priorityCompare != 0) return priorityCompare;

    final stepCompare = left.stepOrder.compareTo(right.stepOrder);
    if (stepCompare != 0) return stepCompare;

    return left.id.compareTo(right.id);
  }

  static int _typeRank(AppCampaignType type) {
    switch (type) {
      case AppCampaignType.modal:
        return 0;
      case AppCampaignType.tooltip:
        return 1;
      case AppCampaignType.banner:
        return 2;
      case AppCampaignType.badge:
        return 3;
    }
  }
}
