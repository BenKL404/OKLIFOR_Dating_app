import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Pastille surface du thème (clair / sombre), icône [ColorScheme.onSurface] par défaut.
class OklAppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double iconSize;

  const OklAppBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconColor,
    this.iconSize = 19,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(
              icon,
              color: iconColor ?? cs.onSurface,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

/// [leading] pour [AppBar] / [SliverAppBar] (flèche retour, même pastille).
class OklAppBarBackButton extends StatelessWidget {
  final bool rootNavigator;
  final VoidCallback? onPressed;

  const OklAppBarBackButton({
    super.key,
    this.rootNavigator = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Center(
        child: OklAppBarIconButton(
          icon: LucideIcons.arrowLeft,
          onPressed:
              onPressed ??
              () {
                final nav = Navigator.of(context, rootNavigator: rootNavigator);
                if (nav.canPop()) nav.pop();
              },
        ),
      ),
    );
  }
}
