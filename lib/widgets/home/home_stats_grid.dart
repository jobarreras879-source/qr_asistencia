import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class HomeStatsGrid extends StatelessWidget {
  final int registrosHoy;
  final int proyectosActivos;

  const HomeStatsGrid({
    super.key,
    required this.registrosHoy,
    required this.proyectosActivos,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HomeStatCard(
            value: '$registrosHoy',
            label: 'Registros hoy',
            valueColor: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _HomeStatCard(
            value: '$proyectosActivos',
            label: 'Proyectos activos',
            valueColor: const Color(0xFF18B4AA),
          ),
        ),
      ],
    );
  }
}

class _HomeStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _HomeStatCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: valueColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
