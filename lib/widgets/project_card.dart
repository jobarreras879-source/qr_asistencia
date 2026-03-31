import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final Animation<double> animation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.animation,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - animation.value)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.elevatedCardDecoration,
          child: Row(
            children: [
              _buildProjectLeading(),
              const SizedBox(width: 16),
              _buildProjectInfo(),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectLeading() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          project['numero'] ?? '?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project['nombre'] ?? 'Sin nombre',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${project['numero']}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
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
}
