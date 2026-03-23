import 'package:go_router/go_router.dart';
import '../../features/auth/models/otp_route_extra.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/otp_screen.dart';
import '../../features/discovery/views/discovery_screen.dart';
import '../../features/chat/views/chat_list_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/profile/views/profile_onboarding_screen.dart';
import '../../features/profile/views/settings_screen.dart';
import '../../features/profile/views/invite_friends_screen.dart';
import '../../features/explore/views/explore_screen.dart';
import '../widgets/main_shell.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileOnboardingScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra;
          final OtpRouteExtra args;
          if (extra is OtpRouteExtra) {
            args = extra;
          } else if (extra is String) {
            args = OtpRouteExtra(phoneE164: extra);
          } else {
            args = const OtpRouteExtra(phoneE164: '');
          }
          return OtpScreen(extra: args);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/invite-friends',
        builder: (context, state) => const InviteFriendsScreen(),
      ),
      // Coquille principale avec barre de navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/discovery',
            builder: (context, state) => const DiscoveryScreen(),
          ),
          GoRoute(
            path: '/explore',
            builder: (context, state) => const ExploreScreen(),
          ),
          GoRoute(
            path: '/chats',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
