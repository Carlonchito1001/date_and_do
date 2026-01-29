import 'package:date_and_doing/auth/phone_auht_service.dart';
import 'package:date_and_doing/views/register/re_fechanacimiento_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _authService = PhoneAuthService();

  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _codeSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu número de teléfono');
      return;
    }

    if (!phone.startsWith('+')) {
      setState(
        () => _errorMessage = 'Incluye el código de país. Ej: +51 999 999 999',
      );
      return;
    }

    setState(() {
      _isSendingCode = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendOtp(phone);
      setState(() => _codeSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se ha enviado un código por SMS a $phone')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error enviando el código: $e';
      });
    } finally {
      setState(() => _isSendingCode = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      setState(() => _errorMessage = 'El código debe tener 6 dígitos');
      return;
    }

    setState(() {
      _isVerifyingCode = true;
      _errorMessage = null;
    });

    try {
      final User? user = await _authService.verifyOtp(code);

      if (user == null) {
        setState(() {
          _errorMessage = 'No se pudo iniciar sesión. Intenta nuevamente.';
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bienvenido ${user.phoneNumber ?? ''}')),
      );

      // Aquí sigues tu flujo normal
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReFechanacimientoPage()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Código incorrecto o expirado: $e';
      });
    } finally {
      setState(() => _isVerifyingCode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar con teléfono')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inicia sesión con tu número de teléfono.\n'
                  'Primero te enviaremos un código por SMS.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),

                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Número de teléfono',
                    hintText: '+51 999 999 999',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),

                const SizedBox(height: 20),

                if (_codeSent) ...[
                  const Text(
                    'Ingresa el código de 6 dígitos que te llegó por SMS',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Código SMS',
                      counterText: '',
                    ),
                  ),
                ],

                const Spacer(),

                if (!_codeSent)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSendingCode ? null : _sendCode,
                      child: _isSendingCode
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Enviar código'),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isVerifyingCode ? null : _verifyCode,
                      child: _isVerifyingCode
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Verificar código'),
                    ),
                  ),
              ],
            ),
          ),

          if (_isVerifyingCode)
            Container(color: Colors.black.withOpacity(0.05)),
        ],
      ),
    );
  }
}
