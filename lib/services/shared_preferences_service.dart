import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_and_doing/services/secure_storage_service.dart';

class SharedPreferencesService {
  static String keyIsLogged = 'is_logged';
  static String keyUid = 'uid';
  static String keyEmail = 'email';
  static String keyPhone = 'phone';
  static String keyPhoto = 'photo_url';

  static String firetoken = 'fire_token';
  static String fcmToken = 'fcm_token';

  static String keyUserInfo = 'user_info';

  // Se mantienen para compatibilidad, pero los tokens ya no se guardan aquí.
  static String keyAccessToken = 'access_token';
  static String keyRefreshToken = 'refresh_token';

  final SecureStorageService _secureStorage = SecureStorageService();

  Future<void> saveUserSession({
    required String uid,
    String? email,
    String? phone,
    String? photoUrl,
    String? firebaseIdToken,
    required String accessToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(keyIsLogged, true);
    await prefs.setString(keyUid, uid);

    if (email != null) {
      await prefs.setString(keyEmail, email);
    }

    if (phone != null) {
      await prefs.setString(keyPhone, phone);
    }

    if (photoUrl != null) {
      await prefs.setString(keyPhoto, photoUrl);
    }

    if (firebaseIdToken != null && firebaseIdToken.isNotEmpty) {
      await prefs.setString(firetoken, firebaseIdToken);
    }

    // Tokens a secure storage
    await _secureStorage.saveAccessToken(accessToken);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.saveRefreshToken(refreshToken);
    }
  }

  Future<void> saveAccessToken(String accessToken) async {
    await _secureStorage.saveAccessToken(accessToken);
  }

  Future<String?> getAccessToken() async {
    return _secureStorage.getAccessToken();
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _secureStorage.saveRefreshToken(refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return _secureStorage.getRefreshToken();
  }

  Future<bool> hasRefreshToken() async {
    return _secureStorage.hasRefreshToken();
  }

  Future<bool> hasAccessToken() async {
    return _secureStorage.hasAccessToken();
  }

  Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUserInfo, jsonEncode(userInfo));
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoString = prefs.getString(keyUserInfo);

    if (userInfoString == null || userInfoString.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(userInfoString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLogged() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsLogged) ?? false;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
    await _secureStorage.clearTokens();
  }

  Future<int?> getUserId() async {
    final info = await getUserInfo();
    if (info == null) return null;

    final v = info["use_int_id"] ?? info["id"] ?? info["user_id"];
    if (v == null) return null;

    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  Future<int> getUserIdOrThrow() async {
    final id = await getUserId();
    if (id == null || id <= 0) {
      throw Exception(
        "No se encontró use_int_id en user_info. Vuelve a iniciar sesión.",
      );
    }
    return id;
  }

  // ================== DISTANCIA MÁXIMA DE BÚSQUEDA ==================
  static String keyMaxDistance = 'max_distance';

  Future<void> saveMaxDistance(int km) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyMaxDistance, km);
  }

  Future<int> getMaxDistance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyMaxDistance) ?? 50;
  }

  // ================== BOOL / STRING GENÉRICOS ==================

  Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  Future<void> saveStringValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getStringValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
