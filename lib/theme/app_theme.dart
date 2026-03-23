import 'package:flutter/material.dart';

/// Centralized design system for AVS Ingeniería QR App
class AppTheme {
  // ─── Colors ───────────────────────────────────────────────
  static const Color bg = Color(0xFF0A0D1A);
  static const Color surface = Color(0xFF141828);
  static const Color surfaceLight = Color(0xFF1C2236);
  static const Color border = Color(0xFF252D47);
  static const Color borderLight = Color(0xFF2F3A5C);

  static const Color accent = Color(0xFF2563EB);
  static const Color accentLight = Color(0xFF3B82F6);
  static const Color accent2 = Color(0xFFF5A623);
  static const Color accent2Light = Color(0xFFFFBF47);

  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFACC15);
  static const Color info = Color(0xFF3B82F6);
  static const Color accentTeal = Color(0xFF2DD4BF);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF7A85A3);
  static const Color textMuted = Color(0xFF4A5578);

  // ─── Gradients ────────────────────────────────────────────
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accent2Gradient = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0A0D1A), Color(0xFF111633)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x20FFFFFF), Color(0x08FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFF141828), Color(0xFF1C2236), Color(0xFF141828)],
    stops: [0.1, 0.5, 0.9],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    tileMode: TileMode.clamp,
  );

  // ─── Decorations ──────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: border.withValues(alpha: 0.5)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration get glassDecoration => BoxDecoration(
    gradient: glassGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration get accentGlassDecoration => BoxDecoration(
    color: accent.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: accent.withValues(alpha: 0.2)),
  );

  static BoxDecoration get dialogDecoration => BoxDecoration(
    color: bg,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.5),
        blurRadius: 40,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static InputDecoration inputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    filled: true,
    fillColor: surfaceLight.withValues(alpha: 0.5),
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
      borderSide: const BorderSide(color: accent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: error),
    ),
  );

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: accent,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
  );

  static ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
    foregroundColor: textPrimary,
    side: const BorderSide(color: border),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static ButtonStyle get ghostButton => TextButton.styleFrom(
    foregroundColor: textSecondary,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  // ─── Spacing & Radius ─────────────────────────────────────
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
