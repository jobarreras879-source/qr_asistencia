import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class HomeCampaignBadge extends StatelessWidget {
  final Widget child;
  final int? count;

  const HomeCampaignBadge({
    super.key,
    required this.child,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final label = count != null && count! > 0 ? '$count' : null;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        child,
        Positioned(
          top: 10,
          right: 10,
          child: IgnorePointer(
            child: Container(
              constraints: BoxConstraints(
                minWidth: label == null ? 14 : 20,
                minHeight: label == null ? 14 : 20,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: label == null ? 0 : 6,
                vertical: label == null ? 0 : 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: AppTheme.softShadow,
              ),
              alignment: Alignment.center,
              child: label == null
                  ? const SizedBox(width: 8, height: 8)
                  : Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
