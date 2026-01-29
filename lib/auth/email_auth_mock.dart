import 'dart:math';
import '../models/dd_user.dart';

/// Simula un pequeño "repositorio" en memoria de usuarios registrados por email.
class _FakeEmailDb {
  static final Map<String, DdUser> _usersByEmail = {};

  static DdUser? getUser(String email) => _usersByEmail[email];

  static void saveUser(DdUser user) {
    _usersByEmail[user.email] = user;
  }
}

class EmailAuthMock {
  /// Simula registrar un usuario nuevo por correo + contraseña.
  Future<DdUser> registerWithEmail({
    required String nombre,
    required String email,
    required String password,
  }) async {
    print('[EmailAuthMock] Registrando usuario con email: $email');

    await Future.delayed(const Duration(seconds: 2));

    // Simulamos que ya existe
    if (_FakeEmailDb.getUser(email) != null) {
      throw Exception('Este correo ya está registrado (simulado)');
    }

    final user = DdUser(
      id: 'email_${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre,
      email: email,
      provider: 'email',
      fotoUrl:
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(nombre)}&background=6366F1&color=fff',
      creadoEn: DateTime.now(),
      esNuevo: true,
    );

    _FakeEmailDb.saveUser(user);
    print('[EmailAuthMock] Registro correcto: $user');
    return user;
  }

  /// Simula login con correo + contraseña.
  Future<DdUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    print('[EmailAuthMock] Intentando login con email: $email');

    await Future.delayed(const Duration(seconds: 1));

    final user = _FakeEmailDb.getUser(email);

    if (user == null) {
      throw Exception('Usuario no encontrado (simulado)');
    }

    // Aquí podrías validar "password" si quisieras, pero lo omitimos
    print('[EmailAuthMock] Login correcto: $user');
    return user;
  }

  /// Atajo: intenta login, y si no existe, registra.
  Future<DdUser> signInOrRegister({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      return await signInWithEmail(email: email, password: password);
    } catch (_) {
      // Si no existe, lo registramos
      return registerWithEmail(nombre: nombre, email: email, password: password);
    }
  }
}
      