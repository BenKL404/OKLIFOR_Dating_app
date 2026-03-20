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
