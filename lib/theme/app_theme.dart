import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF2D5BDA);
  static const Color primaryDark = Color(0xFF2149C2);
  static const Color primaryLight = Color(0xFF4F7BFF);

  static const Color bg = Color(0xFFF4F6F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F5FA);
  static const Color surfaceLight = Color(0xFFF4F6F9);
  static const Color border = Color(0xFFE4EAF3);
  static const Color borderLight = Color(0xFFF1F5FB);

  static const Color success = Color(0xFF1CAA4D);
  static const Color successLight = Color(0xFF22C55E);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF0891B2);

  static const Color textPrimary = Color(0xFF1F293B);
  static const Color textSecondary = Color(0xFF6F7C91);
  static const Color textMuted = Color(0xFF9AA6B2);
  static const Color textOnPrimary = Colors.white;

  static const Color accent = primary;
  static const Color accentLight = primaryLight;
  static const Color accent2 = Color(0xFF0891B2);
  static const Color accent2Light = Color(0xFF06B6D4);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color scannerBg = Color(0xFF040817);
  static const Color scannerSurface = Color(0xFF12182B);
  static const Color scannerBorder = Color(0xFF15A7F8);
  static const Color scannerMuted = Color(0xFF67748C);
  static const Color successSoft = Color(0xFFEAF7EC);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2D5BDA), Color(0xFF2149C2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF4F6F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentGradient = primaryGradient;
  static const LinearGradient accent2Gradient = LinearGradient(
    colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFFF4F6F9), Color(0xFFFFFFFF), Color(0xFFEFF3F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF2D5BDA), Color(0xFF2149C2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x08FFFFFF), Color(0x04FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
    stops: [0.1, 0.5, 0.9],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    tileMode: TileMode.clamp,
  );

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static BoxDecoration get glassDecoration => BoxDecoration(
    color: surface.withValues(alpha: 0.94),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderLight),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get headerDecoration =>
      BoxDecoration(color: primary, borderRadius: BorderRadius.circular(20));

  static BoxDecoration get accentGlassDecoration => BoxDecoration(
    color: primary.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: primary.withValues(alpha: 0.2)),
  );

  static BoxDecoration get dialogDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static InputDecoration inputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool filled = true,
  }) => InputDecoration(
    filled: filled,
    fillColor: surfaceVariant,
    hintText: hint,
    hintStyle: const TextStyle(color: textMuted, fontSize: 14),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: textSecondary, size: 20)
        : null,
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: error),
    ),
  );

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: textOnPrimary,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
  );

  static ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
    foregroundColor: primary,
    side: const BorderSide(color: border),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static ButtonStyle get ghostButton => TextButton.styleFrom(
    foregroundColor: textSecondary,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;
}
