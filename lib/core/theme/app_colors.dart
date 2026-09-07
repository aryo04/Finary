import 'package:flutter/material.dart';

/// Premium Modern Fintech Color Palette for CAKEU
class AppColors {
  // Primary Brand: Deep Emerald & Forest Gradient
  static const Color primary = Color(0xFF0D9488); // Teal 600
  static const Color primaryDark = Color(0xFF0F766E); // Teal 700
  static const Color primaryDarker = Color(0xFF115E59); // Teal 800
  static const Color primaryLight = Color(0xFF2DD4BF); // Teal 400
  static const Color primaryContainer = Color(0xFFCCFBF1); // Teal 100
  static const Color accent = Color(0xFF10B981); // Emerald 500

  // Secondary & Accents
  static const Color secondary = Color(0xFF6366F1); // Indigo 500
  static const Color secondaryContainer = Color(0xFFEEF2FF); // Indigo 50

  // Semantic Status
  static const Color income = Color(0xFF10B981); // Emerald 500
  static const Color incomeLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color expense = Color(0xFFF43F5E); // Rose 500
  static const Color expenseLight = Color(0xFFFFE4E6); // Rose 100
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFFEE2E2); // Red 100

  // Neutral & Surfaces (Light Slate Theme)
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF064E3B), Color(0xFF0F766E), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Category Colors Palette
  static const List<Color> categoryColors = [
    Color(0xFFF43F5E), // Rose (Makan)
    Color(0xFF3B82F6), // Blue (Transport)
    Color(0xFF8B5CF6), // Purple (Belanja)
    Color(0xFFF59E0B), // Amber (Tagihan)
    Color(0xFFEC4899), // Pink (Hiburan)
    Color(0xFF10B981), // Emerald (Gaji)
    Color(0xFF06B6D4), // Cyan (Freelance)
    Color(0xFF6366F1), // Indigo (Investasi)
    Color(0xFF14B8A6), // Teal (Kesehatan)
    Color(0xFF64748B), // Slate (Lainnya)
  ];

  /// Mengonversi string hex (#RRGGBB atau RRGGBB) ke Color Flutter secara aman
  static Color fromHex(String? hexString, {Color fallback = primary}) {
    if (hexString == null || hexString.trim().isEmpty) return fallback;
    try {
      final clean = hexString.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }
}
