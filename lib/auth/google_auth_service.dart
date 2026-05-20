import 'package:flutter/foundation.dart';

import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/location/location_service.dart';
import 'package:date_and_doing/services/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/dd_user.dart';
import '../services/shared_preferences_service.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    // Si en release Google Sign-In te falla por clientId,
    // puedes activar serverClientId con el WEB CLIENT ID de Firebase/Google Cloud:
    //
    // await _googleSignIn.initialize(
    //   serverClientId: 'TU_WEB_CLIENT_ID.apps.googleusercontent.com',
    // );
    //
    // Por ahora lo dejamos así porque ya te está logueando correctamente.
    await _googleSignIn.initialize();

    _isInitialized = true;
  }

  void _printFullToken(String token) {
    if (kReleaseMode) return;

    const int chunkSize = 500;

    for (int i = 0; i < token.length; i += chunkSize) {
      final end = (i + chunkSize < token.length) ? i + chunkSize : token.length;

      debugPrint(
        '🔐 FIREBASE TOKEN PART ${i ~/ chunkSize + 1}: ${token.substring(i, end)}',
      );
    }
  }

  String _cleanToken(String token) {
    return token.trim().replaceAll('\n', '').replaceAll('\r', '');
  }

  String _pickAccess(Map<String, dynamic> json) {
    // Respuesta tipo:
    // { "access": "..." }
    // { "access_token": "..." }
    final direct = json['access_token'] ?? json['access'];

    if (direct != null && direct.toString().isNotEmpty) {
      return direct.toString();
    }

    // Respuesta tipo:
    // { "data": { "access": "...", "refresh": "..." } }
    final data = json['data'];

    if (data is Map<String, dynamic>) {
      final nested = data['access_token'] ?? data['access'];

      if (nested != null && nested.toString().isNotEmpty) {
        return nested.toString();
      }
    }

    throw Exception('Login response sin access_token/access');
  }

  int _pickUserId(Map<String, dynamic> userinfo) {
    final rawId = userinfo['use_int_id'];

    if (rawId == null) {
      throw Exception('infoUser no devolvió use_int_id');
    }

    if (rawId is int) return rawId;

    if (rawId is num) return rawId.toInt();

    final parsed = int.tryParse(rawId.toString());

    if (parsed == null) {
      throw Exception('use_int_id inválido: $rawId');
    }

    return parsed;
  }

  Future<DdUser> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      debugPrint('🚀 Iniciando login con Google...');

      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = await googleUser.authentication;

      final googleIdToken = googleAuth.idToken;

      if (googleIdToken == null || googleIdToken.isEmpty) {
        throw Exception('Google ID Token es nulo');
      }

      final credential = GoogleAuthProvider.credential(idToken: googleIdToken);

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Usuario Firebase nulo');
      }

      final rawIdToken = await user.getIdToken(true);

      if (rawIdToken == null || rawIdToken.isEmpty) {
        throw Exception('Firebase ID Token es nulo');
      }

      _printFullToken(rawIdToken);

      final idToken = _cleanToken(rawIdToken);

      debugPrint('✅ Firebase Auth OK');
      debugPrint('🚀 Enviando Firebase ID Token al backend...');

      final loginResponse = await ApiService().apiLoginFirebase(idToken);

      final sp = SharedPreferencesService();

      final accessToken = _pickAccess(loginResponse);

      await sp.saveAccessToken(accessToken);

      debugPrint('✅ Access token guardado');
      debugPrint('🚀 Consultando infoUser...');

      final userinfo = await ApiService().infoUser(accessToken: accessToken);

      await sp.saveUserInfo(userinfo);

      final int userId = _pickUserId(userinfo);

      debugPrint('✅ infoUser OK. userId: $userId');

      double? latitude;
      double? longitude;

      try {
        final gps = await LocationService().getCurrentPositionSafe();

        if (gps != null) {
          latitude = double.parse(gps.latitude.toStringAsFixed(4));
          longitude = double.parse(gps.longitude.toStringAsFixed(4));

          debugPrint('📍 Ubicación obtenida: $latitude, $longitude');
        } else {
          debugPrint('⚠️ Ubicación no disponible');
        }
      } catch (e) {
        debugPrint('⚠️ No se pudo obtener ubicación en login: $e');
        latitude = null;
        longitude = null;
      }

      final ddUser = DdUser(
        id: user.uid,
        nombre: user.displayName ?? 'Usuario Google',
        email: user.email ?? '',
        provider: 'google',
        fotoUrl: user.photoURL ?? '',
        creadoEn: user.metadata.creationTime ?? DateTime.now(),
        esNuevo: userCredential.additionalUserInfo?.isNewUser ?? false,
      );

      await sp.saveUserSession(
        uid: ddUser.id,
        email: ddUser.email,
        phone: null,
        photoUrl: ddUser.fotoUrl,
        firebaseIdToken: idToken,
        accessToken: accessToken,
      );

      debugPrint('✅ Sesión guardada correctamente');

      try {
        debugPrint('🚀 Sincronizando FCM después del login...');
        await FcmService.afterLoginSync();
        debugPrint('✅ FCM sincronizado después del login');
      } catch (e) {
        debugPrint(
          '⚠️ FCM falló después del login, pero la sesión continúa: $e',
        );
      }

      try {
        debugPrint('🚀 Enviando ubicación al backend...');

        await ApiService().patchUserDevice(
          userId: userId,
          fcmToken: null,
          latitude: latitude,
          longitude: longitude,
        );

        debugPrint('✅ Ubicación enviada al backend');
      } catch (e) {
        debugPrint('⚠️ No se pudo actualizar ubicación del usuario: $e');
      }

      debugPrint('✅ Google login OK: $ddUser');

      return ddUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException Google: ${e.code} - ${e.message}');
      rethrow;
    } on GoogleSignInException catch (e) {
      debugPrint('❌ GoogleSignInException: ${e.code} - ${e.description}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Error GoogleAuthService.signInWithGoogle: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('⚠️ No se pudo desconectar GoogleSignIn: $e');
    }

    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('⚠️ No se pudo cerrar sesión FirebaseAuth: $e');
    }

    await SharedPreferencesService().clearSession();

    debugPrint('✅ Sesión Google/Firebase cerrada');
  }
}
