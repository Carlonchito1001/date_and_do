import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/views/onboarding/onboarding_profile_model.dart';
import 'package:date_and_doing/views/onboarding/onboarding_photo_page.dart';
import 'package:date_and_doing/location/location_service.dart';

class OnboardingProfilePage extends StatefulWidget {
  final VoidCallback? onCompleted;
  final bool isOnboardingFlow;

  const OnboardingProfilePage({
    super.key,
    this.onCompleted,
    this.isOnboardingFlow = false,
  });

  @override
  State<OnboardingProfilePage> createState() => _OnboardingProfilePageState();
}

class _OnboardingProfilePageState extends State<OnboardingProfilePage> {
  final ApiService _api = ApiService();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  final TextEditingController _jobCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController();

  DateTime? _selectedBirthDate;
  double? _selectedLatitude;
  double? _selectedLongitude;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  String _selectedGender = "";
  String _selectedLookingFor = "";

  final LocationService _locationService = LocationService();

  OnboardingProfileModel? _profile;

  final List<String> _genderOptions = const [
    "Masculino",
    "Femenino",
    "No binario",
    "Prefiero no decirlo",
  ];

  final List<String> _lookingForOptions = const [
    "Amistad",
    "Conocer gente",
    "Relación seria",
    "Citas casuales",
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoloadLocation();
    });
  }

  Future<void> _tryAutoloadLocation() async {
    if (_selectedLatitude != null && _selectedLongitude != null) return;

    final position = await _locationService.getCurrentPositionSafe();
    if (!mounted || position == null) return;

    setState(() {
      _selectedLatitude = position.latitude;
      _selectedLongitude = position.longitude;
    });
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _api.getOnboardingProfile();

      _nameCtrl.text = profile.fullName;
      _cityCtrl.text = profile.city;
      _countryCtrl.text = profile.country;
      _bioCtrl.text = profile.bio;
      _jobCtrl.text = profile.job;

      _ageCtrl.text = profile.age;
      _selectedLatitude = profile.latitude;
      _selectedLongitude = profile.longitude;

      _selectedGender = profile.gender;
      _selectedLookingFor = profile.lookingFor;

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _useRealLocation() async {
    try {
      final position = await _locationService.getCurrentPositionSafe();

      if (!mounted) return;

      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo obtener la ubicación real del dispositivo',
            ),
          ),
        );
        return;
      }

      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación actual obtenida correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error obteniendo ubicación: $e')));
    }
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final payload = {
        "use_txt_fullname": _nameCtrl.text.trim(),
        "use_txt_age": _ageCtrl.text.trim(),
        "use_txt_city": _cityCtrl.text.trim(),
        "use_txt_country": _countryCtrl.text.trim(),
        "use_double_latitude": _selectedLatitude,
        "use_double_longitude": _selectedLongitude,
        "ddp_txt_bio": _bioCtrl.text.trim(),
        "ddp_txt_gender": _selectedGender,
        "ddp_txt_looking_for": _selectedLookingFor,
        "ddp_txt_job": _jobCtrl.text.trim(),
      };

      debugPrint("ONBOARDING PAYLOAD => $payload");

      final updated = await _api.patchOnboardingProfile(data: payload);

      if (!mounted) return;

      if (widget.isOnboardingFlow) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const OnboardingPhotosPage(isOnboardingFlow: true),
          ),
        );
        return;
      }

      setState(() {
        _profile = updated;
        _saving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Perfil guardado")));

      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error guardando: $e")));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _bioCtrl.dispose();
    _jobCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isOnboardingFlow ? "Completa tu perfil" : "Editar perfil",
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _loadProfile)
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.isOnboardingFlow
                        ? "Haz que tu perfil se vea real y atractivo"
                        : "Actualiza tu información de perfil",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Completa tus datos para mejorar tus matches y tu experiencia en Date & Do.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _SectionCard(
                    title: "Nombre visible",
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        hintText: "Tu nombre",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _SectionCard(
                    title: "Edad",
                    child: TextField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "Ej. 27",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const SizedBox(height: 14),

                  _SectionCard(
                    title: "Ciudad",
                    child: TextField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        hintText: "Ej. Iquitos",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _SectionCard(
                    title: "País",
                    child: TextField(
                      controller: _countryCtrl,
                      decoration: const InputDecoration(
                        hintText: "Ej. Perú",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _SectionCard(
                    title: "Sobre ti",
                    child: TextField(
                      controller: _bioCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Cuéntales un poco sobre ti...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _SectionCard(
                    title: "Género",
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender.isEmpty ? null : _selectedGender,
                      items: _genderOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _selectedGender = v ?? "");
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _SectionCard(
                    title: "Qué buscas",
                    child: DropdownButtonFormField<String>(
                      value: _selectedLookingFor.isEmpty
                          ? null
                          : _selectedLookingFor,
                      items: _lookingForOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _selectedLookingFor = v ?? "");
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _SectionCard(
                    title: "A qué te dedicas",
                    child: TextField(
                      controller: _jobCtrl,
                      decoration: const InputDecoration(
                        hintText: "Ej. Diseñador gráfico",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _SectionCard(
                    title: "Ubicación",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedLatitude != null &&
                                  _selectedLongitude != null
                              ? "Ubicación actual detectada correctamente"
                              : "Aún no se ha definido ubicación exacta.",
                        ),
                        const SizedBox(height: 6),
                        if (_selectedLatitude != null &&
                            _selectedLongitude != null)
                          Text(
                            "Lat: ${_selectedLatitude!.toStringAsFixed(6)} | Lng: ${_selectedLongitude!.toStringAsFixed(6)}",
                          ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _useRealLocation,
                          icon: const Icon(Icons.my_location_rounded),
                          label: const Text("Usar mi ubicación actual"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: _saving ? null : _saveProfile,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.isOnboardingFlow
                                ? "Guardar y continuar"
                                : "Guardar cambios",
                          ),
                  ),

                  if (_profile != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _profile!.profileCompleted
                          ? "Tu perfil ya está completo."
                          : "Aún faltan datos del usuario base o una foto principal.",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56),
            const SizedBox(height: 12),
            Text(
              "No se pudo cargar tu perfil",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text("Reintentar")),
          ],
        ),
      ),
    );
  }
}
