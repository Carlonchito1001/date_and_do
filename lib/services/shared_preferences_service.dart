import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static String keyIsLogged = 'is_logged';
  static String keyUid = 'uid';
  static String keyEmail = 'email';
  static String keyPhone = 'phone';
  static String keyPhoto = 'photo_url';

  static String firetoken = 'fire_token';
  static String fcmToken = 'fcm_token';

  static String keyUserInfo = 'user_info';

  static String keyAccessToken = 'access_token';
  static String keyRefreshToken = 'refresh_token';

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

    if (email != null) await prefs.setString(keyEmail, email);
    if (phone != null) await prefs.setString(keyPhone, phone);
    if (photoUrl != null) await prefs.setString(keyPhoto, photoUrl);
    if (firebaseIdToken != null)
      await prefs.setString(firetoken, firebaseIdToken);

    await prefs.setString(keyAccessToken, accessToken);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(keyRefreshToken, refreshToken);
    }
  }

  Future<void> saveAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAccessToken, accessToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyAccessToken);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyRefreshToken, refreshToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyRefreshToken);
  }

  Future<bool> hasRefreshToken() async {
    final r = await getRefreshToken();
    return r != null && r.isNotEmpty;
  }

  Future<bool> hasAccessToken() async {
    final a = await getAccessToken();
    return a != null && a.isNotEmpty;
  }

  Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUserInfo, jsonEncode(userInfo));
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoString = prefs.getString(keyUserInfo);
    if (userInfoString == null) return null;
    return jsonDecode(userInfoString) as Map<String, dynamic>;
  }

  Future<bool> isLogged() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsLogged) ?? false;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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
}
