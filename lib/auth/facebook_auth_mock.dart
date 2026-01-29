import 'dart:math';
import '../models/dd_user.dart';

class FacebookAuthMock {
  /// Simula un login con Facebook.
  Future<DdUser> signInWithFacebook() async {
    print('[FacebookAuthMock] Abriendo login de Facebook...');

    await Future.delayed(const Duration(seconds: 2));

    const email = 'user.fb@example.com';
    const nombre = 'Facebook Queen';

    final esNuevo = Random().nextBool();

    final user = DdUser(
      id: 'facebook_${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre,
      email: email,
      provider: 'facebook',
      fotoUrl:
          'https://ui-avatars.com/api/?name=Facebook+Queen&background=1877F2&color=fff',
      creadoEn: DateTime.now(),
      esNuevo: esNuevo,
    );

    print('[FacebookAuthMock] Login correcto, usuario: $user');
    return user;
  }
}
