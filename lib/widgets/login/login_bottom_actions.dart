import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginBottomActions extends StatelessWidget {
  static const _linkColor = Color(0xFF5E6A84);

  final VoidCallback onForgotPassword;
  final VoidCallback onSupport;

  const LoginBottomActions({
    super.key,
    required this.onForgotPassword,
    required this.onSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: _linkColor,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.help_outline_rounded, size: 18),
            label: Text(
              '¿Olvidó su contraseña?',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onSupport,
            style: TextButton.styleFrom(
              foregroundColor: _linkColor,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Soporte Técnico',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
