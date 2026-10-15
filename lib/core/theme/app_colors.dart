import 'package:flutter/material.dart';

/// AppColors encapsulates the "My Trans Actions" brand palette:
/// A light, premium, coin-inspired theme with soft champagne gold,
/// warm ivory/cream surfaces, deep charcoal typography, and tasteful
/// semantic accents for income, expenses, and savings.
class AppColors {
  // Brand Champagne & Coin Gold accents
  static const Color goldPrimary = Color(0xFFC5A059);
  static const Color goldLight = Color(0xFFDFBF77);
  static const Color goldDark = Color(0xFF9E7B35);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldSubtle = Color(0xFFF9F5EC);
  static const Color goldBorder = Color(0xFFEADBBE);

  // Warm ivory, cream & surface colors (Light mode default)
  static const Color ivoryBackground = Color(0xFFFAF8F5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF5F2EB);
  static const Color surfaceMuted = Color(0xFFEFECE5);
  static const Color cardBorder = Color(0xFFEBE6DD);

  // Text & Content hierarchy
  static const Color textPrimary = Color(0xFF1E1D1A);
  static const Color textSecondary = Color(0xFF6B6760);
  static const Color textTertiary = Color(0xFF9C978F);
  static const Color textOnGold = Color(0xFF2A2109);

  // Financial Semantics
  static const Color incomeGreen = Color(0xFF2D8A4E);
  static const Color incomeGreenLight = Color(0xFFE8F5EC);
  static const Color expenseCoral = Color(0xFFD34541);
  static const Color expenseCoralLight = Color(0xFFFDEEEC);
  static const Color savingsTeal = Color(0xFF0F867C);
  static const Color savingsTealLight = Color(0xFFE6F5F3);
  static const Color transferBlue = Color(0xFF3273DC);
  static const Color transferBlueLight = Color(0xFFEBF2FD);

  // Chart Palette (Curated harmonious colors)
  static const List<Color> chartColors = [
    Color(0xFFC5A059), // Gold
    Color(0xFF2D8A4E), // Sage green
    Color(0xFF3F77B0), // Dusty blue
    Color(0xFF8860B8), // Lavender / Purple
    Color(0xFFD35E4B), // Coral
    Color(0xFF0F867C), // Teal
    Color(0xFFD9822B), // Amber orange
    Color(0xFF7A8B99), // Slate gray
  ];

  // Dark Theme Palette (Sleek warm dark mode)
  static const Color darkBackground = Color(0xFF131312);
  static const Color darkSurface = Color(0xFF1D1C1A);
  static const Color darkSurfaceElevated = Color(0xFF272522);
  static const Color darkBorder = Color(0xFF36332E);
  static const Color darkTextPrimary = Color(0xFFF6F3EE);
  static const Color darkTextSecondary = Color(0xFFAAA59D);
}
