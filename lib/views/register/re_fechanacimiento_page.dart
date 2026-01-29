import 'dart:ui';
import 'package:date_and_doing/views/register/re_form_sobreti.dart';
import 'package:date_and_doing/views/register/re_perfil_page.dart';
import 'package:flutter/material.dart';

class ReFechanacimientoPage extends StatefulWidget {
  const ReFechanacimientoPage({super.key});

  @override
  State<ReFechanacimientoPage> createState() => _ReFechanacimientoPageState();
}

class _ReFechanacimientoPageState extends State<ReFechanacimientoPage> {
  DateTime? _selectedDate;

  // Rango permitido (lo puedes ajustar)
  final DateTime _firstDate = DateTime(1950, 1, 1);
  final DateTime _lastDate = DateTime.now();

  int? get _age {
    if (_selectedDate == null) return null;
    final now = DateTime.now();
    int years = now.year - _selectedDate!.year;
    final hasHadBirthdayThisYear =
        (now.month > _selectedDate!.month) ||
        (now.month == _selectedDate!.month && now.day >= _selectedDate!.day);
    if (!hasHadBirthdayThisYear) years--;
    return years;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate =
        _selectedDate ??
        DateTime(now.year - 18, now.month, now.day); // por defecto: 18 años

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _firstDate,
      lastDate: _lastDate,
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) {
        // Para personalizar un poco el datepicker
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE05875), // header + selección
              onPrimary: Colors.white, // texto en header
              onSurface: Colors.black, // texto normal
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE05875),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onContinuar() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona tu fecha de nacimiento'),
        ),
      );
      return;
    }

    // Aquí podrías validar que sea mayor de 18, etc.
    // if ((_age ?? 0) < 18) { ... }

    // Navigator.pop(context, _selectedDate);
    Navigator.push(context, MaterialPageRoute(builder: (_) => RePerfilPage()));
  }

  @override
  Widget build(BuildContext context) {
    final age = _age;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Tu fecha de nacimiento'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Fondo degradado
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
              child: Padding(
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
                        color: Colors.white.withOpacity(0.18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cake_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '¿Cuándo naciste?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Usaremos tu edad para darte una mejor experiencia.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Card interna con la fecha
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withOpacity(0.95),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _selectedDate == null
                                      ? 'Selecciona tu fecha'
                                      : _formatDate(_selectedDate!),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                if (age != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: const Color(
                                        0xFFE05875,
                                      ).withOpacity(0.08),
                                    ),
                                    child: Text(
                                      '$age años',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFE05875),
                                      ),
                                    ),
                                  )
                                else
                                  const Text(
                                    'Debes tener al menos 18 años para usar la app.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                    ),
                                    onPressed: _pickDate,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFFE05875),
                                      ),
                                      foregroundColor: const Color(0xFFE05875),
                                    ),
                                    label: Text(
                                      _selectedDate == null
                                          ? 'Elegir fecha'
                                          : 'Cambiar fecha',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _onContinuar,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF5B2C83),
                                elevation: 3,
                              ),
                              child: const Text(
                                'Continuar',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
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
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Formato: 05 de marzo de 2000
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final dia = date.day.toString().padLeft(2, '0');
    final mes = meses[date.month - 1];
    final anio = date.year;
    return '$dia de $mes de $anio';
  }
}
