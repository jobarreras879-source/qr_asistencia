import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ProjectSelectorCard extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> proyectos;
  final String? proyectoIdSeleccionado;
  final ValueChanged<String?> onChanged;

  const ProjectSelectorCard({
    super.key,
    required this.isLoading,
    required this.proyectos,
    required this.proyectoIdSeleccionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proyecto operativo',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona el frente de trabajo antes de iniciar un registro.',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          isLoading
              ? const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppTheme.accent),
                  ),
                )
              : proyectos.isEmpty
                  ? _buildEmptyState()
                  : _buildDropdown(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No se encontraron proyectos. Verifica la configuración de tu base de datos.',
              style: TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.bg.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: AppTheme.surface,
          value: proyectoIdSeleccionado,
          hint: Text(
            '— Selecciona —',
            style: GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 14),
          ),
          icon: const Icon(Icons.unfold_more_rounded,
              color: AppTheme.textSecondary, size: 20),
          items: proyectos.map((p) {
            return DropdownMenuItem<String>(
              value: p['numero'],
              child: Text(
                '${p['numero']} — ${p['nombre']}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
