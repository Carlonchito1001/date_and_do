import 'package:flutter/material.dart';
import '../../theme/theme_controller.dart';

class ConfigProfile extends StatefulWidget {
  const ConfigProfile({super.key});

  @override
  State<ConfigProfile> createState() => _ConfigProfileState();
}

class _ConfigProfileState extends State<ConfigProfile> {
  // =================== ESTADO (mock) ===================
  // Notificaciones
  bool _notifMatches = true;
  bool _notifMessages = true;
  bool _notifActivities = true;
  bool _notifMarketing = false;

  // Privacidad y seguridad
  bool _showOnline = true;
  bool _showDistance = true;
  bool _showAge = true;
  bool _readReceipts = true;

  // Ubicación
  bool _showLocation = true;
  double _maxDistanceKm = 50;

  // General
  String _language = 'es';
  ThemeMode _themeMode = ThemeMode.system;
  bool _sounds = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        elevation: 0,
        backgroundColor: cs.surface,
      ),
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [cs.primary.withOpacity(0.06), cs.surface],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =================== NOTIFICACIONES ===================
                _SectionHeader(
                  icon: Icons.notifications_active_rounded,
                  iconColor: cs.primary,
                  bgColor: cs.primary.withOpacity(0.10),
                  title: 'Notificaciones',
                ),
                const SizedBox(height: 10),
                _SettingSwitchTile(
                  title: 'Nuevos matches',
                  subtitle:
                      'Recibe notificaciones cuando tengas un nuevo match',
                  value: _notifMatches,
                  onChanged: (v) => setState(() => _notifMatches = v),
                  icon: Icons.favorite_rounded,
                  iconColor: cs.primary,
                ),
                const SizedBox(height: 10),
                _SettingSwitchTile(
                  title: 'Mensajes',
                  subtitle: 'Notificaciones de nuevos mensajes',
                  value: _notifMessages,
                  onChanged: (v) => setState(() => _notifMessages = v),
                  icon: Icons.chat_bubble_rounded,
                  iconColor: cs.primary,
                ),
                const SizedBox(height: 10),
                _SettingSwitchTile(
                  title: 'Propuestas de actividades',
                  subtitle: 'Cuando alguien te proponga una actividad',
                  value: _notifActivities,
                  onChanged: (v) => setState(() => _notifActivities = v),
                  icon: Icons.event_available_rounded,
                  iconColor: cs.primary,
                ),
                const SizedBox(height: 10),
                _SettingSwitchTile(
                  title: 'Marketing y ofertas',
                  subtitle: 'Descuentos exclusivos de lugares afiliados',
                  value: _notifMarketing,
                  onChanged: (v) => setState(() => _notifMarketing = v),
                  icon: Icons.local_offer_rounded,
                  iconColor: cs.primary,
                ),

                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 18),

                // =================== PRIVACIDAD ===================
                _SectionHeader(
                  icon: Icons.privacy_tip_rounded,
                  iconColor: cs.secondary,
                  bgColor: cs.secondary.withOpacity(0.12),
                  title: 'Privacidad y Seguridad',
                ),
                const SizedBox(height: 10),
                _SettingSwitchTile(
                  title: 'Mostrar estado en línea',
                  subtitle: 'Otros usuarios pueden ver cuando estás activo',
                  value: _showOnline,
                  onChanged: (v) => setState(() => _showOnline = v),
                  icon: Icons.visibility_rounded,
                  iconColor: cs.secondary,
                ),
                const SizedBox(height: 10),
                _SettingSwitchTile(
                  title: 'Mostrar distancia',
                  subtitle: 'Muestra tu distancia aproximada a otros',
                  value: _showDistance,
                  onChanged: (v) => setState(() => _showDistance = v),
                  icon: Icons.social_distance_rounded,
                  iconColor: cs.secondary,
                ),
                const SizedBox(height: 10),
                _SettingSwitchTile(
                  title: 'Mostrar edad',
                  subtitle: 'Muestra tu edad en tu perfil',
                  value: _showAge,
                  onChanged: (v) => setState(() => _showAge = v),
                  icon: Icons.cake_rounded,
                  iconColor: cs.secondary,
                ),
                const SizedBox(height: 10),
                _SettingSwitchTile(
                  title: 'Confirmación de lectura',
                  subtitle: 'Los demás verán cuando leas sus mensajes',
                  value: _readReceipts,
                  onChanged: (v) => setState(() => _readReceipts = v),
                  icon: Icons.done_all_rounded,
                  iconColor: cs.secondary,
                ),

                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 18),

                // =================== UBICACIÓN ===================
                _SectionHeader(
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.pinkAccent,
                  bgColor: Colors.pinkAccent.withOpacity(0.12),
                  title: 'Ubicación',
                ),
                const SizedBox(height: 10),
                _SettingSwitchTile(
                  title: 'Mostrar mi ubicación',
                  subtitle: 'Permite que otros usuarios te encuentren',
                  value: _showLocation,
                  onChanged: (v) => setState(() => _showLocation = v),
                  icon: Icons.place_rounded,
                  iconColor: Colors.pinkAccent,
                ),
                const SizedBox(height: 12),
                _SettingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distancia máxima de búsqueda',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '5 km',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            '${_maxDistanceKm.toStringAsFixed(0)} km',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '100 km',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: cs.primary,
                          inactiveTrackColor: cs.primary.withOpacity(0.2),
                          thumbColor: cs.primary,
                        ),
                        child: Slider(
                          min: 5,
                          max: 100,
                          value: _maxDistanceKm,
                          onChanged: (v) {
                            setState(() => _maxDistanceKm = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 18),

                // =================== GENERAL ===================
                _SectionHeader(
                  icon: Icons.settings_suggest_rounded,
                  iconColor: cs.tertiary,
                  bgColor: cs.tertiary.withOpacity(0.12),
                  title: 'General',
                ),
                const SizedBox(height: 10),

                _SettingCard(
                  child: Row(
                    children: [
                      _IconBadge(
                        icon: Icons.language_rounded,
                        color: cs.tertiary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Idioma',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Idioma de la aplicación',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _language,
                          borderRadius: BorderRadius.circular(16),
                          items: const [
                            DropdownMenuItem(
                              value: 'es',
                              child: Text('Español'),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('Inglés'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _language = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                _SettingCard(
                  child: Row(
                    children: [
                      _IconBadge(
                        icon: Icons.dark_mode_rounded,
                        color: cs.tertiary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modo de apariencia',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Elige entre claro, oscuro o predeterminado del sistema',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<ThemeMode>(
                          value: _themeMode,
                          borderRadius: BorderRadius.circular(16),
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('Predeterminado'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Claro'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Oscuro'),
                            ),
                          ],
                          onChanged: (mode) {
                            if (mode == null) return;
                            setState(() => _themeMode = mode);
                            ThemeController.setThemeMode(
                              mode,
                            ); // 👈 aplica a toda la app
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                const SizedBox(height: 10),
                _SettingSwitchTile(
                  title: 'Sonidos',
                  subtitle: 'Sonidos de notificaciones y acciones',
                  value: _sounds,
                  onChanged: (v) => setState(() => _sounds = v),
                  icon: Icons.volume_up_rounded,
                  iconColor: cs.tertiary,
                ),

                const SizedBox(height: 22),
                const Divider(height: 1),
                const SizedBox(height: 18),

                // =================== ZONA DE PELIGRO ===================
                _SectionHeader(
                  icon: Icons.warning_amber_rounded,
                  iconColor: cs.error,
                  bgColor: cs.error.withOpacity(0.10),
                  title: 'Zona de Peligro',
                ),
                const SizedBox(height: 12),
                _SettingCard(
                  bgColor: cs.error.withOpacity(0.06),
                  borderColor: cs.error.withOpacity(0.30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.error,
                            foregroundColor: cs.onError,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () {
                            // TODO: lógica de desactivar cuenta
                          },
                          child: const Text('Desactivar cuenta'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Podrás reactivar tu cuenta cuando lo desees.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =================== WIDGETS REUTILIZABLES ===================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;
  final Color? bgColor;
  final Color? borderColor;

  const _SettingCard({required this.child, this.bgColor, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor ?? cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.16), color.withOpacity(0.30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final Color iconColor;

  const _SettingSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return _SettingCard(
      child: Row(
        children: [
          _IconBadge(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: cs.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
