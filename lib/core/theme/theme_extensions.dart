import 'package:flutter/material.dart';

/// Accès rapide aux couleurs du [Theme] actuel (clair / sombre / système).
extension OklThemeContext on BuildContext {
  Color get oklScaffold => Theme.of(this).scaffoldBackgroundColor;

  Color get oklSurface => Theme.of(this).colorScheme.surface;

  Color get oklDivider => Theme.of(this).dividerColor;

  Color get oklOnSurface => Theme.of(this).colorScheme.onSurface;

  Color oklOnSurfaceMuted([double opacity = 0.55]) =>
      oklOnSurface.withValues(alpha: opacity);
}

/// Canvas et scrims pour Rencontres + Explorer (s’adaptent au thème).
extension OklMeetChrome on BuildContext {
  bool get oklMeetIsDark => Theme.of(this).brightness == Brightness.dark;

  /// Même fond que le reste de l’app (profil, réglages) — pas de dégradé bleuté.
  BoxDecoration get oklMeetCanvasDecoration =>
      BoxDecoration(color: oklScaffold);

  LinearGradient get oklMeetHeaderScrimGradient {
    if (oklMeetIsDark) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0.5),
          Colors.black.withValues(alpha: 0.22),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      );
    }
    // Fond = scaffold : un dégradé blanc/transparence laissait une « ligne d’ombre »
    // sur le gris clair du corps de page (#F2F2F5).
    final bg = oklScaffold;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [bg, bg],
    );
  }
}
