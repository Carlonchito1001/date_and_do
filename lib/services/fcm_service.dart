import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:date_and_doing/services/notificacion_service.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/navigation/app_navigator.dart';
import 'package:date_and_doing/views/home/dd_chat_page.dart';
import 'package:date_and_doing/views/home/matches/match_profile_page.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();

    final prefs = await SharedPreferences.getInstance();
    final sounds = prefs.getBool("sounds") ?? true;

    final type = (message.data['type'] ?? '').toString().toUpperCase();
    final title = message.notification?.title ?? 'Date & Doing';
    final body = message.notification?.body ?? 'Tienes una nueva notificación';

    debugPrint('📩 [BG] Mensaje: ${message.messageId}');
    debugPrint('📦 [BG] TYPE: $type');
    debugPrint('📦 [BG] DATA: ${message.data}');

    await NotificacionService.showSimpleNotification(
      title: title,
      body: body,
      playSound: sounds,
      payloadData: Map<String, dynamic>.from(message.data),
    );
  } catch (e) {
    debugPrint('⚠️ Error en firebaseMessagingBackgroundHandler: $e');
  }
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static String? currentToken;

  static bool _isInitialized = false;
  static bool _listenersRegistered = false;

  static bool _isNavigating = false;
  static String? _lastRouteKey;
  static DateTime? _lastNavigationAt;

  /*
  |--------------------------------------------------------------------------
  | Keys locales para FCM
  |--------------------------------------------------------------------------
  | SharedPreferencesService.fcmToken:
  | - último token FCM obtenido desde Firebase.
  |
  | _keyFcmPendingSync:
  | - true cuando el token existe pero todavía no se pudo enviar al backend.
  |
  | _keyLastFcmSynced:
  | - último token que sí fue enviado correctamente al backend.
  |--------------------------------------------------------------------------
  */

  static const String _keyFcmPendingSync = 'fcm_pending_sync';
  static const String _keyLastFcmSynced = 'last_fcm_synced';

  static Future<void> initFCM() async {
    debugPrint('🚀 Entrando a initFCM');

    if (_isInitialized) {
      debugPrint(
        'ℹ️ FCM ya estaba inicializado, intentando refrescar/sincronizar token...',
      );

      await obtainAndStoreFcmToken();
      await syncTokenWithBackendIfPossible();

      debugPrint('✅ Reintento FCM terminado');
      return;
    }

    _isInitialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermissionSafe();

    await obtainAndStoreFcmToken();

    _registerListenersOnce();

    await _checkInitialMessage();

    await syncTokenWithBackendIfPossible();

    debugPrint('✅ initFCM terminó');
  }

  static Future<void> _requestPermissionSafe() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('🔔 Permiso notificaciones: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('⚠️ No se pudo solicitar permiso de notificaciones: $e');
    }
  }

  static void _registerListenersOnce() {
    if (_listenersRegistered) {
      debugPrint('ℹ️ Listeners FCM ya estaban registrados');
      return;
    }

    _listenersRegistered = true;

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) async {
        try {
          if (token.isEmpty) {
            debugPrint('⚠️ onTokenRefresh devolvió token vacío');
            await _markFcmPendingSync(true);
            return;
          }

          currentToken = token;

          await _saveFcmTokenLocally(token);

          debugPrint('♻️ FCM TOKEN renovado y guardado localmente');

          await syncTokenWithBackendIfPossible();
        } catch (e) {
          debugPrint('⚠️ Error guardando token actualizado: $e');
          await _markFcmPendingSync(true);
        }
      },
      onError: (error) async {
        debugPrint('⚠️ Error en onTokenRefresh: $error');
        await _markFcmPendingSync(true);
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      try {
        debugPrint('📩 [FG] Mensaje: ${message.messageId}');
        debugPrint(
          '📦 [FG] TYPE: ${(message.data['type'] ?? '').toString().toUpperCase()}',
        );
        debugPrint('📦 [FG] DATA: ${message.data}');

        final prefs = await SharedPreferences.getInstance();
        final sounds = prefs.getBool("sounds") ?? true;

        final title = message.notification?.title ?? 'Date & Doing';
        final body =
            message.notification?.body ?? 'Tienes una nueva notificación';

        await NotificacionService.showSimpleNotification(
          title: title,
          body: body,
          playSound: sounds,
          payloadData: Map<String, dynamic>.from(message.data),
        );
      } catch (e) {
        debugPrint('⚠️ Error procesando mensaje foreground: $e');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      try {
        debugPrint('👉 onMessageOpenedApp: ${message.messageId}');
        debugPrint('📦 [OPENED] DATA: ${message.data}');

        await _handleNotificationNavigation(message.data);
      } catch (e) {
        debugPrint('⚠️ Error en onMessageOpenedApp: $e');
      }
    });
  }

  static Future<void> _checkInitialMessage() async {
    try {
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();

      if (initialMessage != null) {
        debugPrint('🚀 App abierta desde notificación cerrada');
        debugPrint('📦 [INITIAL] DATA: ${initialMessage.data}');

        await _handleNotificationNavigation(initialMessage.data);
      }
    } catch (e) {
      debugPrint('⚠️ Error leyendo initialMessage: $e');
    }
  }

  /*
  |--------------------------------------------------------------------------
  | FCM TOKEN: obtener, guardar y leer seguro
  |--------------------------------------------------------------------------
  */

  static Future<String?> obtainAndStoreFcmToken({int maxAttempts = 4}) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final token = await _messaging.getToken();

        if (token != null && token.isNotEmpty) {
          currentToken = token;

          await _saveFcmTokenLocally(token);

          debugPrint('✅ FCM TOKEN obtenido y guardado en intento $attempt');

          return token;
        }

        debugPrint('⚠️ FCM token vacío en intento $attempt');
      } catch (e) {
        debugPrint('⚠️ Error obteniendo FCM token intento $attempt: $e');
      }

      await Future.delayed(Duration(seconds: attempt * 2));
    }

    debugPrint(
      '❌ No se pudo obtener FCM token después de $maxAttempts intentos',
    );

    await _markFcmPendingSync(true);
    return null;
  }

  static Future<String?> getTokenWithRetry({int maxAttempts = 4}) async {
    return obtainAndStoreFcmToken(maxAttempts: maxAttempts);
  }

  static Future<String?> getSafeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedToken = prefs.getString(SharedPreferencesService.fcmToken);

      if (savedToken != null && savedToken.isNotEmpty) {
        currentToken = savedToken;
        debugPrint('✅ FCM TOKEN leído de SharedPreferences');
        return savedToken;
      }

      return await obtainAndStoreFcmToken();
    } catch (e) {
      debugPrint('⚠️ getSafeToken falló, se continuará sin FCM token: $e');
      await _markFcmPendingSync(true);
      return null;
    }
  }

  static Future<void> _saveFcmTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(SharedPreferencesService.fcmToken, token);
    await prefs.setBool(_keyFcmPendingSync, true);

    currentToken = token;

    debugPrint('✅ FCM token guardado localmente y marcado como pendiente');
  }

  static Future<void> _markFcmPendingSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFcmPendingSync, value);
  }

  static Future<bool> isFcmPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFcmPendingSync) ?? false;
  }

  static Future<String?> _getLastSyncedFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastFcmSynced);
  }

  static Future<void> _markFcmSynced(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyLastFcmSynced, token);
    await prefs.setBool(_keyFcmPendingSync, false);

    debugPrint('✅ FCM token marcado como sincronizado');
  }

  /*
  |--------------------------------------------------------------------------
  | Sincronizar FCM con backend
  |--------------------------------------------------------------------------
  */

  static Future<void> syncTokenWithBackendIfPossible() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? token = prefs.getString(SharedPreferencesService.fcmToken);

      token ??= currentToken;

      if (token == null || token.isEmpty) {
        debugPrint('ℹ️ No hay FCM local, intentando obtener uno nuevo...');
        token = await obtainAndStoreFcmToken();
      }

      if (token == null || token.isEmpty) {
        debugPrint('⚠️ No hay FCM token para enviar al backend');
        await _markFcmPendingSync(true);
        return;
      }

      /*
      IMPORTANTE:
      Antes estaba leyendo el access token directo desde SharedPreferences:
      prefs.getString(SharedPreferencesService.keyAccessToken)

      Pero en tu flujo los tokens deben leerse desde SharedPreferencesService(),
      porque ahí puede estar usando SecureStorage internamente.
      */
      final accessToken = await SharedPreferencesService().getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('⚠️ No hay accessToken, FCM queda pendiente');
        await _markFcmPendingSync(true);
        return;
      }

      final lastSyncedToken = await _getLastSyncedFcmToken();

      if (lastSyncedToken == token) {
        debugPrint('ℹ️ FCM token ya estaba sincronizado, no se reenvía');
        await _markFcmPendingSync(false);
        return;
      }

      final userinfo = await ApiService().infoUser(accessToken: accessToken);

      final userId = _toIntSafe(userinfo['use_int_id']);

      if (userId == null || userId <= 0) {
        debugPrint('⚠️ infoUser no devolvió use_int_id válido');
        await _markFcmPendingSync(true);
        return;
      }

      await ApiService().patchUserDevice(
        userId: userId,
        fcmToken: token,
        latitude: null,
        longitude: null,
      );

      await _markFcmSynced(token);

      debugPrint('✅ FCM token sincronizado con backend');
    } catch (e) {
      debugPrint('⚠️ No se pudo sincronizar FCM token con backend: $e');
      await _markFcmPendingSync(true);
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Reintento manual recomendado después del login
  |--------------------------------------------------------------------------
  | Llama esto justo después de guardar access/refresh token.
  |--------------------------------------------------------------------------
  */

  static Future<void> afterLoginSync() async {
    debugPrint('🔐 afterLoginSync FCM iniciado');

    await obtainAndStoreFcmToken();
    await syncTokenWithBackendIfPossible();

    debugPrint('✅ afterLoginSync FCM terminado');
  }

  /*
  |--------------------------------------------------------------------------
  | Utilidades
  |--------------------------------------------------------------------------
  */

  static int? _toIntSafe(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  /*
  |--------------------------------------------------------------------------
  | Navegación desde notificaciones
  |--------------------------------------------------------------------------
  */

  static bool _shouldSkipDuplicateNavigation(String routeKey) {
    final now = DateTime.now();

    if (_isNavigating) {
      debugPrint('⚠️ Navegación bloqueada: ya hay una en progreso');
      return true;
    }

    if (_lastRouteKey == routeKey && _lastNavigationAt != null) {
      final diff = now.difference(_lastNavigationAt!).inMilliseconds;

      if (diff < 1800) {
        debugPrint('⚠️ Navegación duplicada evitada: $routeKey');
        return true;
      }
    }

    return false;
  }

  static Future<void> _handleNotificationNavigation(
    Map<String, dynamic> data,
  ) async {
    try {
      final type = (data['type'] ?? '').toString().toUpperCase();
      final matchId = int.tryParse((data['match_id'] ?? '').toString());

      debugPrint('🧭 Navegación por notificación push');
      debugPrint('TYPE => $type');
      debugPrint('MATCH_ID => $matchId');

      if (matchId == null || matchId <= 0) {
        debugPrint('⚠️ match_id inválido o ausente');
        return;
      }

      final routeKey = '$type-$matchId';

      if (_shouldSkipDuplicateNavigation(routeKey)) return;

      final context = appNavigatorKey.currentContext;

      if (context == null) {
        debugPrint('⚠️ navigator context no disponible');
        return;
      }

      _isNavigating = true;
      _lastRouteKey = routeKey;
      _lastNavigationAt = DateTime.now();

      final api = ApiService();

      if (type == 'MATCH') {
        try {
          await api.getMatchProfile(matchId);
        } catch (e) {
          debugPrint('⚠️ Aún no se pudo cargar getMatchProfile($matchId): $e');
          return;
        }

        if (!context.mounted) return;

        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MatchProfilePage(matchId: matchId)),
        );

        return;
      }

      if (type == 'MESSAGE') {
        try {
          await api.getMatchTimeline(matchId);
        } catch (e) {
          debugPrint('⚠️ Aún no se pudo cargar getMatchTimeline($matchId): $e');
          return;
        }

        final allMatches = await api.getAllMatches();

        Map<String, dynamic>? foundMatch;

        for (final item in allMatches) {
          final itemMatchId = int.tryParse(
            (item["ddm_int_id"] ?? "").toString(),
          );

          if (itemMatchId == matchId) {
            foundMatch = item;
            break;
          }
        }

        if (foundMatch == null) {
          debugPrint('⚠️ No se encontró el match para abrir el chat');
          return;
        }

        final other = foundMatch["other_user"];

        if (other is! Map<String, dynamic>) {
          debugPrint('⚠️ other_user inválido en match');
          return;
        }

        final otherUserId =
            int.tryParse((other["use_int_id"] ?? "0").toString()) ?? 0;

        final nombre = (other["fullname"] ?? "Chat").toString();

        final foto = (other["photo_fallback_url"] ?? other["photo"] ?? "")
            .toString();

        final fotoBase64 = other["photo_preview_base64"]?.toString();

        if (!context.mounted) return;

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DdChatPage(
              matchId: matchId,
              otherUserId: otherUserId,
              nombre: nombre,
              foto: foto,
              fotoBase64: fotoBase64,
            ),
          ),
        );

        return;
      }

      debugPrint('ℹ️ Tipo de notificación no manejado: $type');
    } catch (e) {
      debugPrint('❌ Error navegando desde notificación: $e');
    } finally {
      _isNavigating = false;
    }
  }
}
