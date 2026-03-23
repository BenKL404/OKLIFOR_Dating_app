import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/auth/providers/auth_api_provider.dart';
import '../../features/auth/utils/apply_post_login.dart';
import '../constants/app_colors.dart';
import '../constants/layout_constants.dart';
import '../theme/theme_extensions.dart';
import '../utils/okl_feedback.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  DateTime? _lastExitPrompt;
  bool _sessionSynced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSessionFromApi());
  }

  Future<void> _syncSessionFromApi() async {
    if (_sessionSynced || !mounted) return;
    _sessionSynced = true;
    try {
      final me = await ref.read(okliforApiClientProvider).fetchMe();
      if (!mounted) return;
      if (!me.profile.profileOnboardingCompleted) {
        applyMeAndGoHome(context, me);
        return;
      }
      me.applyToLocalSessions();
    } catch (_) {
      // Hors ligne ou token expiré : l’écran suivant gère (splash / 401).
    }
  }

  static int _tabIndexForPath(String path) {
    if (path.startsWith('/discovery')) return 0;
    if (path.startsWith('/explore')) return 1;
    if (path.startsWith('/chats')) return 2;
    if (path.startsWith('/profile')) return 3;
    return 0;
  }

  static const _routes = ['/discovery', '/explore', '/chats', '/profile'];

  /// Même base que le scaffold (profil, réglages, onglets) — pas de teinte bleue ni surface blanche isolée.
  static BoxDecoration _navBarDecorationFor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: context.oklScaffold,
      border: Border(
        top: BorderSide(color: context.oklDivider, width: 0.5),
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.32)
              : Colors.black.withValues(alpha: 0.06),
          blurRadius: isDark ? 14 : 10,
          offset: const Offset(0, -2),
        ),
      ],
    );
  }

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
        extendBody: true,
        body: widget.child,
        bottomNavigationBar: DecoratedBox(
          decoration: _navBarDecorationFor(context),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: kOklMainNavContentHeight,
              child: Row(
                children: [
                  _NavItem(
                    icon: LucideIcons.home,
                    label: 'Rencontres',
                    index: 0,
                    selected: selectedIndex == 0,
                    onTap: () => context.go(_routes[0]),
                  ),
                  _NavItem(
                    icon: LucideIcons.heartHandshake,
                    label: 'Sorties',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = selected
        ? AppColors.primary
        : (isDark ? Colors.white : Colors.black);

    final labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      color: accent,
    );

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ],
        ),
      ),
    );
  }
}
