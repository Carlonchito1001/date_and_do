import 'dart:convert';

import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/navigation/app_navigator.dart';
import 'package:date_and_doing/views/home/dd_chat_page.dart';
import 'package:date_and_doing/views/home/matches/match_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificacionService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isNavigating = false;
  static String? _lastRouteKey;
  static DateTime? _lastNavigationAt;

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;

        if (payload == null || payload.isEmpty) {
          debugPrint('⚠️ Notificación local sin payload');
          return;
        }

        try {
          final decoded = jsonDecode(payload);

          if (decoded is! Map) {
            debugPrint('⚠️ Payload local no es un Map válido');
            return;
          }

          final data = Map<String, dynamic>.from(decoded);
          await _handleNotificationNavigation(data);
        } catch (e) {
          debugPrint('❌ Error procesando payload local: $e');
        }
      },
    );

    await _requestAndroidNotificationPermission();
  }

  static Future<void> _requestAndroidNotificationPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    required bool playSound,
    Map<String, dynamic>? payloadData,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'date_and_doing',
      'Notificación Date ❤️ Doing',
      channelDescription: 'Notificaciones generales de Date & Doing',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payloadData == null ? null : jsonEncode(payloadData),
    );
  }

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

      debugPrint('🧭 Navegación desde notificación local');
      debugPrint('TYPE => $type');
      debugPrint('MATCH_ID => $matchId');

      if (matchId == null || matchId <= 0) {
        debugPrint('⚠️ match_id inválido o ausente en local notification');
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
          MaterialPageRoute(
            builder: (_) => MatchProfilePage(matchId: matchId),
          ),
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
          final itemMatchId =
              int.tryParse((item['ddm_int_id'] ?? '').toString());

          if (itemMatchId == matchId) {
            foundMatch = item;
            break;
          }
        }

        if (foundMatch == null) {
          debugPrint('⚠️ No se encontró el match para abrir el chat');
          return;
        }

        final other = foundMatch['other_user'];

        if (other is! Map<String, dynamic>) {
          debugPrint('⚠️ other_user inválido en match');
          return;
        }

        final otherUserId =
            int.tryParse((other['use_int_id'] ?? '0').toString()) ?? 0;

        final nombre = (other['fullname'] ?? 'Chat').toString();

        final foto =
            (other['photo_fallback_url'] ?? other['photo'] ?? '').toString();

        final fotoBase64 = other['photo_preview_base64']?.toString();

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

      debugPrint('ℹ️ Tipo no manejado en local notification: $type');
    } catch (e) {
      debugPrint('❌ Error navegando desde notificación local: $e');
    } finally {
      _isNavigating = false;
    }
  }
}