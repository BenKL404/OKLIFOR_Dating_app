import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage local du code PIN (Keychain / Keystore). Pas synchronisé avec le serveur.
class OklSecurityPinStorage {
  OklSecurityPinStorage._();

  static const _key = 'oklifor_security_pin_v1';
  static final FlutterSecureStorage _s = const FlutterSecureStorage();

  /// Anciens codes 4–6 chiffres ; les nouveaux définis dans l’app font 6 chiffres.
  static final RegExp _storedPinPattern = RegExp(r'^\d{4,6}$');

  static Future<bool> hasPin() async {
    final v = await _s.read(key: _key);
    return v != null && _storedPinPattern.hasMatch(v);
  }

  static Future<bool> verify(String pin) async {
    final v = await _s.read(key: _key);
    return v == pin;
  }

  /// Nouveau code : exactement 6 chiffres (affichage type verrouillage téléphone).
  static Future<void> setPin(String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw ArgumentError('Le PIN doit contenir exactement 6 chiffres.');
    }
    await _s.write(key: _key, value: pin);
  }

  static Future<void> clearPin() async {
    await _s.delete(key: _key);
  }
}
