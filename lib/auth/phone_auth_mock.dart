import 'dart:math';
import '../models/dd_user.dart';

class PhoneAuthMock {
  /// Simula enviar un código SMS al teléfono
  Future<String> enviarCodigoSms(String telefono) async {
    print('[PhoneAuthMock] Enviando SMS a $telefono...');

    await Future.delayed(const Duration(seconds: 2));

    // Código ficticio
    const codigo = '1234';
    print('[PhoneAuthMock] Código enviado: $codigo (simulado)');
    return codigo; 
  }

  /// Simula verificar código SMS e iniciar sesión / registrar.
  Future<DdUser> verificarCodigoYLogin({
    required String telefono,
    required String codigoIngresado,
  }) async {
    print('[PhoneAuthMock] Verificando código $codigoIngresado para $telefono');

    await Future.delayed(const Duration(seconds: 1));

    // Aquí simulamos que "123456" es válido
    if (codigoIngresado != '1234') {
      throw Exception('Código incorrecto (simulado)');
    }

    final esNuevo = Random().nextBool();

    final user = DdUser(
      id: 'phone_${DateTime.now().millisecondsSinceEpoch}',
      nombre: 'User $telefono',
      email: '$telefono@phone.date_doing.fake',
      provider: 'phone',
      fotoUrl:
          'https://ui-avatars.com/api/?name=Phone+User&background=34D399&color=fff',
      creadoEn: DateTime.now(),
      esNuevo: esNuevo,
    );

    print('[PhoneAuthMock] Login/registro con teléfono correcto: $user');
    return user;
  }
}
