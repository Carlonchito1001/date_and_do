import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/navigation/app_navigator.dart';
import 'package:date_and_doing/views/home/dd_chat_page.dart';
import 'package:date_and_doing/views/home/matches/match_profile_page.dart';

class NotificacionService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isNavigating = false;
  static String? _lastRouteKey;
  static DateTime? _lastNavigationAt;

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;

        if (payload == null || payload.isEmpty) {
          print('⚠️ Notificación local sin payload');
          return;
        }

        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload));
          await _handleNotificationNavigation(data);
        } catch (e) {
          print('❌ Error procesando payload local: $e');
        }
      },
    );
  }

  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    required bool playSound,
    Map<String, dynamic>? payloadData,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'date_and_doing',
          'Notificacion Date ❤️ Doing',
          channelDescription: 'Notificaciones generales de Date & Doing',
          importance: Importance.max,
          priority: Priority.high,
          playSound: playSound,
          enableVibration: true,
        );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payloadData == null ? null : jsonEncode(payloadData),
    );
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

      print('🧭 Navegación desde notificación local');
      print('TYPE => $type');
      print('MATCH_ID => $matchId');

      if (matchId == null || matchId <= 0) {
        print('⚠️ match_id inválido o ausente en local notification');
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
          print('⚠️ Aún no se pudo cargar getMatchTimeline($matchId): $e');
          return;
        }

        final allMatches = await api.getAllMatches();

        Map<String, dynamic>? foundMatch;
        for (final item in allMatches) {
          final itemMatchId =
              int.tryParse((item["ddm_int_id"] ?? "").toString());
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
        final foto =
            (other["photo_fallback_url"] ?? other["photo"] ?? "").toString();
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

      print('ℹ️ Tipo no manejado en local notification: $type');
    } catch (e) {
      print('❌ Error navegando desde notificación local: $e');
    } finally {
      _isNavigating = false;
    }
  }
}