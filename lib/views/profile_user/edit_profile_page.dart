import 'dart:convert';
import 'dart:io';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String? _selectedCountry;
  String? _selectedCity;

  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  String _fullName = '';
  String _ageText = '';
  String? _avatarUrl;

  // Avatar nuevo (base64)
  final ImagePicker _picker = ImagePicker();
  File? _avatarFile;
  String? _avatarBase64DataUri; // data:image/jpeg;base64,...

  bool _loading = true;
  bool _saving = false;

  static const int _maxAboutChars = 300;

  final List<String> _countries = ["Perú", "México", "Argentina", "Chile"];
  final List<String> _cities = ["Iquitos", "Lima", "Cusco", "Arequipa"];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _occupationController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final sp = SharedPreferencesService();
    final userInfo = await sp.getUserInfo();

    if (!mounted) return;

    if (userInfo != null) {
      final fullname = (userInfo['use_txt_fullname'] ?? '').toString();
      final age = userInfo['use_txt_age'];
      final country = userInfo['use_txt_country'];
      final city = userInfo['use_txt_city'];
      final occupation = userInfo['use_txt_occupation'];
      final desc = userInfo['use_txt_description'];
      final avatar = userInfo['use_txt_avatar'];

      setState(() {
        _fullName = fullname.isEmpty ? 'Usuario' : fullname;
        _ageText = (age == null || age.toString().trim().isEmpty)
            ? '—'
            : age.toString();

        _selectedCountry =
            (country == null || country.toString().trim().isEmpty)
            ? null
            : country.toString();
        _selectedCity = (city == null || city.toString().trim().isEmpty)
            ? null
            : city.toString();

        _occupationController.text = (occupation ?? '').toString();
        _aboutController.text = (desc ?? '').toString();

        _avatarUrl = (avatar == null || avatar.toString().trim().isEmpty)
            ? null
            : avatar.toString();

        // reset avatar nuevo
        _avatarFile = null;
        _avatarBase64DataUri = null;

        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  // ===================== Avatar (iOS style) =====================

  void _openAvatarSheet() {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iosSheetItem(
                  icon: Icons.photo_library_outlined,
                  title: "Elegir de galería",
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAvatar(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                _iosSheetItem(
                  icon: Icons.photo_camera_outlined,
                  title: "Tomar foto",
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAvatar(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.onSurface.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: cs.surfaceVariant.withOpacity(0.6),
                    ),
                    child: const Text("Cancelar"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _iosSheetItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.8)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.45)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        maxWidth: 2400,
      );
      if (xfile == null) return;

      final original = File(xfile.path);
      final compressed = await _compressToJpeg(original);
      final bytes = await compressed.readAsBytes();

      final b64 = base64Encode(bytes);

      if (!mounted) return;
      setState(() {
        _avatarFile = compressed;
        _avatarBase64DataUri = "data:image/jpeg;base64,$b64";
      });
    } catch (e) {
      _toast("Error seleccionando imagen: $e");
    }
  }

  Future<File> _compressToJpeg(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 75,
      minWidth: 720,
      minHeight: 720,
      format: CompressFormat.jpeg,
    );

    if (result == null) return file;
    return File(result.path);
  }

  // ===================== Payload / Save =====================

  Map<String, dynamic> _buildPayload() {
    final Map<String, dynamic> payload = {};

    void putIfValid(String key, dynamic value) {
      if (value == null) return;
      if (value is String) {
        final v = value.trim();
        if (v.isEmpty) return;
        payload[key] = v;
        return;
      }
      payload[key] = value;
    }

    putIfValid('use_txt_country', _selectedCountry);
    putIfValid('use_txt_city', _selectedCity);
    putIfValid('use_txt_occupation', _occupationController.text);
    putIfValid('use_txt_description', _aboutController.text);

    // Avatar: si cambió -> base64. Si no -> no lo mandamos (mantiene URL existente).
    if (_avatarBase64DataUri != null && _avatarBase64DataUri!.isNotEmpty) {
      putIfValid('use_txt_avatar', _avatarBase64DataUri);
    }

    return payload;
  }

  Future<void> _saveProfile() async {
    final sp = SharedPreferencesService();

    final accessToken = await sp.getAccessToken();
    final userInfo = await sp.getUserInfo();

    if (accessToken == null || accessToken.isEmpty) {
      _toast('No hay access token. Vuelve a iniciar sesión.');
      return;
    }
    if (userInfo == null) {
      _toast('No hay userInfo guardado.');
      return;
    }

    final idRaw = userInfo['use_int_id'];
    if (idRaw == null) {
      _toast('userInfo no trae use_int_id.');
      return;
    }
    final int userId = (idRaw as num).toInt();

    final payload = _buildPayload();
    if (payload.isEmpty) {
      _toast('No hay cambios para guardar.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiService().editarPerfil(
        accessToken: accessToken,
        perfilData: payload,
        id: userId,
      );

      final refreshed = await ApiService().infoUser(accessToken: accessToken);
      await sp.saveUserInfo(refreshed);

      if (!mounted) return;
      setState(() => _saving = false);

      _toast('Perfil actualizado ✅');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Error: $e');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ===================== iOS-ish UI =====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Editar perfil"),
          backgroundColor: cs.surface,
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final aboutLength = _aboutController.text.length;

    ImageProvider? avatarProvider;
    if (_avatarFile != null) {
      avatarProvider = FileImage(_avatarFile!);
    } else if (_avatarUrl != null && _avatarUrl!.trim().isNotEmpty) {
      avatarProvider = NetworkImage(_avatarUrl!);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text("Editar perfil"),
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card (iOS style)
              _card(
                context,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [cs.primary, cs.secondary],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: cs.surface,
                            backgroundImage: avatarProvider,
                            child: avatarProvider == null
                                ? Icon(
                                    Icons.person,
                                    size: 46,
                                    color: cs.onSurface.withOpacity(0.65),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: InkWell(
                            onTap: _openAvatarSheet,
                            borderRadius: BorderRadius.circular(999),
                            child: Ink(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.shadow.withOpacity(0.18),
                                    blurRadius: 14,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                                color: cs.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _fullName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ageText == '—' ? '—' : '$_ageText años',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_avatarBase64DataUri != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Foto lista para guardar (optimizada).",
                          style: textTheme.bodySmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // No editable section (iOS settings group)
              _sectionTitle(context, "Datos protegidos"),
              const SizedBox(height: 8),
              _card(
                context,
                child: Column(
                  children: [
                    _readOnlyRow(
                      context,
                      icon: Icons.person_outline,
                      title: "Nombre Completo",
                      value: _fullName,
                    ),
                    _divider(context),
                    _readOnlyRow(
                      context,
                      icon: Icons.cake_outlined,
                      title: "Edad",
                      value: _ageText == '—' ? '—' : '$_ageText años',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Editable section
              _sectionTitle(context, "Información editable"),
              const SizedBox(height: 8),
              _card(
                context,
                child: Column(
                  children: [
                    _fieldBlock(
                      context,
                      label: "País",
                      child: _buildDropdownField(
                        context,
                        value: _selectedCountry,
                        hint: "Selecciona un país",
                        items: _countries,
                        onChanged: (value) =>
                            setState(() => _selectedCountry = value),
                      ),
                    ),
                    _divider(context),
                    _fieldBlock(
                      context,
                      label: "Ciudad",
                      child: _buildDropdownField(
                        context,
                        value: _selectedCity,
                        hint: "Selecciona una ciudad",
                        items: _cities,
                        onChanged: (value) =>
                            setState(() => _selectedCity = value),
                      ),
                    ),
                    _divider(context),
                    _fieldBlock(
                      context,
                      label: "Ocupación",
                      child: TextField(
                        controller: _occupationController,
                        decoration: _inputDecoration(context).copyWith(
                          prefixIcon: const Icon(Icons.work_outline),
                          hintText: "Tu ocupación",
                        ),
                      ),
                    ),
                    _divider(context),
                    _fieldBlock(
                      context,
                      label: "Algo sobre mí",
                      footer: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Máximo $_maxAboutChars caracteres",
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            "$aboutLength/$_maxAboutChars",
                            style: textTheme.bodySmall?.copyWith(
                              color: aboutLength > _maxAboutChars
                                  ? cs.error
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _aboutController,
                        maxLines: 5,
                        maxLength: _maxAboutChars,
                        onChanged: (_) => setState(() {}),
                        decoration: _inputDecoration(
                          context,
                        ).copyWith(alignLabelWithHint: true, counterText: ""),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Security info (tu card, pero con look iOS)
              _card(context, child: _buildSecurityCard(context)),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Guardar cambios"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== iOS-ish components ======

  Widget _card(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: tt.labelSmall?.copyWith(
            color: cs.onSurface.withOpacity(0.55),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }

  Widget _divider(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: cs.outlineVariant.withOpacity(0.75)),
    );
  }

  Widget _readOnlyRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.65),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _fieldBlock(
    BuildContext context, {
    required String label,
    required Widget child,
    Widget? footer,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(0.75),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (footer != null) ...[const SizedBox(height: 8), footer],
      ],
    );
  }

  // ====== tus helpers originales (solo reusados) ======

  Widget _buildDropdownField(
    BuildContext context, {
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(context),
      icon: Icon(Icons.arrow_drop_down, color: cs.onSurface.withOpacity(0.7)),
      hint: Text(hint),
      items: items
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: cs.surface.withOpacity(0.55),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildSecurityCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Datos protegidos por seguridad",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Tu nombre y edad no pueden ser modificados para garantizar la autenticidad y seguridad de todos los usuarios de la plataforma.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Si necesitas modificar estos datos, por favor contacta a nuestro equipo de soporte.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
