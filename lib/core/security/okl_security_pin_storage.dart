import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage local du code PIN (Keychain / Keystore). Pas synchronisé avec le serveur.
class OklSecurityPinStorage {
  OklSecurityPinStorage._();

  static const _key = 'oklifor_security_pin_v1';
  static final FlutterSecureStorage _s = const FlutterSecureStorage();

  static Future<bool> hasPin() async {
    final v = await _s.read(key: _key);
    return v != null && v.length >= 4;
  }

  static Future<bool> verify(String pin) async {
    final v = await _s.read(key: _key);
    return v == pin;
  }

  static Future<void> setPin(String pin) async {
    await _s.write(key: _key, value: pin);
  }

  static Future<void> clearPin() async {
    await _s.delete(key: _key);
  }
}
