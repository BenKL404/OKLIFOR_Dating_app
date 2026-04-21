import 'package:connectivity_plus/connectivity_plus.dart';

/// Indique si l’appareil a une interface réseau active (Wi‑Fi / mobile / ethernet).
/// Ne garantit pas l’accès Internet ni au backend.
Future<bool> oklIsDeviceOnline() async {
  try {
    final r = await Connectivity().checkConnectivity();
    return r.any((x) => x != ConnectivityResult.none);
  } catch (_) {
    return true;
  }
}
