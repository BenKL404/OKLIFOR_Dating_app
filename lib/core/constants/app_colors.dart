import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary    = Color(0xFFE8315B);
  static const Color primaryDark = Color(0xFFC0183A);
  static const Color secondary  = Color(0xFFFF6B35);

  // IG/WA inspired
  static const Color dark       = Color(0xFF0A0A0A);
  static const Color surface    = Color(0xFF161616);
  static const Color card       = Color(0xFF1E1E1E);
  static const Color divider    = Color(0xFF2A2A2A);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E8E);
  static const Color textMuted     = Color(0xFF555555);

  /// Palette **clair** (synchronisée avec [AppTheme.lightTheme]).
  static const Color lightScaffold = Color(0xFFF2F2F5);
  static const Color lightSurface  = Color(0xFFFFFFFF);
  static const Color lightDivider  = Color(0xFFE4E4EA);
  static const Color lightTextPrimary   = Color(0xFF0F0F0F);
  static const Color lightTextSecondary = Color(0xFF5C5C62);
  static const Color lightTextMuted     = Color(0xFF93939C);

  // Togo — drapeau en accents modernes (vert / or / rouge)
  static const Color togoGreen = Color(0xFF006A4E);
  static const Color togoGold  = Color(0xFFFFD200);
  /// Or plus lisible sur fond clair (barre d’onglets, surfaces blanches).
  static const Color togoGoldOnLight = Color(0xFFB8860B);
  static const Color togoRed   = Color(0xFFD21034);

  // Functional
  static const Color green  = Color(0xFF25D366); // WhatsApp green
  static const Color blue   = Color(0xFF0095F6); // IG blue
  static const Color story  = Color(0xFFC13584); // IG story gradient

  static const LinearGradient togoAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [togoGreen, Color(0xFF0D4D3F)],
  );

  static const LinearGradient togoHeroOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x99000000),
      Colors.transparent,
      Color(0xE6000000),
    ],
    stops: [0.0, 0.35, 1.0],
  );

  static const LinearGradient igStoryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFCAF45), Color(0xFFE1306C), Color(0xFF833AB4)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8315B), Color(0xFFC0183A)],
  );

  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xEE0A0A0A)],
    stops: [0.4, 1.0],
  );
}
