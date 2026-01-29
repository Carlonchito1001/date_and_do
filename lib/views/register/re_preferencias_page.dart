import 'dart:ui';
import 'package:date_and_doing/views/register/re_busqueda_preferencias_page.dart';
import 'package:flutter/material.dart';

class RePreferenciasPage extends StatefulWidget {
  const RePreferenciasPage({super.key});

  @override
  State<RePreferenciasPage> createState() => _RePreferenciasPageState();
}

class _RePreferenciasPageState extends State<RePreferenciasPage> {
  final TextEditingController _customPrefCtrl = TextEditingController();
  final List<String> _selectedPrefs = [];

  final List<_PrefItem> _presetPrefs = const [
    _PrefItem('Música', '🎵'),
    _PrefItem('Deportes', '⚽'),
    _PrefItem('Viajar', '✈️'),
    _PrefItem('Cocinar', '👩‍🍳'),
    _PrefItem('Leer', '📚'),
    _PrefItem('Cine', '🎬'),
    _PrefItem('Videojuegos', '🎮'),
    _PrefItem('Fitness', '💪'),
    _PrefItem('Arte', '🎨'),
    _PrefItem('Fotografía', '📸'),
    _PrefItem('Gastronomía', '🍣'),
    _PrefItem('Mascotas', '🐶'),
    _PrefItem('Naturaleza', '🌿'),
    _PrefItem('Tecnología', '💻'),
    _PrefItem('Teatro', '🎭'),
    _PrefItem('Playa', '🏖️'),
    _PrefItem('Montaña', '⛰️'),
    _PrefItem('Karaoke', '🎤'),
  ];

  @override
  void dispose() {
    _customPrefCtrl.dispose();
    super.dispose();
  }

  void _togglePref(String pref) {
    setState(() {
      if (_selectedPrefs.contains(pref)) {
        _selectedPrefs.remove(pref);
      } else {
        _selectedPrefs.add(pref);
      }
    });
  }

  void _addCustomPref() {
    final text = _customPrefCtrl.text.trim();
    if (text.isEmpty) return;
    if (!_selectedPrefs.contains(text)) {
      setState(() {
        _selectedPrefs.add(text);
      });
    }
    _customPrefCtrl.clear();
  }

  void _onContinuar() {
    if (_selectedPrefs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una preferencia')),
      );
      return;
    }

    // Navigator.pop(context, _selectedPrefs);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReBusquedaPreferenciasPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Selecciona tus Preferencias'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Fondo degradado igual que las otras pantallas
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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Iconito / avatar
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
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Selecciona tus Preferencias',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cuéntanos qué te apasiona para conectar\ncon personas afines',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Input para preferencia personalizada
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Agregar preferencia personalizada',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _customPrefCtrl,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText:
                                        'Ej: Yoga, Senderismo, Ajedrez...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                  onSubmitted: (_) => _addCustomPref(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _addCustomPref,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFD5E9D),
                                        Color(0xFFFD4E60),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Selecciona de nuestra lista',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Chips de preferencias
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final pref in _presetPrefs)
                                _PreferenceChip(
                                  label: pref.label,
                                  emoji: pref.emoji,
                                  selected: _selectedPrefs.contains(pref.label),
                                  onTap: () => _togglePref(pref.label),
                                ),
                              // chips personalizados (solo texto)
                              for (final custom in _selectedPrefs.where(
                                (p) => !_presetPrefs
                                    .map((e) => e.label)
                                    .contains(p),
                              ))
                                _PreferenceChip(
                                  label: custom,
                                  emoji: '✨',
                                  selected: true,
                                  onTap: () => _togglePref(custom),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                // Botón Continuar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onContinuar,
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
                            colors: [Color(0xFFFD5E9D), Color(0xFFFD4E60)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          child: const Text(
                            'Continuar',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefItem {
  final String label;
  final String emoji;
  const _PrefItem(this.label, this.emoji);
}

class _PreferenceChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _PreferenceChip({
    super.key,
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgSelected = Colors.white;
    final bgUnselected = Colors.white.withOpacity(0.1);

    final textSelected = const Color(0xFF111827);
    final textUnselected = Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? bgSelected : bgUnselected,
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withOpacity(0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? textSelected : textUnselected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
