import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginBottomActions extends StatelessWidget {
  static const _linkColor = Color(0xFF5E6A84);
  static const _panelBg = Color(0xFFF8FAFD);
  static const _panelBorder = Color(0xFFE6ECF4);

  final VoidCallback onForgotPassword;
  final VoidCallback onSupport;

  const LoginBottomActions({
    super.key,
    required this.onForgotPassword,
    required this.onSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ayuda y soporte',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A2234),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionChip(
                icon: Icons.help_outline_rounded,
                label: 'Recuperar acceso',
                onTap: onForgotPassword,
              ),
              _ActionChip(
                icon: Icons.support_agent_rounded,
                label: 'Soporte técnico',
                onTap: onSupport,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: LoginBottomActions._linkColor,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
