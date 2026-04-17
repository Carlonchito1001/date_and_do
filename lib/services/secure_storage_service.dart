import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: keyAccessToken, value: accessToken);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: keyAccessToken);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: keyRefreshToken, value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: keyRefreshToken);
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> hasRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: keyAccessToken);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: keyRefreshToken);
  }

  Future<void> clearTokens() async {
    await deleteAccessToken();
    await deleteRefreshToken();
  }
}
