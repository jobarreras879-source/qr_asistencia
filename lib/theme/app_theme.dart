import 'package:flutter/material.dart';

/// Centralized design system for AVS Ingeniería QR App
class AppTheme {
  // ─── Colors ───────────────────────────────────────────────
  static const Color bg = Color(0xFF0F1724);
  static const Color surface = Color(0xFF162132);
  static const Color surfaceLight = Color(0xFF1D2B40);
  static const Color border = Color(0xFF314259);
  static const Color borderLight = Color(0xFF41546E);

  static const Color accent = Color(0xFF2F5D8A);
  static const Color accentLight = Color(0xFF4D79A3);
  static const Color accent2 = Color(0xFFC39A5B);
  static const Color accent2Light = Color(0xFFD9B47A);

  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFACC15);
  static const Color info = Color(0xFF3B82F6);
  static const Color accentTeal = Color(0xFF2DD4BF);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA6B3C5);
  static const Color textMuted = Color(0xFF73839A);

  // ─── Gradients ────────────────────────────────────────────
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF2A5278), Color(0xFF3A6B97)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accent2Gradient = LinearGradient(
    colors: [Color(0xFFC39A5B), Color(0xFFA87A3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0D1521), Color(0xFF132033), Color(0xFF101A29)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x20FFFFFF), Color(0x08FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1A2940), Color(0xFF132033)],
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
    color: surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: border.withValues(alpha: 0.78)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.18),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration get glassDecoration => BoxDecoration(
    color: surfaceLight.withValues(alpha: 0.94),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderLight.withValues(alpha: 0.72)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.16),
        blurRadius: 28,
        offset: const Offset(0, 12),
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
    border: Border.all(color: borderLight),
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
    fillColor: bg.withValues(alpha: 0.34),
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
      borderSide: const BorderSide(color: borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: accent2, width: 1.5),
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
    side: const BorderSide(color: borderLight),
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
