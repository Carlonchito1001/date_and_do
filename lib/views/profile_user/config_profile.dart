import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import '../../theme/theme_controller.dart';

class ConfigProfile extends StatefulWidget {
  const ConfigProfile({super.key});

  @override
  State<ConfigProfile> createState() => _ConfigProfileState();
}

class _ConfigProfileState extends State<ConfigProfile> {
  final SharedPreferencesService _prefs = SharedPreferencesService();

  // =================== ESTADO ===================

  // Notificaciones
  bool _notifMatches = true;
  bool _notifMessages = true;
  bool _notifActivities = true;
  bool _notifMarketing = false;

  // Edad
  int _ageMin = 18;
  int _ageMax = 99;

  // Privacidad
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
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final token = await _prefs.getAccessToken();

      if (token != null) {
        final prefs = await ApiService().getPreferences(accessToken: token);

        _maxDistanceKm = (prefs["ddp_int_radius_km"] ?? 50).toDouble();
        _ageMin = prefs["ddp_int_age_min"] ?? 18;
        _ageMax = prefs["ddp_int_age_max"] ?? 99;
      }
    } catch (e) {
      debugPrint("Error cargando preferencias backend: $e");
    }

    _notifMatches = await _prefs.getBool("notif_matches") ?? true;
    _notifMessages = await _prefs.getBool("notif_messages") ?? true;
    _notifActivities = await _prefs.getBool("notif_activities") ?? true;
    _notifMarketing = await _prefs.getBool("notif_marketing") ?? false;
    _sounds = await _prefs.getBool("sounds") ?? true;
    _language = await _prefs.getStringValue("language") ?? 'es';

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveNotificationPrefs() async {
    await _prefs.saveBool("notif_matches", _notifMatches);
    await _prefs.saveBool("notif_messages", _notifMessages);
    await _prefs.saveBool("notif_activities", _notifActivities);
    await _prefs.saveBool("notif_marketing", _notifMarketing);
    await _prefs.saveBool("sounds", _sounds);
    await _prefs.saveStringValue("language", _language);
  }

  Future<void> _saveDistance(double value) async {
    setState(() {
      _maxDistanceKm = value;
    });

    await _prefs.saveMaxDistance(value.toInt());

    final token = await _prefs.getAccessToken();
    if (token == null) return;

    await ApiService().updatePreferences(
      accessToken: token,
      radiusKm: value.toInt(),
    );
  }

  Future<void> _saveAgeRange(RangeValues values) async {
    setState(() {
      _ageMin = values.start.round();
      _ageMax = values.end.round();
    });

    final token = await _prefs.getAccessToken();
    if (token == null) return;

    await ApiService().updatePreferences(
      accessToken: token,
      ageMin: _ageMin,
      ageMax: _ageMax,
    );
  }

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                icon: Icons.notifications,
                title: "Notificaciones",
              ),
              const SizedBox(height: 12),
              _SettingSwitchTile(
                title: "Nuevos matches",
                subtitle: "Recibe notificación cuando tengas un match",
                value: _notifMatches,
                icon: Icons.favorite,
                iconColor: cs.primary,
                onChanged: (v) async {
                  setState(() => _notifMatches = v);
                  await _saveNotificationPrefs();
                },
              ),
              const SizedBox(height: 10),
              _SettingSwitchTile(
                title: "Mensajes",
                subtitle: "Notificaciones de chat",
                value: _notifMessages,
                icon: Icons.chat,
                iconColor: cs.primary,
                onChanged: (v) async {
                  setState(() => _notifMessages = v);
                  await _saveNotificationPrefs();
                },
              ),
              const SizedBox(height: 10),
              _SettingSwitchTile(
                title: "Actividades",
                subtitle: "Cuando alguien te invite a algo",
                value: _notifActivities,
                icon: Icons.event,
                iconColor: cs.primary,
                onChanged: (v) async {
                  setState(() => _notifActivities = v);
                  await _saveNotificationPrefs();
                },
              ),
              const SizedBox(height: 10),
              _SettingSwitchTile(
                title: "Marketing",
                subtitle: "Promociones y ofertas",
                value: _notifMarketing,
                icon: Icons.local_offer,
                iconColor: cs.primary,
                onChanged: (v) async {
                  setState(() => _notifMarketing = v);
                  await _saveNotificationPrefs();
                },
              ),

              const SizedBox(height: 26),

              const _SectionHeader(icon: Icons.location_on, title: "Ubicación"),
              const SizedBox(height: 12),
              _SettingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Distancia máxima de búsqueda",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("5 km"),
                        Text(
                          "${_maxDistanceKm.toInt()} km",
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text("100 km"),
                      ],
                    ),
                    Slider(
                      min: 5,
                      max: 100,
                      divisions: 19,
                      value: _maxDistanceKm,
                      label: "${_maxDistanceKm.toInt()} km",
                      onChanged: (v) async {
                        await _saveDistance(v);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              const _SectionHeader(icon: Icons.cake, title: "Edad preferida"),
              const SizedBox(height: 12),
              _SettingCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$_ageMin años",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "$_ageMax años",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    RangeSlider(
                      min: 18,
                      max: 99,
                      values: RangeValues(
                        _ageMin.toDouble(),
                        _ageMax.toDouble(),
                      ),
                      labels: RangeLabels("$_ageMin", "$_ageMax"),
                      onChanged: (values) async {
                        await _saveAgeRange(values);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              const _SectionHeader(icon: Icons.settings, title: "General"),
              const SizedBox(height: 12),
              _SettingCard(
                child: Row(
                  children: [
                    const Icon(Icons.language),
                    const SizedBox(width: 12),
                    const Text("Idioma"),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _language,
                      items: const [
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                      ],
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _language = v);
                        await _saveNotificationPrefs();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SettingCard(
                child: Row(
                  children: [
                    const Icon(Icons.dark_mode),
                    const SizedBox(width: 12),
                    const Text("Tema"),
                    const Spacer(),
                    DropdownButton<ThemeMode>(
                      value: _themeMode,
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text("Sistema"),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text("Claro"),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text("Oscuro"),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode == null) return;
                        setState(() => _themeMode = mode);
                        ThemeController.setThemeMode(mode);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SettingSwitchTile(
                title: "Sonidos",
                subtitle: "Sonidos de notificaciones",
                value: _sounds,
                icon: Icons.volume_up,
                iconColor: cs.tertiary,
                onChanged: (v) async {
                  setState(() => _sounds = v);
                  await _saveNotificationPrefs();
                },
              ),

              const SizedBox(height: 30),

              const _SectionHeader(
                icon: Icons.warning_amber,
                title: "Zona de peligro",
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Desactivar cuenta",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;

  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
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
    return _SettingCard(
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
