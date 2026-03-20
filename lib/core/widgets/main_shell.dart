import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../theme/theme_extensions.dart';
import '../utils/okl_feedback.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  DateTime? _lastExitPrompt;

  static int _tabIndexForPath(String path) {
    if (path.startsWith('/discovery')) return 0;
    if (path.startsWith('/explore')) return 1;
    if (path.startsWith('/chats')) return 2;
    if (path.startsWith('/profile')) return 3;
    return 0;
  }

  static const _routes = ['/discovery', '/explore', '/chats', '/profile'];

  void _onPopInvoked(bool didPop, dynamic result) {
    if (didPop) return;
    if (!mounted) return;

    // Fermer d’abord les écrans poussés avec rootNavigator (statuts, conversation, image…)
    final rootNav = Navigator.of(context, rootNavigator: true);
    if (rootNav.canPop()) {
      rootNav.pop();
      return;
    }

    final go = GoRouter.maybeOf(context);
    if (go != null && go.canPop()) {
      go.pop();
      return;
    }

    final nestedNav = Navigator.maybeOf(context, rootNavigator: false);
    if (nestedNav != null && nestedNav.canPop()) {
      nestedNav.pop();
      return;
    }

    final now = DateTime.now();
    if (_lastExitPrompt == null ||
        now.difference(_lastExitPrompt!) > const Duration(seconds: 2)) {
      _lastExitPrompt = now;
      OklFeedback.snack(
        context,
        'Appuie encore sur Retour pour quitter Oklifor',
      );
      return;
    }

    _lastExitPrompt = null;
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _tabIndexForPath(path);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        backgroundColor: context.oklScaffold,
        body: widget.child,
        bottomNavigationBar: ClipRect(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.oklScaffold.withValues(alpha: 0.92),
              border: Border(
                top: BorderSide(color: context.oklDivider, width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 62,
                child: Row(
                  children: [
                    _NavItem(
                      icon: LucideIcons.sparkles,
                      label: 'Découvrir',
                      index: 0,
                      selected: selectedIndex == 0,
                      onTap: () => context.go(_routes[0]),
                    ),
                    _NavItem(
                      icon: LucideIcons.compass,
                      label: 'Explorer',
                      index: 1,
                      selected: selectedIndex == 1,
                      onTap: () => context.go(_routes[1]),
                    ),
                    _NavItem(
                      icon: LucideIcons.messageCircle,
                      label: 'Messages',
                      index: 2,
                      selected: selectedIndex == 2,
                      onTap: () => context.go(_routes[2]),
                    ),
                    _NavItem(
                      icon: LucideIcons.user,
                      label: 'Profil',
                      index: 3,
                      selected: selectedIndex == 3,
                      onTap: () => context.go(_routes[3]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? AppColors.togoGold
        : context.oklOnSurfaceMuted(0.55);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: accent,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: selected ? 4 : 0,
                height: selected ? 4 : 0,
                decoration: BoxDecoration(
                  color: AppColors.togoGreen,
                  shape: BoxShape.circle,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.togoGold.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
