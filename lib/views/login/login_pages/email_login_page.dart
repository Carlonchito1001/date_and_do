import 'package:flutter/material.dart';
import '../../../auth/email_auth_mock.dart';
import '../../../models/dd_user.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  final _auth = EmailAuthMock();
  bool _loading = false;
  String? _error;

  bool _codeRequested = false;

  // 4 dígitos del código
  final _d1Ctrl = TextEditingController();
  final _d2Ctrl = TextEditingController();
  final _d3Ctrl = TextEditingController();
  final _d4Ctrl = TextEditingController();

  final _f1 = FocusNode();
  final _f2 = FocusNode();
  final _f3 = FocusNode();
  final _f4 = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _d1Ctrl.dispose();
    _d2Ctrl.dispose();
    _d3Ctrl.dispose();
    _d4Ctrl.dispose();
    _f1.dispose();
    _f2.dispose();
    _f3.dispose();
    _f4.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _error = null;
      _codeRequested = true;
    });

    // Aquí podrías simular un "envío de correo"
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Se ha enviado un código a ${_emailCtrl.text.trim()} (simulado)',
        ),
      ),
    );

    // Poner foco en el primer dígito
    Future.delayed(const Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(_f1);
    });
  }

  void _onCodeChanged() {
    if (_d1Ctrl.text.length == 1 &&
        _d2Ctrl.text.length == 1 &&
        _d3Ctrl.text.length == 1 &&
        _d4Ctrl.text.length == 1 &&
        !_loading) {
      _verificarCodigoYLogin();
    }
  }

  Future<void> _verificarCodigoYLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final code = '${_d1Ctrl.text}${_d2Ctrl.text}${_d3Ctrl.text}${_d4Ctrl.text}';

    // Aquí podrías validar el código si quisieras.
    // Por ahora, cualquier código de 4 dígitos es "válido" (simulado).

    try {
      final DdUser user = await _auth.signInOrRegister(
        nombre: 'User DateDoing',
        email: email,
        password: code, // usamos el código como "password" simulada
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.esNuevo
                ? 'Cuenta creada (simulado), bienvenido ${user.nombre}'
                : 'Bienvenido de nuevo, ${user.nombre}',
          ),
        ),
      );

      Navigator.pop(context, user);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildDigitField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
  }) {
    return SizedBox(
      width: 55,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (value) {
          if (value.length == 1) {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            } else {
              FocusScope.of(context).unfocus();
            }
          }
          _onCodeChanged();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailField = TextFormField(
      controller: _emailCtrl,
      enabled: !_codeRequested && !_loading,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Correo electrónico',
        prefixIcon: Icon(Icons.mail_outline),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa tu correo';
        }
        if (!value.contains('@')) {
          return 'Correo inválido';
        }
        return null;
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar con correo (simulado)')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Simularemos un login por correo con código de 4 dígitos.\nPrimero ingresa tu correo y luego el código.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        emailField,
                        const SizedBox(height: 24),
                        if (_codeRequested) ...[
                          const Text(
                            'Ingresa el código de 4 dígitos enviado a tu correo',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildDigitField(
                                controller: _d1Ctrl,
                                focusNode: _f1,
                                nextFocus: _f2,
                              ),
                              _buildDigitField(
                                controller: _d2Ctrl,
                                focusNode: _f2,
                                nextFocus: _f3,
                              ),
                              _buildDigitField(
                                controller: _d3Ctrl,
                                focusNode: _f3,
                                nextFocus: _f4,
                              ),
                              _buildDigitField(
                                controller: _d4Ctrl,
                                focusNode: _f4,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cuando completes los 4 dígitos se enviará automáticamente.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (!_codeRequested)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _enviarCodigo,
                      child: _loading
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
                  const SizedBox(height: 40), // espacio cuando ya no hay botón
              ],
            ),
          ),

          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
