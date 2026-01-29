// import 'package:date_and_doing/service/fcm_service.dart';
import 'package:date_and_doing/services/notificacion_service.dart';
import 'package:date_and_doing/splash_page.dart';
import 'package:date_and_doing/theme/app_theme.dart';
import 'package:date_and_doing/theme/theme_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificacionService.init();
  // await FcmService.initFCM();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Date & Doing',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode, 
          debugShowCheckedModeBanner: false,
          home: SplashPage(),
        );
      },
    );
  }
}
