import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';

/// A single attendance record card for the History screen.
class HistoryRecordCard extends StatelessWidget {
  final Map<String, dynamic> registro;

  const HistoryRecordCard({super.key, required this.registro});

  @override
  Widget build(BuildContext context) {
    final isProyecto = registro['tipo'] == 'Proyecto';
    final color = isProyecto ? AppTheme.accent : AppTheme.accent2;
    final icon = isProyecto
        ? Icons.construction_rounded
        : Icons.restaurant_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          _buildIcon(icon, color),
          const SizedBox(width: 14),
          _buildInfo(color),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: AppTheme.border, size: 14),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(child: Icon(icon, color: color, size: 20)),
    );
  }

  Widget _buildInfo(Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            registro['nombre']?.toString() ?? 'Sin nombre',
            style: GoogleFonts.ibmPlexSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                DateFormatter.formatTime(registro['fecha_hora']?.toString()),
                style: GoogleFonts.ibmPlexSans(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  registro['tipo']?.toString() ?? '',
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Proyecto: ${registro['proyecto'] ?? ''}',
            style: GoogleFonts.ibmPlexSans(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
