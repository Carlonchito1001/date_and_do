import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificacionService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(initSettings);
  }

  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    required bool playSound,
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
    );
  }
}
