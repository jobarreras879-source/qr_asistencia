import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_campaign.dart';
import '../theme/app_theme.dart';

class CampaignModalDialog extends StatelessWidget {
  final AppCampaign campaign;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;

  const CampaignModalDialog({
    super.key,
    required this.campaign,
    required this.onDismiss,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Container(
        decoration: AppTheme.dialogDecoration,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    campaign.title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  splashRadius: 18,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              campaign.body,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    'Cerrar',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                if (campaign.hasCta && onAction != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onAction,
                    child: Text(campaign.ctaLabel!),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
