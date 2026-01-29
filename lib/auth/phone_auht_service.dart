import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;

  /// Enviar OTP al número de teléfono
  Future<void> sendOtp(String phoneNumber) async {  
    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
        // Login automático (Android)
        // await _auth.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(
            e.message ?? "Error enviando el SMS",
          );
        }
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete();
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );

    return completer.future;
  }

  /// Verificar OTP ingresado
  Future<User?> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      throw Exception("Primero debes enviar el código.");
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Código incorrecto o expirado.");
    }
  }

  /// Devuelve el usuario autenticado actualmente (si existe)
  User? get currentUser => _auth.currentUser;

  /// Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }
}
