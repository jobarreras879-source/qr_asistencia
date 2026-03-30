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
        Text(
          'Acciones disponibles',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Accede a configuraciones y tareas administrativas desde este panel.',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.08,
          children: [
            if (currentRol == 'ADMIN') ...[
              _buildActionButton(
                context,
                icon: Icons.folder_copy_rounded,
                label: 'Proyectos',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProjectManagementScreen(),
                    ),
                  );
                  onRefreshProyectos();
                },
                accentColor: AppTheme.accent,
              ),
              _buildActionButton(
                context,
                icon: Icons.add_to_drive_rounded,
                label: 'Drive',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DriveConfigScreen(),
                    ),
                  );
                },
                accentColor: const Color(0xFF5B87C5),
              ),
              _buildActionButton(
                context,
                icon: Icons.table_chart_rounded,
                label: 'Sheets',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SheetsConfigScreen(),
                    ),
                  );
                },
                accentColor: const Color(0xFF4B8A63),
              ),
              _buildActionButton(
                context,
                icon: Icons.people_rounded,
                label: 'Usuarios',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserManagementScreen(),
                    ),
                  );
                },
                accentColor: AppTheme.accent2,
              ),
            ],
            _buildActionButton(
              context,
              icon: Icons.history_rounded,
              label: 'Historial',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
            ),
            _buildActionButton(
              context,
              icon: Icons.logout_rounded,
              label: 'Salir',
              onTap: onLogout,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required String label,
    Color? accentColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  accentColor?.withValues(alpha: 0.35) ??
                  AppTheme.borderLight.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (accentColor ?? AppTheme.accent).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accentColor ?? AppTheme.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
