import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class SheetsNoSheetView extends StatelessWidget {
  final bool isCreating;
  final VoidCallback onCreateSpreadsheet;

  const SheetsNoSheetView({
    super.key,
    required this.isCreating,
    required this.onCreateSpreadsheet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.elevatedCardDecoration,
      child: Column(
        children: [
          Icon(Icons.file_copy_rounded, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            'Sin hoja vinculada',
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea o vincula una hoja de cálculo para sincronizar la asistencia.',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          isCreating
              ? const CircularProgressIndicator(color: AppTheme.success)
              : ElevatedButton.icon(
                  onPressed: onCreateSpreadsheet,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: Text(
                    'Crear Nueva Hoja',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
