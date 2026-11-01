import 'package:flutter/material.dart';

class AppColors {
  // Pure OLED Background
  static const Color background = Color(0xFF000000);
  
  // Surfaces & Cards
  static const Color surfacePrimary = Color(0xFF0A0A0C);
  static const Color surfaceSecondary = Color(0xFF141418);
  static const Color surfaceElevated = Color(0xFF1C1C22);
  static const Color surfaceHighlight = Color(0xFF262630);

  // Borders
  static const Color borderSubtle = Color(0x1AFFFFFF); // ~10% white
  static const Color borderMedium = Color(0x33FFFFFF); // ~20% white
  static const Color borderFocus = Color(0xFF00F2FE);

  // Status & Accents
  static const Color connected = Color(0xFF00FF87);    // Neon Mint
  static const Color connecting = Color(0xFFFFB800);   // Neon Amber
  static const Color disconnected = Color(0xFF6B7280); // Muted Slate
  static const Color error = Color(0xFFFF3B30);        // Neon Crimson
  static const Color accent = Color(0xFF00F2FE);       // Electric Cyan

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF4B5563);

  // Gradient accents
  static const LinearGradient activeGradient = LinearGradient(
    colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient powerGlowGradient = LinearGradient(
    colors: [Color(0x3300FF87), Color(0x00000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
