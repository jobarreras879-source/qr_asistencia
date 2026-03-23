import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../screens/project_management_screen.dart';
import '../screens/drive_config_screen.dart';
import '../screens/sheets_config_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/history_screen.dart';

class QuickActionsGrid extends StatelessWidget {
  final String rol;
  final VoidCallback onLogout;
  final VoidCallback onRefreshProyectos;

  const QuickActionsGrid({
    super.key,
    required this.rol,
    required this.onLogout,
    required this.onRefreshProyectos,
  });

  @override
  Widget build(BuildContext context) {
    final currentRol = rol.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.accentTeal,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ACCIONES RÁPIDAS',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (currentRol == 'ADMIN') ...[
              _buildIconButton(
                context,
                icon: Icons.folder_copy_rounded,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProjectManagementScreen(),
                    ),
                  );
                  onRefreshProyectos();
                },
                tooltip: 'Proyectos',
                accentColor: AppTheme.accentTeal,
              ),
              _buildIconButton(
                context,
                icon: Icons.add_to_drive_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DriveConfigScreen()),
                  );
                },
                tooltip: 'Google Drive (Fotos)',
                accentColor: const Color(0xFF4285F4),
              ),
              _buildIconButton(
                context,
                icon: Icons.table_chart_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SheetsConfigScreen()),
                  );
                },
                tooltip: 'Google Sheets (Historial)',
                accentColor: const Color(0xFF0F9D58),
              ),
              _buildIconButton(
                context,
                icon: Icons.people_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                  );
                },
                tooltip: 'Usuarios',
                accentColor: AppTheme.accent2,
              ),
            ],
            _buildIconButton(
              context,
              icon: Icons.history_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              tooltip: 'Historial',
            ),
            _buildIconButton(
              context,
              icon: Icons.logout_rounded,
              onTap: onLogout,
              tooltip: 'Cerrar Sesión',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? accentColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor?.withOpacity(0.5) ??
                    AppTheme.border.withOpacity(0.5),
              ),
            ),
            child: Icon(
              icon,
              color: accentColor ?? AppTheme.textSecondary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
