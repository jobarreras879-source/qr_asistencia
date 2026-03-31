import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ProcessingOverlay extends StatelessWidget {
  final String message;
  final String? subMessage;
  final IconData? icon;

  const ProcessingOverlay({
    super.key,
    required this.message,
    this.subMessage,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIndicator(),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  subMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    if (icon != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            height: 56,
            width: 56,
            child: CircularProgressIndicator(
              color: AppTheme.primary,
              strokeWidth: 3,
            ),
          ),
          Icon(icon, color: AppTheme.primary, size: 24),
        ],
      );
    }
    return const SizedBox(
      height: 48,
      width: 48,
      child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
    );
  }
}
