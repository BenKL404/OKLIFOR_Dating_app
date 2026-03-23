import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/app_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_settings.dart';
import 'core/routing/app_router.dart';
import 'core/widgets/app_lock_overlay.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDotEnv.load();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e, st) {
    debugPrint(
      'Firebase non initialisé ($e). '
      'Exécute flutterfire configure et ajoute les fichiers natifs — voir docs/FIREBASE.md',
    );
    debugPrint('$st');
  }
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const OkliforApp(),
    ),
  );
}

class OkliforApp extends ConsumerWidget {
  const OkliforApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Oklifor Dating',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
          ),
        );
        return AppLockOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: AppRouter.router,
    );
  }
}
