import 'dart:async';
import 'dart:convert';
import 'package:date_and_doing/models/dd_date.dart';
import 'package:http/http.dart' as http;

import 'package:date_and_doing/api/api_endpoints.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';

class ApiService {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  Completer<void>? _refreshCompleter;

  String _cleanToken(String token) {
    return token.trim().replaceAll('\n', '').replaceAll('\r', '');
  }

  String _pickAccess(Map<String, dynamic> json) {
    final v = json['access_token'] ?? json['access'];
    if (v == null) throw Exception('Respuesta sin access_token/access');
    return v.toString();
  }

  String? _pickRefresh(Map<String, dynamic> json) {
    final v = json['refresh_token'] ?? json['refresh'];
    return v?.toString();
  }

  bool _shouldRefresh(http.Response res) {
    if (res.statusCode != 401) return false;
    final b = res.body;
    return b.contains('token_not_valid') || b.contains('AccessToken');
  }

  Future<String> _getValidAccessToken() async {
    String? access = await _prefs.getAccessToken();
    if (access != null && access.isNotEmpty) return access;

    final refresh = await _prefs.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw Exception('No hay sesión válida (sin refresh_token).');
    }

    final ok = await _ensureRefresh();
    if (!ok) throw Exception('Sesión expirada (refresh falló).');

    access = await _prefs.getAccessToken();
    if (access == null || access.isEmpty) {
      throw Exception('No se obtuvo nuevo access_token.');
    }

