import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:date_and_doing/services/shared_preferences_service.dart';
import '../services/notificacion_service.dart';

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
  );
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? currentToken;

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
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👉 onMessageOpenedApp: ${message.messageId}');
      print('📦 [OPENED] DATA: ${message.data}');
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print('🚀 App abierta desde notificación cerrada');
      print('📦 [INITIAL] DATA: ${initialMessage.data}');
    }

    print("✅ initFCM terminó");
  }
}
