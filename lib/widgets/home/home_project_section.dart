import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import 'home_campaign_badge.dart';

class HomeProjectSection extends StatelessWidget {
  final GlobalKey? selectorKey;
  final List<Map<String, dynamic>> projects;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final String Function(Map<String, dynamic>) labelBuilder;
  final bool showBadge;
  final int? badgeCount;

  const HomeProjectSection({
    super.key,
    required this.selectorKey,
    required this.projects,
    required this.selectedValue,
    required this.onChanged,
    required this.labelBuilder,
    this.showBadge = false,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final selector = Container(
      key: selectorKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.textSecondary,
          ),
          hint: Text(
            'Seleccione un proyecto',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
          items: projects.map((project) {
            final numero = project['numero']?.toString() ?? '';
            return DropdownMenuItem<String>(
              value: numero,
              child: Text(
                labelBuilder(project),
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frente de Trabajo',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        !showBadge
            ? selector
            : HomeCampaignBadge(count: badgeCount, child: selector),
      ],
    );
  }
}
