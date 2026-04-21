import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kAccess = 'okl_access_token';
const _kRefresh = 'okl_refresh_token';
const _kUserId = 'okl_user_id';

/// Jetons JWT et identifiant utilisateur (UUID).
class AuthTokenStorage {
  AuthTokenStorage({FlutterSecureStorage? storage})
      : _s = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _s;

  Future<String?> readAccessToken() => _s.read(key: _kAccess);

  Future<String?> readRefreshToken() => _s.read(key: _kRefresh);

  Future<String?> readUserId() => _s.read(key: _kUserId);

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await _s.write(key: _kAccess, value: accessToken);
    await _s.write(key: _kRefresh, value: refreshToken);
    await _s.write(key: _kUserId, value: userId);
  }

  Future<void> clear() async {
    await _s.delete(key: _kAccess);
    await _s.delete(key: _kRefresh);
    await _s.delete(key: _kUserId);
  }
}
