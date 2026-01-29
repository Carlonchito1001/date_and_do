import 'dart:ui';
import 'package:date_and_doing/views/register/re_exito_page.dart';
import 'package:flutter/material.dart';

class ReBusquedaPreferenciasPage extends StatefulWidget {
  const ReBusquedaPreferenciasPage({super.key});

  @override
  State<ReBusquedaPreferenciasPage> createState() =>
      _ReBusquedaPreferenciasPageState();
}

class _ReBusquedaPreferenciasPageState
    extends State<ReBusquedaPreferenciasPage> {
  // Género que le gustaría conocer
  String _generoBuscado = 'todos'; // 'hombre', 'mujer', 'todos'

  // Rango de edad
  static const double _minAllowedAge = 18;
  static const double _maxAllowedAge = 75;
  RangeValues _ageRange = const RangeValues(18, 35);

  // Qué está buscando
  String _queBuscas =
      'relacion_seria'; // 'relacion_seria', 'casual', 'amistad', 'no_se'

  void _onFinalizar() {
    final data = {
      'genero_buscado': _generoBuscado,
      'edad_min': _ageRange.start.round(),
      'edad_max': _ageRange.end.round(),
      'que_buscas': _queBuscas,
    };

    // Navigator.pop(context, data);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegistroExitoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minEdad = _ageRange.start.round();
    final maxEdad = _ageRange.end.round();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Preferencias de Búsqueda'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Fondo degradado (igual tema)
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icono superior
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFD5E9D), Color(0xFFFD4E60)],
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
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Preferencias de Búsqueda',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Personaliza tu experiencia y encuentra a quien buscas',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // ¿Qué género te gustaría conocer?
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '¿Qué género te gustaría conocer?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _PillToggle(
                                  label: 'Hombre',
                                  emoji: '👨',
                                  selected: _generoBuscado == 'hombre',
                                  onTap: () {
                                    setState(() => _generoBuscado = 'hombre');
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _PillToggle(
                                  label: 'Mujer',
                                  emoji: '👩',
                                  selected: _generoBuscado == 'mujer',
                                  onTap: () {
                                    setState(() => _generoBuscado = 'mujer');
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.center,
                            child: _PillToggle(
                              label: 'Todos',
                              emoji: '🌈',
                              selected: _generoBuscado == 'todos',
                              onTap: () {
                                setState(() => _generoBuscado = 'todos');
                              },
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Rango de edad
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rango de edad',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: const Color(0xFFFFF0F5),
                              border: Border.all(
                                color: const Color(0xFFF9A8D4),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$minEdad',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFE05875),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Mínimo',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 28,
                                      height: 2,
                                      color: Colors.grey.shade300,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$maxEdad',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF8B5CF6),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Máximo',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                RangeSlider(
                                  min: _minAllowedAge,
                                  max: _maxAllowedAge,
                                  divisions: (_maxAllowedAge - _minAllowedAge)
                                      .toInt(),
                                  values: _ageRange,
                                  activeColor: const Color(0xFFE05875),
                                  inactiveColor: Colors.grey.shade300
                                      .withOpacity(0.9),
                                  onChanged: (values) {
                                    setState(() {
                                      if (values.end - values.start >= 1) {
                                        _ageRange = values;
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text(
                                      '18 años',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                    Text(
                                      '75 años',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ¿Qué estás buscando?
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '¿Qué estás buscando?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _OptionCard(
                            label: 'Relación seria',
                            emoji: '💕',
                            selected: _queBuscas == 'relacion_seria',
                            onTap: () {
                              setState(() => _queBuscas = 'relacion_seria');
                            },
                          ),
                          const SizedBox(height: 8),
                          _OptionCard(
                            label: 'Algo casual',
                            emoji: '😊',
                            selected: _queBuscas == 'casual',
                            onTap: () {
                              setState(() => _queBuscas = 'casual');
                            },
                          ),
                          const SizedBox(height: 8),
                          _OptionCard(
                            label: 'Amistad',
                            emoji: '🤝',
                            selected: _queBuscas == 'amistad',
                            onTap: () {
                              setState(() => _queBuscas = 'amistad');
                            },
                          ),
                          const SizedBox(height: 8),
                          _OptionCard(
                            label: 'Aún no lo sé',
                            emoji: '🤷‍♀️',
                            selected: _queBuscas == 'no_se',
                            onTap: () {
                              setState(() => _queBuscas = 'no_se');
                            },
                          ),

                          const SizedBox(height: 20),

                          // Botón Finalizar Registro
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _onFinalizar,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                elevation: 4,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.black.withOpacity(0.25),
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
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Finalizar Registro',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Podrás cambiar estas preferencias en cualquier momento',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
}

class _PillToggle extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _PillToggle({
    super.key,
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.white : const Color(0xFFF3F4F6);
    final borderColor = selected
        ? const Color(0xFFFD5E9D)
        : const Color(0xFFE5E7EB);
    final textColor = selected
        ? const Color(0xFF111827)
        : const Color(0xFF4B5563);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: bg,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    super.key,
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFFFD5E9D)
        : const Color(0xFFE5E7EB);
    final bgColor = selected ? const Color(0xFFFFF1F5) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: bgColor,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
