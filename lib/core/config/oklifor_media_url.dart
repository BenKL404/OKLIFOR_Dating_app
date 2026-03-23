import 'oklifor_api_config.dart';

/// URLs renvoyées par l’API pour avatar / couverture : chemin relatif ou URL absolue.
class OkliforMediaUrl {
  OkliforMediaUrl._();

  static String resolve(String stored) {
    final t = stored.trim();
    if (t.isEmpty) {
      return t;
    }
    if (t.startsWith('http://') || t.startsWith('https://')) {
      return t;
    }
    if (t.startsWith('/')) {
      return '${OkliforApiConfig.baseUrl}$t';
    }
    return t;
  }
}
