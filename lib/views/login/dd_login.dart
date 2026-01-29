import 'dart:ui';
import 'package:date_and_doing/auth/google_auth_service.dart';
import 'package:date_and_doing/views/home/dd_home.dart';
import '../../auth/facebook_auth_service.dart';
import 'package:date_and_doing/models/dd_user.dart';
import 'package:date_and_doing/views/login/login_pages/email_login_page.dart';
import 'package:date_and_doing/views/login/login_pages/phone_login_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DdLogin extends StatefulWidget {
  const DdLogin({super.key});

  @override
  State<DdLogin> createState() => _DdLoginState();
}

class _DdLoginState extends State<DdLogin> {
  final _googleAuth = GoogleAuthService();
  final _facebookAuth = FacebookAuthService();

  bool _loading = false;
  bool _aceptaTerminos = false;

  // ---------- HELPERS ----------

  void _mostrarMensajeTerminos() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Debes aceptar los Términos y Condiciones para continuar',
        ),
      ),
    );
  }

  Future<void> _onGoogleTap() async {
    if (!_aceptaTerminos) {
      _mostrarMensajeTerminos();
      return;
    }
    await _handleGoogle();
  }

  Future<void> _onFacebookTap() async {
    if (!_aceptaTerminos) {
      _mostrarMensajeTerminos();
      return;
    }
    await _handleFacebook();
  }

  Future<void> _onPhoneTap() async {
    if (!_aceptaTerminos) {
      _mostrarMensajeTerminos();
      return;
    }
    await _goToPhone();
  }

  Future<void> _onEmailTap() async {
    if (!_aceptaTerminos) {
      _mostrarMensajeTerminos();
      return;
    }
    await _goToEmail();
  }

  Future<void> _handleGoogle() async {
    setState(() => _loading = true);
    try {
      final DdUser user = await _googleAuth.signInWithGoogle();
      print('✅ Google login OK: $user');

      if (!mounted) return;

      // Navegar al Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DdHome()),
      );
    } catch (e) {
      print('❌ Error Google: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al iniciar con Google')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleFacebook() async {
    setState(() => _loading = true);
    try {
      final DdUser user = await _facebookAuth.signInWithFacebook();
      print('✅ Facebook login OK: $user');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DdHome()),
      );
    } catch (e) {
      print('❌ Error Facebook: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al iniciar con Facebook')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goToEmail() async {
    final user = await Navigator.push<DdUser?>(
      context,
      MaterialPageRoute(builder: (_) => const EmailLoginPage()),
    );

    if (user != null) {
      print('✅ Volvió del login por correo: $user');
      // TODO: Navegar a tu Home real
    }
  }

  Future<void> _goToPhone() async {
    final user = await Navigator.push<DdUser?>(
      context,
      MaterialPageRoute(builder: (_) => const PhoneLoginPage()),
    );

    if (user != null) {
      print('✅ Volvió del login por teléfono: $user');
      // TODO: Navegar a tu Home real
    }
  }

  // ---------- TÉRMINOS Y CONDICIONES ----------

  void _openTerminos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      isScrollControlled: true,
      builder: (_) => _TerminosSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar flotante
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'DATE ❤️ DO',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Fondo degradado
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE05875), // rose suave
                  Color(0xFF5B2C83), // purple profundo
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Opacity(
                  opacity: _loading ? 0.4 : 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar / logo
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: Image.asset('assets/datedo.png', scale: 5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Encuentra tu conexión perfecta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Elige cómo quieres comenzar',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Card principal con efecto glass
                      ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 22,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              color: Colors.white.withOpacity(0.20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      color: Colors.yellow.shade300,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Iniciar sesión',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // GOOGLE
                                _LoginOptionCard(
                                  iconBgColor: const Color(0xFFFFE9E9),
                                  icon: const FaIcon(
                                    FontAwesomeIcons.google,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  title: 'Continuar con Google',
                                  subtitle: 'Usa tu cuenta de Google',
                                  onTap: _loading ? null : _onGoogleTap,
                                ),
                                const SizedBox(height: 10),

                                // FACEBOOK
                                _LoginOptionCard(
                                  iconBgColor: const Color(0xFFE7F0FF),
                                  icon: const FaIcon(
                                    FontAwesomeIcons.facebookF,
                                    color: Color(0xFF1877F2),
                                    size: 20,
                                  ),
                                  title: 'Continuar con Facebook',
                                  subtitle: 'Rápido y seguro',
                                  onTap: _loading ? null : _onFacebookTap,
                                ),
                                const SizedBox(height: 10),

                                // TELÉFONO
                                _LoginOptionCard(
                                  iconBgColor: const Color(0xFFE7FFF1),
                                  icon: const FaIcon(
                                    FontAwesomeIcons.phone,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  title: 'Continuar con teléfono',
                                  subtitle: 'Recibe un código por SMS',
                                  onTap: _loading ? null : _onPhoneTap,
                                ),
                                const SizedBox(height: 10),

                                // CORREO
                                _LoginOptionCard(
                                  iconBgColor: const Color(0xFFEDE7FF),
                                  icon: const Icon(
                                    Icons.mail_outline_rounded,
                                    color: Color(0xFF6D3BFF),
                                    size: 22,
                                  ),
                                  title: 'Continuar con correo',
                                  subtitle: 'Código por correo electrónico',
                                  onTap: _loading ? null : _onEmailTap,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Checkbox de Términos
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _aceptaTerminos,
                            activeColor: Colors.white,
                            checkColor: const Color(0xFF5B2C83),
                            onChanged: (v) {
                              setState(() => _aceptaTerminos = v ?? false);
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openTerminos(context),
                              child: Text(
                                'Acepto los Términos y Condiciones y la Política de Privacidad',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white.withOpacity(0.85),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_loading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}

/// Card para cada opción de inicio de sesión
class _LoginOptionCard extends StatelessWidget {
  final Widget icon;
  final Color iconBgColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _LoginOptionCard({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(disabled ? 0.6 : 0.92),
          boxShadow: [
            if (!disabled)
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade500,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- BOTTOM SHEET DE TÉRMINOS ----------

class _TerminosSheet extends StatelessWidget {
  const _TerminosSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const Text(
                "Términos y Condiciones de DATE ❤️ DOING",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: const [
                    Text(
                      _terminosTexto,
                      style: TextStyle(fontSize: 13.5, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFD4E60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "Cerrar",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const String _terminosTexto = """
Bienvenido a DATE ❤️ DOING. Antes de usar nuestra aplicación, es importante que leas y aceptes los siguientes Términos y Condiciones.

1. ACEPTACIÓN DEL SERVICIO  
Al crear una cuenta o iniciar sesión en DATE ❤️ DOING, aceptas cumplir estos Términos y la Política de Privacidad. Si no estás de acuerdo, por favor no uses nuestra plataforma.

2. USO ADECUADO  
La aplicación está destinada exclusivamente a personas mayores de 18 años. Te comprometes a utilizar la plataforma de forma respetuosa, evitando comportamientos ofensivos, engañosos o inapropiados.

3. VERACIDAD DE LA INFORMACIÓN  
Eres responsable de proporcionar información real y actualizada. DATE ❤️ DOING no se hace responsable por perfiles falsos o datos inexactos proporcionados por otros usuarios.

4. SEGURIDAD Y PRIVACIDAD  
No compartimos tu información personal sin consentimiento. Puedes revisar cómo tratamos tus datos en nuestra Política de Privacidad.  
Nunca compartas contraseñas, códigos o datos sensibles dentro de la app.

5. INTERACCIONES ENTRE USUARIOS  
Las conversaciones, citas o encuentros derivados del uso de DATE ❤️ DOING se realizan bajo tu propia responsabilidad. La empresa no garantiza compatibilidad ni resultados específicos.

6. CONTENIDO PROHIBIDO  
No está permitido subir o compartir contenido:  
• Sexual explícito  
• Violento o discriminatorio  
• Spam o promociones comerciales  
• Suplantación de identidad

7. SUSPENSIÓN O ELIMINACIÓN DE CUENTA  
DATE ❤️ DOING puede suspender o eliminar tu cuenta si incumples estos Términos o si se detecta actividad sospechosa.

8. MODIFICACIONES  
DATE ❤️ DOING podrá actualizar estos Términos cuando lo considere necesario. Se notificará a los usuarios en caso de cambios importantes. 

Al continuar, declaras haber leído y aceptado estos Términos y Condiciones.
""";
