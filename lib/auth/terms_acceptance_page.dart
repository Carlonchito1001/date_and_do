import 'package:date_and_doing/auth/post_login_gate_page.dart';
import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';

class TermsAcceptancePage extends StatefulWidget {
  const TermsAcceptancePage({super.key});

  @override
  State<TermsAcceptancePage> createState() => _TermsAcceptancePageState();
}

class _TermsAcceptancePageState extends State<TermsAcceptancePage> {
  final ApiService _api = ApiService();

  bool _accepted = false;
  bool _loading = false;

  Future<void> _acceptTerms() async {
    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes aceptar los términos y condiciones."),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _api.acceptTerms(version: "v1");

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PostLoginGatePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo registrar la aceptación: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Términos y condiciones"),
        content: const SingleChildScrollView(child: Text(_terminosTexto)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Términos y condiciones"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Icon(
                    Icons.verified_user_outlined,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Antes de continuar",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Necesitamos que aceptes los términos y condiciones para continuar usando Date and Do.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.45),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.15),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          "Resumen de condiciones:\n\n"
                          "• Debes usar la plataforma de forma respetuosa.\n"
                          "• No está permitido el acoso, fraude, suplantación o contenido inapropiado.\n"
                          "• Tu cuenta puede ser revisada o limitada por seguridad.\n"
                          "• Tus datos serán tratados conforme a las políticas de privacidad.\n"
                          "• Al continuar, aceptas las reglas de uso de Date and Do.\n\n"
                          "Puedes tocar el botón de abajo para leer el texto completo.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _showTermsDialog,
                    child: const Text("Ver términos completos"),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _accepted,
                    onChanged: _loading
                        ? null
                        : (v) {
                            setState(() => _accepted = v ?? false);
                          },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      "He leído y acepto los términos y condiciones",
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _acceptTerms,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text("Aceptar y continuar"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
