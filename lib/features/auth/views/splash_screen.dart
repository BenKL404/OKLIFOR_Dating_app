import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/oklifor_api_exception.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/app_local_cache.dart';
import '../providers/auth_api_provider.dart';
import '../utils/apply_post_login.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 200), _bootstrap);
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final storage = ref.read(authTokenStorageProvider);
    final client = ref.read(okliforApiClientProvider);
    final token = await storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        final me = await client.fetchMe();
        await AppLocalCache.saveMe(me);
        if (mounted) applyMeAndGoHome(context, me);
        return;
      } on OkliforApiException catch (e) {
        // Si token expiré => logout. Si hors-ligne => démarrage en cache.
        if (e.statusCode == 401 || e.statusCode == 403) {
          await client.logout();
        } else {
          final userId = await storage.readUserId();
          final cached = userId == null ? null : await AppLocalCache.loadMe(userId);
          if (cached != null && mounted) {
            applyMeAndGoHome(context, cached);
            return;
          }
        }
      } catch (_) {
        final userId = await storage.readUserId();
        final cached = userId == null ? null : await AppLocalCache.loadMe(userId);
        if (cached != null && mounted) {
          applyMeAndGoHome(context, cached);
          return;
        }
      }
    }
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blob rose haut gauche
          Positioned(
            top: -100, left: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.withAlpha(80), Colors.transparent],
                ),
              ),
            ),
          ),
          // Blob secondaire bas droite
          Positioned(
            bottom: -80, right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.secondary.withAlpha(50), Colors.transparent],
                ),
              ),
            ),
          ),
          // Contenu centré
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Center(
                    child: Text('♥', style: TextStyle(fontSize: 42, color: Colors.white)),
                  ),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .fade(duration: 300.ms),
                const SizedBox(height: 28),
                Text(
                  'Oklifor',
                  style: TextStyle(
                    color: context.oklOnSurface,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    fontFamilyFallback: const ['Helvetica'],
                  ),
                ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.18, end: 0),
                const SizedBox(height: 4),
                Text(
                  'Rencontres au Togo',
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.62),
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ).animate().fadeIn(delay: 120.ms),
              ],
            ),
          ),
          // Loading bar en bas
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                  backgroundColor: AppColors.primary.withAlpha(25),
                ),
              ),
            ).animate().fadeIn(delay: 180.ms),
          ),
        ],
      ),
    );
  }
}
