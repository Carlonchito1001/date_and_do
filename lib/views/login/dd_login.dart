import 'dart:ui';
import 'package:date_and_doing/auth/google_auth_service.dart';
import 'package:date_and_doing/auth/post_login_gate_page.dart';
import '../../auth/facebook_auth_service.dart';
import 'package:date_and_doing/models/dd_user.dart';
import 'package:date_and_doing/views/login/login_pages/email_login_page.dart';
import 'package:date_and_doing/views/login/login_pages/phone_login_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:date_and_doing/services/fcm_service.dart';
import 'package:date_and_doing/services/session_bootstrap_service.dart';

class DdLogin extends StatefulWidget {
  const DdLogin({super.key});

  @override
  State<DdLogin> createState() => _DdLoginState();
}

class _DdLoginState extends State<DdLogin> {
  final _googleAuth = GoogleAuthService();
  final _facebookAuth = FacebookAuthService();

  bool _loading = false;

  Future<void> _onGoogleTap() async {
    await _handleGoogle();
  }

  Future<void> _onFacebookTap() async {
    await _handleFacebook();
  }

  Future<void> _onPhoneTap() async {
    await _goToPhone();
  }

  Future<void> _onEmailTap() async {
    await _goToEmail();
  }

  Future<void> _handleGoogle() async {
    setState(() => _loading = true);

    try {
      final DdUser user = await _googleAuth.signInWithGoogle();
      print('✅ Google login OK: $user');

      print('🚀 Iniciando FCM después del login...');
      await FcmService.initFCM();
      print('✅ FCM inicializado después del login');

      print('🚀 Enviando token/ubicación al backend...');
      await SessionBootstrapService().ensureDeviceData();
      print('✅ Token/ubicación enviados al backend');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PostLoginGatePage()),
      );
    } catch (e) {
      print('❌ Error Google: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar con Google: $e')),
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

      print('🚀 Iniciando FCM después del login...');
      await FcmService.initFCM();
      print('✅ FCM inicializado después del login');

      print('🚀 Enviando token/ubicación al backend...');
      await SessionBootstrapService().ensureDeviceData();
      print('✅ Token/ubicación enviados al backend');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PostLoginGatePage()),
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

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PostLoginGatePage()),
      );
    }
  }

  Future<void> _goToPhone() async {
    final user = await Navigator.push<DdUser?>(
      context,
      MaterialPageRoute(builder: (_) => const PhoneLoginPage()),
    );

    if (user != null) {
      print('✅ Volvió del login por teléfono: $user');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PostLoginGatePage()),
      );
    }
  }

  void _openTerminos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      isScrollControlled: true,
      builder: (_) => const _TerminosSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE05875), Color(0xFF5B2C83)],
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
                          fontWeight: FontWeight.w800,
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

                                // _LoginOptionCard(
                                //   iconBgColor: const Color(0xFFE7F0FF),
                                //   icon: const FaIcon(
                                //     FontAwesomeIcons.facebookF,
                                //     color: Color(0xFF1877F2),
                                //     size: 20,
                                //   ),
                                //   title: 'Continuar con Facebook',
                                //   subtitle: 'Rápido y seguro',
                                //   onTap: _loading ? null : _onFacebookTap,
                                // ),
                                // const SizedBox(height: 10),

                                // _LoginOptionCard(
                                //   iconBgColor: const Color(0xFFE7FFF1),
                                //   icon: const FaIcon(
                                //     FontAwesomeIcons.phone,
                                //     color: Colors.green,
                                //     size: 20,
                                //   ),
                                //   title: 'Continuar con teléfono',
                                //   subtitle: 'Recibe un código por SMS',
                                //   onTap: _loading ? null : _onPhoneTap,
                                // ),
                                // const SizedBox(height: 10),

                                // _LoginOptionCard(
                                //   iconBgColor: const Color(0xFFEDE7FF),
                                //   icon: const Icon(
                                //     Icons.mail_outline_rounded,
                                //     color: Color(0xFF6D3BFF),
                                //     size: 22,
                                //   ),
                                //   title: 'Continuar con correo',
                                //   subtitle: 'Código por correo electrónico',
                                //   onTap: _loading ? null : _onEmailTap,
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () => _openTerminos(context),
                        child: Text(
                          'Al continuar, podrás revisar y aceptar los Términos y Condiciones y la Política de Privacidad.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.8,
                            color: Colors.white.withOpacity(0.88),
                            decoration: TextDecoration.underline,
                          ),
                        ),
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
                      style: const TextStyle(
                        fontSize: 12.2,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}

class _TerminosSheet extends StatelessWidget {
  const _TerminosSheet();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: media.viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Términos y Condiciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            const SizedBox(
              height: 280,
              child: SingleChildScrollView(
                child: Text(
                  'Aquí puedes colocar el contenido real de tus Términos y Condiciones y la Política de Privacidad.\n\n'
                  'Ejemplo:\n\n'
                  '1. El usuario acepta usar la plataforma de forma responsable.\n'
                  '2. No se permite suplantación, fraude, acoso ni contenido inapropiado.\n'
                  '3. La cuenta podrá ser revisada por motivos de seguridad.\n'
                  '4. El uso de la app implica aceptar las reglas de convivencia y privacidad.\n'
                  '5. El incumplimiento de estas reglas puede generar restricciones o suspensión.\n\n'
                  'Luego reemplazas este texto por tu versión final.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
