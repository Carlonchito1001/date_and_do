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
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final type = (message.data['type'] ?? '').toString().toUpperCase();
  final sounds = prefs.getBool("sounds") ?? true;

  final title = message.notification?.title ?? 'Date & Doing';
  final body = message.notification?.body ?? 'Tienes una nueva notificación';

  print('📩 [BG] Mensaje: ${message.messageId}');
  print('📦 [BG] TYPE: $type');
  print('📦 [BG] DATA: ${message.data}');

  await NotificacionService.showSimpleNotification(
    title: title,
    body: body,
    playSound: sounds,
    payloadData: Map<String, dynamic>.from(message.data),
  );
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? currentToken;

  static bool _isNavigating = false;
  static String? _lastRouteKey;
  static DateTime? _lastNavigationAt;

  static Future<void> initFCM() async {
    print("🚀 Entrando a initFCM");

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('🔔 Permiso notificaciones: ${settings.authorizationStatus}');

    currentToken = await _messaging.getToken();
    print('🔥 FCM TOKEN: $currentToken');

    final prefs = await SharedPreferences.getInstance();

    if (currentToken != null && currentToken!.isNotEmpty) {
      await prefs.setString(SharedPreferencesService.fcmToken, currentToken!);
      print('💾 Token guardado en SharedPreferences');
    } else {
      print('⚠️ No se obtuvo token FCM');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      currentToken = token;
      print('♻️ FCM TOKEN REFRESH: $token');
      await prefs.setString(SharedPreferencesService.fcmToken, token);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📩 [FG] Mensaje: ${message.messageId}');
      print(
        '📦 [FG] TYPE: ${(message.data['type'] ?? '').toString().toUpperCase()}',
      );
      print('📦 [FG] DATA: ${message.data}');

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
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print('👉 onMessageOpenedApp: ${message.messageId}');
      print('📦 [OPENED] DATA: ${message.data}');
      await _handleNotificationNavigation(message.data);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print('🚀 App abierta desde notificación cerrada');
      print('📦 [INITIAL] DATA: ${initialMessage.data}');
      await _handleNotificationNavigation(initialMessage.data);
    }

    print("✅ initFCM terminó");
  }

  static bool _shouldSkipDuplicateNavigation(String routeKey) {
    final now = DateTime.now();

    if (_isNavigating) {
      print('⚠️ Navegación bloqueada: ya hay una en progreso');
      return true;
    }

    if (_lastRouteKey == routeKey && _lastNavigationAt != null) {
      final diff = now.difference(_lastNavigationAt!).inMilliseconds;
      if (diff < 1800) {
        print('⚠️ Navegación duplicada evitada: $routeKey');
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

      print('🧭 Navegación por notificación push');
      print('TYPE => $type');
      print('MATCH_ID => $matchId');

      if (matchId == null || matchId <= 0) {
        print('⚠️ match_id inválido o ausente');
        return;
      }

      final routeKey = '$type-$matchId';
      if (_shouldSkipDuplicateNavigation(routeKey)) return;

      final context = appNavigatorKey.currentContext;
      if (context == null) {
        print('⚠️ navigator context no disponible');
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
          print('⚠️ Aún no se pudo cargar getMatchProfile($matchId): $e');
          return;
        }

        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MatchProfilePage(matchId: matchId)),
        );
        return;
      }

      if (type == 'MESSAGE') {
        try {
          await api.getMatchTimeline(matchId);
        } catch (e) {
          print('⚠️ Aún no se pudo cargar getMatchTimeline($matchId): $e');
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
          print('⚠️ No se encontró el match para abrir el chat');
          return;
        }

        final other = foundMatch["other_user"];
        if (other is! Map<String, dynamic>) {
          print('⚠️ other_user inválido en match');
          return;
        }

        final otherUserId =
            int.tryParse((other["use_int_id"] ?? "0").toString()) ?? 0;

        final nombre = (other["fullname"] ?? "Chat").toString();
        final foto = (other["photo_fallback_url"] ?? other["photo"] ?? "")
            .toString();
        final fotoBase64 = other["photo_preview_base64"]?.toString();

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

      print('ℹ️ Tipo de notificación no manejado: $type');
    } catch (e) {
      print('❌ Error navegando desde notificación: $e');
    } finally {
      _isNavigating = false;
    }
  }
}
