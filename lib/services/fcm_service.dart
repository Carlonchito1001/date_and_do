import 'dart:developer';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notificacion_service.dart';

@pragma('vm:entry-point') // necesario para background en release
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  log('📩 [BG] Mensaje en background: ${message.messageId}');

  final title = message.notification?.title ?? 'Date & Doing';
  final body = message.notification?.body ?? 'Tienes una nueva notificación';

  // Mostramos una notificación local
  await NotificacionService.showSimpleNotification(title: title, body: body);
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? currentToken;

  static Future<void> initFCM() async {
    // Registrar el handler de background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Pedir permisos (Android 13 / iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    log('🔔 Permiso notificaciones: ${settings.authorizationStatus}');

    // Obtener token FCM
    currentToken = await _messaging.getToken();
    log('🔥 FCM TOKEN: $currentToken');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharedPreferencesService.fcmToken, currentToken!);

    // Si el token se refresca
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      currentToken = token;
      log('♻️ FCM TOKEN REFRESH: $token');
    });

    // Mensaje recibido en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      log('📩 [FG] Mensaje: ${message.messageId}');
      final title = message.notification?.title ?? 'Date & Doing';
      final body =
          message.notification?.body ?? 'Tienes una nueva notificación';

      // Mostramos notificación local aunque esté abierta
      await NotificacionService.showSimpleNotification(
        title: title,
        body: body,
      );
    });

    // Cuando el usuario toca la notificación y abre la app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('👉 onMessageOpenedApp: ${message.messageId}');
      // TODO: navegar a alguna pantalla si quieres, por ejemplo al chat
    });
  }
}
