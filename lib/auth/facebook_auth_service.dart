import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../models/dd_user.dart';

class FacebookAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<DdUser> signInWithFacebook() async {
    // 1. Login con Facebook
    final LoginResult loginResult = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (loginResult.status != LoginStatus.success) {
      throw Exception(
        'Facebook login falló: ${loginResult.status} - ${loginResult.message}',
      );
    }

    final accessToken = loginResult.accessToken!;
    final token = accessToken.tokenString; // <-- NUEVO

    // 2. Credencial de Firebase
    final credential = FacebookAuthProvider.credential(token);

    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );
    final user = userCredential.user;

    if (user == null) {
      throw Exception('Face no devolvió usuario');
    }

    final bool esNuevo = userCredential.additionalUserInfo?.isNewUser ?? false;

    // 3. Info extra desde Facebook
    final fbData = await FacebookAuth.instance.getUserData(
      fields: 'name,email,picture.width(200)',
    );

    final name = fbData['name'] as String?;
    final email = fbData['email'] as String?;
    final foto = fbData['picture']?['data']?['url'] as String?;

    final ddUser = DdUser(
      id: user.uid,
      nombre: user.displayName ?? name ?? 'Usuario Facebook',
      email: user.email ?? email ?? '',
      provider: 'facebook',
      fotoUrl:
          foto ??
          user.photoURL ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name ?? 'User')}&background=1877F2&color=fff',
      creadoEn: user.metadata.creationTime ?? DateTime.now(),
      esNuevo: esNuevo,
    );

    await SharedPreferencesService().saveUserSession(
      uid: ddUser.id,
      email: ddUser.email,
      phone: null,
      photoUrl: ddUser.fotoUrl,
      accessToken: '',
    );

    return ddUser;
  }

  Future<void> signOut() async {
    await FacebookAuth.instance.logOut();
    await _auth.signOut();

    await SharedPreferencesService().clearSession();
  }
}
