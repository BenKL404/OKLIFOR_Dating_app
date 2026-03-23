import 'package:flutter/foundation.dart';

import 'app_dotenv.dart';

/// URL de l’API Spring Boot.
///
/// **Priorité** : `--dart-define=OKLIFOR_API_BASE=...` → `assets/.env` (`OKLIFOR_API_BASE`) → défaut plateforme.
///
/// Défauts sans `.env` ni define (port = défaut `SERVER_PORT` dans `backend/application.yml`) :
/// - **Web** : `http://127.0.0.1:<port>`
/// - **Android émulateur** : `http://10.0.2.2:<port>` (alias machine hôte)
/// - **iOS simulateur / desktop** : `http://127.0.0.1:<port>`
///
/// **Téléphone physique** : mets `OKLIFOR_API_BASE=http://IP_LAN_DU_PC:<port>` dans `assets/.env`
/// (`ipconfig` / Wi‑Fi, même sous-réseau que le téléphone).
class OkliforApiConfig {
  OkliforApiConfig._();

  static const String _envBase = String.fromEnvironment('OKLIFOR_API_BASE');

  static const int _defaultPort = 8100;

  static String _normalizeBase(String raw) {
    final t = raw.trim();
    if (t.endsWith('/')) {
      return t.substring(0, t.length - 1);
    }
    return t;
  }

  static String get baseUrl {
    if (_envBase.isNotEmpty) {
      return _normalizeBase(_envBase);
    }
    final fromDot = AppDotEnv.get('OKLIFOR_API_BASE');
    if (fromDot != null) {
      return _normalizeBase(fromDot);
    }
    if (kIsWeb) {
      final base = Uri.base;
      final scheme = base.scheme == 'https' ? 'https' : 'http';
      return '$scheme://${base.host}:$_defaultPort';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:$_defaultPort';
      default:
        return 'http://127.0.0.1:$_defaultPort';
    }
  }
}
