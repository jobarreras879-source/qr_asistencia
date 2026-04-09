import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import 'home_campaign_badge.dart';

class HomeCta extends StatelessWidget {
  final GlobalKey? buttonKey;
  final bool enabled;
  final VoidCallback? onPressed;
  final bool showBadge;
  final int? badgeCount;

  const HomeCta({
    super.key,
    required this.buttonKey,
    required this.enabled,
    required this.onPressed,
    this.showBadge = false,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final button = SizedBox(
      key: buttonKey,
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          Icons.qr_code_2_rounded,
          size: 22,
          color: Colors.white.withValues(alpha: enabled ? 1 : 0.78),
        ),
        label: Text(
          'Iniciar Registro',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: enabled ? 1 : 0.84),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? AppTheme.primary : const Color(0xFF8FA4E7),
          disabledBackgroundColor: const Color(0xFF8FA4E7),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );

    final wrapped = !showBadge
        ? button
        : HomeCampaignBadge(count: badgeCount, child: button);

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18, 18 + bottomPadding),
      child: wrapped,
    );
  }
}
