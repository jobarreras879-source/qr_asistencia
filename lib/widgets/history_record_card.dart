import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';

class HistoryRecordCard extends StatelessWidget {
  final Map<String, dynamic> registro;

  const HistoryRecordCard({super.key, required this.registro});

  @override
  Widget build(BuildContext context) {
    final isProyecto = registro['tipo'] == 'Proyecto';
    final color = isProyecto ? AppTheme.primary : AppTheme.accent2;
    final icon = isProyecto
        ? Icons.construction_rounded
        : Icons.restaurant_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.elevatedCardDecoration,
      child: Row(
        children: [
          _buildIcon(icon, color),
          const SizedBox(width: 14),
          _buildInfo(color),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppTheme.border,
            size: 14,
          ),
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
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                DateFormatter.formatTime(registro['fecha_hora']?.toString()),
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  registro['tipo']?.toString() ?? '',
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Proyecto: ${registro['proyecto'] ?? ''}',
            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          if (registro['usuario_logueado'] != null) ...[
            const SizedBox(height: 2),
            Text(
              'Registrado por: ${registro['usuario_logueado']}',
              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
