import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF8B7CF8);
  static const Color primaryDark = Color(0xFF5B4BC4);

  // Secondary colors
  static const Color secondary = Color(0xFFFF7675);
  static const Color secondaryLight = Color(0xFFFFA8A7);
  static const Color secondaryDark = Color(0xFFE55A59);

  // Accent colors
  static const Color accent = Color(0xFF00B894);
  static const Color accentLight = Color(0xFF55C8A3);
  static const Color accentDark = Color(0xFF009B7D);

  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF0A0E27);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1A1F3A);

  // Text colors
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textLight = Colors.white;
  static const Color textHint = Color(0xFFB2BEC3);

  // Status colors
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFFA502);
  static const Color error = Color(0xFFFF4757);
  static const Color info = Color(0xFF3742FA);

  // Financial colors
  static const Color income = Color(0xFF00B894);
  static const Color expense = Color(0xFFFF7675);
  static const Color savings = Color(0xFF6C5CE7);
  static const Color budget = Color(0xFFFFA502);

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF6C5CE7),
    Color(0xFFFF7675),
    Color(0xFF00B894),
    Color(0xFFFFA502),
    Color(0xFF3742FA),
    Color(0xFFFF4757),
    Color(0xFF2ED573),
    Color(0xFF3742FA),
  ];

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFFE8E8E8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadow colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);
}
