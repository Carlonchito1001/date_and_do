import 'dart:ui';
import 'package:date_and_doing/views/register/re_preferencias_page.dart';
import 'package:flutter/material.dart';

class RePerfilPage extends StatefulWidget {
  const RePerfilPage({super.key});

  @override
  State<RePerfilPage> createState() => _RePerfilPageState();
}

class _RePerfilPageState extends State<RePerfilPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _estaturaCtrl = TextEditingController();
  final _profesionCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _sobreTiCtrl = TextEditingController();

  String? _genero;
  String? _pais;

  int get _sobreTiLength => _sobreTiCtrl.text.length;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _estaturaCtrl.dispose();
    _profesionCtrl.dispose();
    _direccionCtrl.dispose();
    _ciudadCtrl.dispose();
    _sobreTiCtrl.dispose();
    super.dispose();
  }

  void _onContinuar() {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nombre_mostrar': _nombreCtrl.text.trim(),
      'genero': _genero,
      'estatura_cm': _estaturaCtrl.text.trim(),
      'profesion': _profesionCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
      'pais': _pais,
      'ciudad': _ciudadCtrl.text.trim(),
      'sobre_ti': _sobreTiCtrl.text.trim(),
    };

    // Aquí podrías llamar a tu backend o guardar en provider/BLoC
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RePreferenciasPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Crea tu Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Fondo degradado (mismo tema que la vista anterior)
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        color: Colors.white.withOpacity(0.96),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar / ícono
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFD5E9D),
                                    Color(0xFFFD4E60),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Crea tu Perfil',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Cuéntanos sobre ti para encontrar tu match perfecto',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Nombre a mostrar
                            _LabelWithAsterisk('Nombre a mostrar'),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _nombreCtrl,
                              decoration: _inputDecoration(
                                hint: '¿Cómo quieres que te llamen?',
                                icon: Icons.person_outline,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa un nombre a mostrar';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Género
                            _LabelWithAsterisk('Género'),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _genero,
                              decoration: _inputDecoration(
                                hint: 'Selecciona tu género',
                                icon: Icons.wc_outlined,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'mujer',
                                  child: Text('Mujer'),
                                ),
                                DropdownMenuItem(
                                  value: 'hombre',
                                  child: Text('Hombre'),
                                ),
                                DropdownMenuItem(
                                  value: 'otro',
                                  child: Text('Otro / Prefiero no decirlo'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _genero = value);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecciona un género';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Estatura
                            _LabelSimple('Estatura (cm)'),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _estaturaCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                hint: '170',
                                icon: Icons.straighten_rounded,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Profesión / Educación / Ocupación
                            _LabelSimple('Profesión / Educación / Ocupación'),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _profesionCtrl,
                              decoration: _inputDecoration(
                                hint: 'Ej: Ingeniero, Estudiante de Medicina',
                                icon: Icons.work_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Dirección
                            _LabelSimple('Dirección'),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _direccionCtrl,
                              decoration: _inputDecoration(
                                hint: 'Av. Principal 123, Miraflores',
                                icon: Icons.home_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // País
                            _LabelWithAsterisk('País'),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _pais,
                              decoration: _inputDecoration(
                                hint: 'Selecciona tu país',
                                icon: Icons.public_outlined,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'peru',
                                  child: Text('Perú'),
                                ),
                                DropdownMenuItem(
                                  value: 'mexico',
                                  child: Text('México'),
                                ),
                                DropdownMenuItem(
                                  value: 'colombia',
                                  child: Text('Colombia'),
                                ),
                                DropdownMenuItem(
                                  value: 'chile',
                                  child: Text('Chile'),
                                ),
                                DropdownMenuItem(
                                  value: 'otro',
                                  child: Text('Otro'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _pais = value);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecciona un país';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Ciudad
                            _LabelSimple('Ciudad'),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _ciudadCtrl,
                              decoration: _inputDecoration(
                                hint: 'Ej: Lima',
                                icon: Icons.location_city_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Algo sobre ti
                            Row(
                              children: const [
                                Text(
                                  'Algo sobre ti',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '(Opcional)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _sobreTiCtrl,
                              maxLines: 4,
                              maxLength: 500,
                              decoration:
                                  _inputDecoration(
                                    hint:
                                        'Cuéntanos un poco sobre ti, tus intereses, hobbies...',
                                    icon: Icons.chat_bubble_outline_rounded,
                                  ).copyWith(
                                    counterText:
                                        '$_sobreTiLength/500 caracteres',
                                  ),
                            ),
                            const SizedBox(height: 20),

                            // Botón Continuar
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _onContinuar,
                                style:
                                    ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      elevation: 4,
                                      backgroundColor:
                                          const LinearGradient(
                                                colors: [
                                                  Color(0xFFFD5E9D),
                                                  Color(0xFFFD4E60),
                                                ],
                                              ).createShader(
                                                const Rect.fromLTWH(
                                                  0,
                                                  0,
                                                  200,
                                                  50,
                                                ),
                                              ) ==
                                              null
                                          ? null
                                          : null, // hack para evitar warning
                                    ).copyWith(
                                      backgroundColor:
                                          MaterialStateProperty.resolveWith(
                                            (states) => null,
                                          ),
                                      foregroundColor:
                                          MaterialStateProperty.all(
                                            Colors.white,
                                          ),
                                    ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFD5E9D),
                                        Color(0xFFFD4E60),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 48,
                                    child: const Text(
                                      'Continuar',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Los campos marcados con * son obligatorios.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE05875)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
    );
  }
}

class _LabelWithAsterisk extends StatelessWidget {
  final String text;
  const _LabelWithAsterisk(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const Text(
          ' *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }
}

class _LabelSimple extends StatelessWidget {
  final String text;
  const _LabelSimple(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
      ),
    );
  }
}
