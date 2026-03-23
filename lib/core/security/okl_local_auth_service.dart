import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Biométrie locale (empreinte / Face ID). Inactif sur le web.
class OklLocalAuthService {
  OklLocalAuthService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> deviceSupportsBiometrics() async {
    if (kIsWeb) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Déverrouillage biométrique uniquement (pas le code appareil système).
  Future<bool> authenticateUnlock({required String localizedReason}) async {
    if (kIsWeb) return false;
    try {
      return _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Utilisé pour activer l’option biométrique dans les réglages.
  Future<bool> authenticateEnrollment({required String localizedReason}) async {
    if (kIsWeb) return false;
    try {
      return _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