    return access;
  }

  Future<http.Response> _requestWithRefresh(
    Future<http.Response> Function(String token) request,
  ) async {
    final access = await _getValidAccessToken();
    final res = await request(access);

    if (!_shouldRefresh(res)) return res;

    final ok = await _ensureRefresh();
    if (!ok) throw Exception('Sesión expirada (refresh falló).');

    final newAccess = await _prefs.getAccessToken();
    if (newAccess == null || newAccess.isEmpty) {
      throw Exception('No se obtuvo nuevo access_token.');
    }

    return request(newAccess);
  }

  Future<bool> _ensureRefresh() async {
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      final a = await _prefs.getAccessToken();
      return a != null && a.isNotEmpty;
    }

    _refreshCompleter = Completer<void>();

    try {
      final refresh = await _prefs.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        return false;
      }

      final data = await refreshToken(refreshToken: refresh);

      final newAccess = _pickAccess(data);
      await _prefs.saveAccessToken(newAccess);

      final newRefresh = _pickRefresh(data);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _prefs.saveRefreshToken(newRefresh);
      }

      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    }
  }

  Future<void> warmRefreshIfNeeded() async {
    final refresh = await _prefs.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return;

    final data = await refreshToken(refreshToken: refresh);

    final newAccess = _pickAccess(data);
    await _prefs.saveAccessToken(newAccess);

    final newRefresh = _pickRefresh(data);
    if (newRefresh != null && newRefresh.isNotEmpty) {
      await _prefs.saveRefreshToken(newRefresh);
    }
  }

  // ================== LOGIN FIREBASE ==================
  Future<Map<String, dynamic>> apiLoginFirebase(String firebaseIdToken) async {
    final cleanToken = _cleanToken(firebaseIdToken);

    final response = await http.post(
      Uri.parse(ApiEndpoints.login),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Service-Code': 'dateanddo',
      },
      body: jsonEncode({'firebase_id_token': cleanToken}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final access = _pickAccess(data);
      await _prefs.saveAccessToken(access);

      final refresh = _pickRefresh(data);
      if (refresh != null && refresh.isNotEmpty) {
        await _prefs.saveRefreshToken(refresh);
      }

      return data;
    }

    throw Exception(
      'Failed to login: ${response.statusCode} - ${response.body}',
    );
  }

  // ================== INFO USER ==================
  Future<Map<String, dynamic>> infoUser({required String accessToken}) async {
    final response = await _requestWithRefresh((token) {
      return http.get(
        Uri.parse(ApiEndpoints.infoUser),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to get user info: ${response.statusCode} - ${response.body}',
    );
  }

  // ================== PATCH DEVICE (FCM y/o Ubicación) ==================
  Future<void> patchUserDevice({
    required int userId,
    String? fcmToken,
    double? latitude,
    double? longitude,
  }) async {
    final payload = <String, dynamic>{};

    if (fcmToken != null && fcmToken.isNotEmpty) {
      payload['use_txt_fcm'] = fcmToken;
    }
    if (latitude != null) payload['use_double_latitude'] = latitude;
    if (longitude != null) payload['use_double_longitude'] = longitude;

    if (payload.isEmpty) return;

    final response = await _requestWithRefresh((token) {
      return http.patch(
        Uri.parse('${ApiEndpoints.fcmToken}$userId/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Service-Code': 'dateanddo',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
    });

    if (response.statusCode == 200 || response.statusCode == 201) return;

    throw Exception(
      'Failed to patch user device: ${response.statusCode} - ${response.body}',
    );
  }

  // ================== (TU FUNCIÓN ORIGINAL) FCM ==================
  Future<void> apiFcm(
    String fcmToken,
    int id,
    double latitude,
    double longitude,
    String accessToken,
  ) async {
    final response = await _requestWithRefresh((token) {
      return http.patch(
        Uri.parse('${ApiEndpoints.fcmToken}$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Service-Code': 'dateanddo',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'use_txt_fcm': fcmToken,
          'use_double_latitude': latitude,
          'use_double_longitude': longitude,
        }),
      );
    });

    if (response.statusCode == 200 || response.statusCode == 201) return;

    throw Exception(
      'Failed to register FCM token: ${response.statusCode} - ${response.body}',
    );
  }

  // ================== SUGERENCIAS ==================
  Future<List<Map<String, dynamic>>> sugerenciasMatch({
    required String accessToken,
  }) async {
    final response = await _requestWithRefresh((token) {
      return http.get(
        Uri.parse(ApiEndpoints.sugerenciasMatch),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      'Failed to get suggestions: ${response.statusCode} - ${response.body}',
    );
  }

  // ================== LIKES ==================
  Future<void> likes({
    required String accessToken,
    required int targetUserId,
    required String type,
  }) async {
    final response = await _requestWithRefresh((token) {
      return http.post(
        Uri.parse(ApiEndpoints.swipes),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'use_int_target': targetUserId,
          'ddw_txt_action': type,
        }),
      );
    });

    if (response.statusCode == 200 || response.statusCode == 201) return;

    throw Exception(
      'Failed to like user: ${response.statusCode} - ${response.body}',
    );
  }



  Future<Map<String, dynamic>> swipeRaw({
  required int targetUserId,
  required String action, // "LIKE" o "DISLIKE"
}) async {
  final response = await _requestWithRefresh((token) {
    return http.post(
      Uri.parse(ApiEndpoints.swipes),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'use_int_target': targetUserId,
        'ddw_txt_action': action,
      }),
    );
  });

  // 👇 imprime todo para ver qué llega
  print("SWIPE STATUS: ${response.statusCode}");
  print("SWIPE BODY: ${response.body}");

  if (response.statusCode == 200 || response.statusCode == 201) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  throw Exception("Swipe failed: ${response.statusCode} - ${response.body}");
}




  // ================== REFRESH TOKEN ==================
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.refreshToken),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Service-Code': 'dateanddo',
      },
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401 &&
        (response.body.contains('token_not_valid') ||
            response.body.contains('Token is invalid') ||
            response.body.contains('invalid'))) {
      await _prefs.clearSession();
    }

    throw Exception(
      'Failed to refresh token: ${response.statusCode} - ${response.body}',
    );
  }

  //==================Todos los Matches =====================//
  Future<List<Map<String, dynamic>>> allMatches({
    required String accessToken,
  }) async {
    final response = await _requestWithRefresh((token) {
      return http.get(
        Uri.parse(ApiEndpoints.allMatches),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      'Failed to get all matches: ${response.statusCode} - ${response.body}',
    );
  }

  //==================Todos los Chats =====================//
  Future<List<Map<String, dynamic>>> allChats({
    required String accessToken,
  }) async {
    final response = await _requestWithRefresh((token) {
      return http.get(
        Uri.parse(ApiEndpoints.allChats),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      'Failed to get all chats: ${response.statusCode} - ${response.body}',
    );
  }

  //=================== Editar Perfil ==========================//
  Future<void> editarPerfil({
    required String accessToken,
    required Map<String, dynamic> perfilData,
    required int id,
  }) async {
    final response = await _requestWithRefresh((token) {
      return http.patch(
        Uri.parse('${ApiEndpoints.editarPerfil}$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(perfilData),
      );
    });

    if (response.statusCode == 200 || response.statusCode == 201) return;

    throw Exception(
      'Failed to edit profile: ${response.statusCode} - ${response.body}',
    );
  }

  //==================== citas =============================//

  Future<Map<String, dynamic>> createDate({
    required int matchId,
    required String title,
    required String description,
    required DateTime scheduledLocal, // hora local del usuario (Perú -05)
  }) async {
    // Formato tipo: 2026-01-15T18:30:00-05:00
    // Construimos ISO con offset local.
    final offset = scheduledLocal.timeZoneOffset;
    final sign = offset.isNegative ? "-" : "+";
    final hh = offset.inHours.abs().toString().padLeft(2, "0");
    final mm = (offset.inMinutes.abs() % 60).toString().padLeft(2, "0");
    final isoWithOffset =
        "${scheduledLocal.toIso8601String().substring(0, 19)}$sign$hh:$mm";

    final payload = {
      "ddm_int_id": matchId,
      "ddd_txt_title": title,
      "ddd_txt_description": description,
      "ddd_timestamp_date": isoWithOffset,
    };

    final response = await _requestWithRefresh((token) {
      return http.post(
        Uri.parse(ApiEndpoints.dates),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-Service-Code": "dateanddo",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      );
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      "Failed to create date: ${response.statusCode} - ${response.body}",
    );
  }

  Future<List<Map<String, dynamic>>> allDates() async {
    final response = await _requestWithRefresh((token) {
      return http.get(
        Uri.parse(ApiEndpoints.dates), // /api/dateanddo/dates/
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Service-Code': 'dateanddo',
          'Authorization': 'Bearer $token',
        },
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      'Failed to get dates: ${response.statusCode} - ${response.body}',
    );
  }

  // ================================================================//

  Future<List<DdDate>> getDatesForMatch(int matchId) async {
    final response = await _requestWithRefresh((token) {
      return http.get(
        Uri.parse(ApiEndpoints.dates),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Service-Code': 'dateanddo',
          'Authorization': 'Bearer $token',
        },
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> raw = jsonDecode(response.body);
      final list = raw.cast<Map<String, dynamic>>();

      final filtered = list.where((d) => d["ddm_int_id"] == matchId).toList();

      return filtered.map((j) => DdDate.fromJson(j)).toList();
    }

    throw Exception(
      'Failed to get dates: ${response.statusCode} - ${response.body}',
    );
  }

  Future<Map<String, dynamic>> patchDate({
    required int dateId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _requestWithRefresh((token) {
      return http.patch(
        Uri.parse(ApiEndpoints.dateById(dateId)),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-Service-Code": "dateanddo",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(data),
      );
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      "Failed to patch date: ${response.statusCode} - ${response.body}",
    );
  }

  Future<void> confirmDate(int dateId) async {
    await patchDate(dateId: dateId, data: {"ddd_txt_status": "CONFIRMADA"});
  }

  Future<void> rejectDate(int dateId) async {
    await patchDate(dateId: dateId, data: {"ddd_txt_status": "RECHAZADA"});
  }

  Future<Map<String, dynamic>> sendMessage({
    required int matchId,
    required int receiverId,
    required String body,
  }) async {
    final payload = {
      "ddm_int_id": matchId,
      "use_int_receiver": receiverId,
      "ddmsg_txt_body": body,
    };

    final response = await _requestWithRefresh((token) {
      return http.post(
        Uri.parse(ApiEndpoints.messages),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-Service-Code": "dateanddo",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      );
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      "Failed to send message: ${response.statusCode} - ${response.body}",
    );
  }

  Future<Map<String, dynamic>> getPreferences() async {
    final response = await _requestWithRefresh((token) {
      return http.get(
        Uri.parse(ApiEndpoints.preferencias),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-Service-Code": "dateanddo",
          "Authorization": "Bearer $token",
        },
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      "Failed to get preferences: ${response.statusCode} - ${response.body}",
    );
  }

  Future<Map<String, dynamic>> updateMatchPreferences({
    required int userId,
    required String targetGender,
    required int minAge,
    required int maxAge,
    required String lookingFor,
  }) async {
    final payload = {
      "use_txt_pref_target_gender": targetGender,
      "use_int_pref_min_age": minAge,
      "use_int_pref_max_age": maxAge,
      "use_txt_pref_looking_for": lookingFor,
    };

    final response = await _requestWithRefresh((token) {
      return http.patch(
        Uri.parse(ApiEndpoints.editPreferencias(userId)),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-Service-Code": "dateanddo",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      );
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      "Failed to update preferences: ${response.statusCode} - ${response.body}",
    );
  }

  Future<List<Map<String, dynamic>>> getMessagesByMatch(int matchId) async {
    final response = await _requestWithRefresh((token) {
      return http.get(
        Uri.parse(ApiEndpoints.messagesByMatch(matchId)),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-Service-Code": "dateanddo",
          "Authorization": "Bearer $token",
        },
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      "Failed to get messages: ${response.statusCode} - ${response.body}",
    );
  }

  // ================== TODOS LOS MENSAJES (ALL) ==================
  Future<List<Map<String, dynamic>>> getAllMessages() async {
    final response = await _requestWithRefresh((token) {
      return http.get(
        Uri.parse(ApiEndpoints.messages), // /api/dateanddo/messages/
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-Service-Code": "dateanddo",
          "Authorization": "Bearer $token",
        },
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      "Failed to get all messages: ${response.statusCode} - ${response.body}",
    );
  }

  // ================== TODOS LOS MATCHES (para nombre/foto) ==================
  Future<List<Map<String, dynamic>>> getAllMatches() async {
    final response = await _requestWithRefresh((token) {
      return http.get(
        Uri.parse(ApiEndpoints.allMatches), // /api/dateanddo/matches/
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-Service-Code": "dateanddo",
          "Authorization": "Bearer $token",
        },
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      "Failed to get all matches: ${response.statusCode} - ${response.body}",
    );
  }

  Future<List<Map<String, dynamic>>> getLugares(String category) async {
    final url = ApiEndpoints.lugares(category);

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Accept": "application/json",
        "x-api-key": "ESTAESTUAPIKEYDESCRAPINGDEPAGA",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // ✅ Tu API devuelve { ok: true, items: [...] }
      if (decoded is Map<String, dynamic>) {
        final items = decoded["items"];
        if (items is List) {
          return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      }

      // Si algún día devuelve lista directa, también lo soportamos
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      return [];
    }

    throw Exception(
      "Failed to get lugares: ${response.statusCode} - ${response.body}",
    );
  }
}
