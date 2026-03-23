import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  final String usuario;

  const HomeHeader({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AVS Ingeniería',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 26,
                    letterSpacing: 3,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'REGISTRAR ASISTENCIA',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildUserBadge(usuario),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBadge(String usuario) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withOpacity(0.15),
            AppTheme.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            usuario,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.accent,
            ),
          ),
        ],
      ),
    );
  }
}
