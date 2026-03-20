import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Pastille surface du thème (clair / sombre), icône [ColorScheme.onSurface] par défaut.
class OklAppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double iconSize;
  final bool useOverlayStyle;
  final bool overlaySelected;

  const OklAppBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconColor,
    this.iconSize = 19,
    this.useOverlayStyle = false,
    this.overlaySelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = useOverlayStyle
        ? (overlaySelected
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.black.withValues(alpha: 0.28))
        : cs.surface;
    final borderColor = useOverlayStyle
        ? (overlaySelected ? Colors.white70 : Colors.white30)
        : Colors.transparent;
    final resolvedIconColor = useOverlayStyle
        ? Colors.white.withValues(alpha: overlaySelected ? 0.98 : 0.9)
        : (iconColor ?? cs.onSurface);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: useOverlayStyle && overlaySelected ? 1.4 : 1,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Icon(
                icon,
                color: resolvedIconColor,
                size: iconSize,
              ),
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
