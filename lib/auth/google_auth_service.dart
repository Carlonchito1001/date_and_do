import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/location/location_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dd_user.dart';
import '../services/shared_preferences_service.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await _googleSignIn.initialize();
    _isInitialized = true;
  }

  void _printFullToken(String token) {
    const int chunkSize = 500;
    for (int i = 0; i < token.length; i += chunkSize) {
      final end = (i + chunkSize < token.length) ? i + chunkSize : token.length;
      print(
        '🔐 FIREBASE TOKEN PART ${i ~/ chunkSize + 1}: ${token.substring(i, end)}',
      );
    }
  }

  String _cleanToken(String token) =>
      token.trim().replaceAll('\n', '').replaceAll('\r', '');

  String _pickAccess(Map<String, dynamic> json) {
    final v = json['access_token'] ?? json['access'];
    if (v == null) throw Exception('Login response sin access_token/access');
    return v.toString();
  }

  Future<DdUser> signInWithGoogle() async {
    await _ensureInitialized();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) throw Exception('Usuario Firebase nulo');

    final rawIdToken = await user.getIdToken(true);
    if (rawIdToken == null || rawIdToken.isEmpty) {
      throw Exception('Firebase ID Token es nulo');
    }

    _printFullToken(rawIdToken);

    final idToken = _cleanToken(rawIdToken);

    final loginResponse = await ApiService().apiLoginFirebase(idToken);

    final sp = SharedPreferencesService();
    final accessToken = _pickAccess(loginResponse);
    await sp.saveAccessToken(accessToken);

    final userinfo = await ApiService().infoUser(accessToken: accessToken);
    await sp.saveUserInfo(userinfo);

    final int userId = (userinfo['use_int_id'] as num).toInt();

    final prefs = await SharedPreferences.getInstance();
    final String? fcmToken = prefs.getString(SharedPreferencesService.fcmToken);

    double? latitude;
    double? longitude;

    try {
      final gps = await LocationService().getCurrentPositionSafe();
      if (gps != null) {
        latitude = double.parse(gps.latitude.toStringAsFixed(4));
        longitude = double.parse(gps.longitude.toStringAsFixed(4));
      } else {
        latitude = null;
        longitude = null;
      }
    } catch (_) {
      latitude = null;
      longitude = null;
    }

    try {
      await ApiService().patchUserDevice(
        userId: userId,
        fcmToken: fcmToken,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {}

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

    return ddUser;
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    await _auth.signOut();
    await SharedPreferencesService().clearSession();
  }
}
