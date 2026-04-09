import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import 'home_campaign_badge.dart';

class HomeActionItem {
  final String label;
  final IconData icon;
  final Color iconColor;
  final String? targetKey;
  final FutureOr<void> Function() onTap;

  const HomeActionItem({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.targetKey,
  });
}

class HomeActionsSection extends StatelessWidget {
  final List<HomeActionItem> actions;
  final Map<String, GlobalKey> targetKeys;
  final Set<String> badgeTargets;
  final Map<String, int?> badgeCounts;

  const HomeActionsSection({
    super.key,
    required this.actions,
    required this.targetKeys,
    required this.badgeTargets,
    required this.badgeCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.98,
          ),
          itemBuilder: (_, index) => _HomeActionTile(
            item: actions[index],
            showBadge: actions[index].targetKey != null &&
                badgeTargets.contains(actions[index].targetKey!),
            badgeCount: actions[index].targetKey == null
                ? null
                : badgeCounts[actions[index].targetKey!],
            targetKey: actions[index].targetKey == null
                ? null
                : targetKeys[actions[index].targetKey!],
          ),
        ),
      ],
    );
  }
}

class _HomeActionTile extends StatelessWidget {
  final HomeActionItem item;
  final GlobalKey? targetKey;
  final bool showBadge;
  final int? badgeCount;

  const _HomeActionTile({
    required this.item,
    required this.targetKey,
    required this.showBadge,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      key: targetKey,
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => item.onTap(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.iconColor, size: 29),
              const SizedBox(height: 10),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return !showBadge
        ? tile
        : HomeCampaignBadge(count: badgeCount, child: tile);
  }
}
