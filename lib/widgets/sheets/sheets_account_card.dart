import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../theme/app_theme.dart';

class SheetsAccountCard extends StatelessWidget {
  final GoogleSignInAccount account;
  final VoidCallback onSignOut;

  const SheetsAccountCard({
    super.key,
    required this.account,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.elevatedCardDecoration,
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: account.photoUrl != null
                ? NetworkImage(account.photoUrl!)
                : null,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: account.photoUrl == null
                ? const Icon(Icons.person, color: AppTheme.primary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.displayName ?? 'Usuario de Google',
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  account.email,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
            onPressed: onSignOut,
            tooltip: 'Desconectar',
          ),
        ],
      ),
    );
  }
}
