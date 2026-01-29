import 'dart:math';
import '../models/dd_user.dart';

class GoogleAuthMock {
  /// Simula un login con Google.
  /// Si el usuario no existe, se "registra" automáticamente.
  Future<DdUser> signInWithGoogle() async {
    print('[GoogleAuthMock] Abriendo selector de cuenta de Google...');

    // Simulamos retraso de red
    await Future.delayed(const Duration(seconds: 2));

    // Simulamos data que vendría de Google
    const email = 'user.google@example.com';
    const nombre = 'Google Lover';

    final esNuevo = Random().nextBool(); // a veces nuevo, a veces no

    final user = DdUser(
      id: 'google_${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre,
      email: email,
      provider: 'google',
      fotoUrl:
          'https://ui-avatars.com/api/?name=Google+Lover&background=FF5F6D&color=fff',
      creadoEn: DateTime.now(),
      esNuevo: esNuevo,
    );

    print('[GoogleAuthMock] Login correcto, usuario: $user');
    return user;
  }
}
