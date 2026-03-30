import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final Animation<double> animation;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.animation,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rol = user['rol'] as String;
    final color = _rolColor(rol);

    return FadeTransition(
      opacity: animation,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - animation.value)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: AppTheme.cardDecoration,
          child: Row(
            children: [
              _buildAvatar(rol, color),
              const SizedBox(width: 14),
              _buildUserInfo(rol, color),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String rol, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Center(child: Icon(_rolIcon(rol), color: color, size: 22)),
    );
  }

  Widget _buildUserInfo(String rol, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user['usuario'] ?? 'Sin nombre',
            style: GoogleFonts.ibmPlexSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              rol,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onEdit,
          icon: const Icon(
            Icons.edit_outlined,
            color: AppTheme.textSecondary,
            size: 20,
          ),
        ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.error,
              size: 20,
            ),
          ),
      ],
    );
  }

  Color _rolColor(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMIN':
        return AppTheme.accent;
      default:
        return AppTheme.accentTeal;
    }
  }

  IconData _rolIcon(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMIN':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}
