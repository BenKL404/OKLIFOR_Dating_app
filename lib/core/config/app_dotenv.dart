import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Charge [assets/.env] une seule fois au démarrage ([main]).
class AppDotEnv {
  AppDotEnv._();

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    await dotenv.load(fileName: 'assets/.env');
    _loaded = true;
  }

  static String? get(String key) {
    final v = dotenv.env[key]?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }
}
