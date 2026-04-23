import 'package:date_and_doing/auth/google_auth_service.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:date_and_doing/views/login/dd_login.dart';
import 'package:date_and_doing/views/onboarding/onboarding_photo_model.dart';
import 'package:date_and_doing/views/onboarding/onboarding_photo_page.dart';
import 'package:date_and_doing/views/onboarding/onboarding_profile_page.dart';
import 'package:date_and_doing/views/profile_user/config_profile.dart';
import 'package:date_and_doing/views/profile_user/match_preferences_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_and_doing/widgets/cached_base64_photo.dart';
// import 'package:date_and_doing/helpers/photo_memory_cache_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:date_and_doing/services/image_base64_service.dart';

class HomeProfile extends StatefulWidget {
  const HomeProfile({super.key});

  @override
  State<HomeProfile> createState() => _HomeProfileState();
}

class _HomeProfileState extends State<HomeProfile>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();

  String userName = '';
  String userEmail = '';
  String? avatarUrl;

  List<OnboardingPhotoModel> _photos = [];

  bool loading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getInfoUser();
  }

  Future<void> _getInfoUser() async {
    try {
      final userInfo = await SharedPreferencesService().getUserInfo();
      final photos = await _api.getUserPhotos();

      if (!mounted) return;

      if (userInfo == null) {
        setState(() {
          hasError = true;
          errorMessage = 'No se encontró información del usuario';
          loading = false;
        });
        return;
      }

      OnboardingPhotoModel? primaryPhoto;
      if (photos.isNotEmpty) {
        try {
          primaryPhoto = photos.firstWhere((p) => p.isPrimary);
        } catch (_) {
          primaryPhoto = photos.first;
        }
      }

      setState(() {
        userName = userInfo['use_txt_fullname'] ?? '';
        userEmail = userInfo['use_txt_email'] ?? '';

        avatarUrl = userInfo['use_txt_avatar'];

        _photos = photos;

        hasError = false;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        hasError = true;
        errorMessage = 'Error al cargar el perfil. Intenta nuevamente.';
        loading = false;
      });
    }
  }

  Future<void> _refreshUserData() async {
    setState(() {
      loading = true;
      hasError = false;
    });
    await _getInfoUser();
  }

  String _getInitials(String value) {
    final parts = value.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      await GoogleAuthService().signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DdLogin()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;

    final bool? ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: cs.error),
              const SizedBox(width: 10),
              const Text("Cerrar sesión"),
            ],
          ),
          content: Text(
            "¿Seguro que deseas cerrar sesión? Tendrás que iniciar sesión nuevamente.",
            style: TextStyle(color: cs.onSurface.withOpacity(0.8)),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurface.withOpacity(0.8),
              ),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text("Sí, cerrar"),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await logout(context);
    }
  }

  Future<void> _openPhotoPreview(OnboardingPhotoModel photo) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _PhotoPreviewPage(photo: photo)),
    );

    if (updated == true) {
      await _refreshUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (loading) {
      return const _ProfileSkeleton();
    }

    if (hasError) {
      return _ErrorState(message: errorMessage, onRetry: _refreshUserData);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator(
        onRefresh: _refreshUserData,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Builder(
                      builder: (_) {
                        OnboardingPhotoModel? primaryPhoto;
                        if (_photos.isNotEmpty) {
                          try {
                            primaryPhoto = _photos.firstWhere(
                              (p) => p.isPrimary,
                            );
                          } catch (_) {
                            primaryPhoto = _photos.first;
                          }
                        }

                        return Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: primaryPhoto != null
                              ? CachedBase64Photo(
                                  photo: primaryPhoto,
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(999),
                                )
                              : (avatarUrl != null && avatarUrl!.isNotEmpty)
                              ? Image.network(
                                  avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      _getInitials(userName),
                                      style: textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _getInitials(userName),
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  userName.isNotEmpty ? userName : 'Usuario',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),

                if (_photos.isNotEmpty)
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final photo = _photos[i];

                        return GestureDetector(
                          onTap: () => _openPhotoPreview(photo),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 84,
                                  height: 84,
                                  color: Colors.grey.shade300,
                                  child: CachedBase64Photo(
                                    photo: photo,
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(16),
                                    errorWidget: const Icon(
                                      Icons.broken_image_rounded,
                                    ),
                                  ),
                                ),
                              ),
                              if (photo.isPrimary)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      "Principal",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "Aún no tienes fotos en tu álbum.",
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 24),

                _ProfileOptionCard(
                  icon: Icons.edit_note_rounded,
                  iconBgGradient: [
                    cs.secondary.withOpacity(0.18),
                    cs.secondaryContainer.withOpacity(0.35),
                  ],
                  iconColor: cs.secondary,
                  title: "Editar perfil",
                  subtitle: "Actualiza tus datos personales",
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnboardingProfilePage(
                          isOnboardingFlow: false,
                        ),
                      ),
                    );
                    await _refreshUserData();
                  },
                ),
                const SizedBox(height: 12),

                _ProfileOptionCard(
                  icon: Icons.photo_library_rounded,
                  iconBgGradient: [
                    Colors.pink.withOpacity(0.18),
                    Colors.pinkAccent.withOpacity(0.35),
                  ],
                  iconColor: Colors.pink,
                  title: "Editar fotos",
                  subtitle: "Administra tu álbum y tu foto principal",
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const OnboardingPhotosPage(isOnboardingFlow: false),
                      ),
                    );
                    await _refreshUserData();
                  },
                ),
                const SizedBox(height: 12),

                _ProfileOptionCard(
                  icon: Icons.tune_rounded,
                  iconBgGradient: [
                    cs.primary.withOpacity(0.18),
                    cs.primaryContainer.withOpacity(0.35),
                  ],
                  iconColor: cs.primary,
                  title: "Preferencias de Match",
                  subtitle: "Define qué perfiles quieres encontrar",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MatchPreferencesPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _ProfileOptionCard(
                  icon: Icons.settings_outlined,
                  iconBgGradient: [
                    cs.tertiary.withOpacity(0.18),
                    cs.tertiaryContainer.withOpacity(0.35),
                  ],
                  iconColor: cs.tertiary,
                  title: "Configuración",
                  subtitle: "Ajusta tu experiencia en la app",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ConfigProfile()),
                    );
                  },
                ),
                const SizedBox(height: 20),

                const Divider(),
                const SizedBox(height: 20),

                _ProfileOptionCard(
                  icon: Icons.logout_rounded,
                  iconBgGradient: [
                    Colors.red.withOpacity(0.18),
                    Colors.redAccent.withOpacity(0.35),
                  ],
                  iconColor: Colors.red,
                  title: "Cerrar Sesión",
                  subtitle: "Salir de tu cuenta actual",
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPreviewPage extends StatefulWidget {
  final OnboardingPhotoModel photo;

  const _PhotoPreviewPage({required this.photo});

  @override
  State<_PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<_PhotoPreviewPage> {
  final ApiService _api = ApiService();

  int _quarterTurns = 0;
  bool _saving = false;

  void _rotateLeft() {
    setState(() {
      _quarterTurns = (_quarterTurns - 1) % 4;
    });
  }

  void _rotateRight() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  Future<File> _buildEditableSourceFile() async {
    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/editable_photo_${widget.photo.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    if ((widget.photo.url ?? '').trim().isNotEmpty) {
      final response = await http.get(Uri.parse(widget.photo.url!));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes, flush: true);
        return file;
      }
    }

    final preview = widget.photo.previewBase64 ?? '';
    if (preview.trim().isNotEmpty) {
      final file = File(filePath);
      await file.writeAsBytes(base64Decode(preview), flush: true);
      return file;
    }

    throw Exception('No se pudo obtener el archivo original de la foto.');
  }

  Future<void> _editAndSave() async {
    if (_saving) return;

    try {
      setState(() => _saving = true);

      final sourceFile = await _buildEditableSourceFile();

      final cropped = await ImageCropper().cropImage(
        sourcePath: sourceFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Editar foto',
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Editar foto',
            rotateButtonsHidden: false,
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );

      if (cropped == null) {
        if (!mounted) return;
        setState(() => _saving = false);
        return;
      }

      File editedFile = File(cropped.path);

      if (_quarterTurns != 0) {
        editedFile = await _rotateFileByQuarterTurns(
          editedFile,
          ((_quarterTurns % 4) + 4) % 4,
        );
      }

      final fixedFile = await ImageBase64Service.normalizeAndCompressToJpegFile(
        editedFile,
        quality: 80,
        minWidth: 1080,
        minHeight: 1080,
      );

      await _api.updateUserPhoto(
        photoId: widget.photo.id,
        imageFile: fixedFile,
      );

      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto actualizada correctamente")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error guardando foto: $e")));
    }
  }

  Future<File> _rotateFileByQuarterTurns(File inputFile, int turns) async {
    if (turns == 0) return inputFile;

    final cropped = await ImageCropper().cropImage(
      sourcePath: inputFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar rotación',
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
          hideBottomControls: false,
          initAspectRatio: CropAspectRatioPreset.original,
        ),
        IOSUiSettings(
          title: 'Ajustar rotación',
          rotateButtonsHidden: false,
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
        ),
      ],
    );

    if (cropped != null) {
      return File(cropped.path);
    }

    return inputFile;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final turns = ((_quarterTurns % 4) + 4) % 4;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.photo.isPrimary ? "Foto principal" : "Foto"),
        actions: [
          IconButton(
            tooltip: "Girar izquierda",
            onPressed: _saving ? null : _rotateLeft,
            icon: const Icon(Icons.rotate_left_rounded),
          ),
          IconButton(
            tooltip: "Girar derecha",
            onPressed: _saving ? null : _rotateRight,
            icon: const Icon(Icons.rotate_right_rounded),
          ),
          TextButton.icon(
            onPressed: _saving ? null : _editAndSave,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: const Text("Guardar"),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: RotatedBox(
                quarterTurns: turns,
                child: CachedBase64Photo(
                  photo: widget.photo,
                  fit: BoxFit.contain,
                  errorWidget: Icon(
                    Icons.broken_image_rounded,
                    color: cs.error,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Text(
                  turns == 0
                      ? "Puedes girar, hacer zoom y luego guardar"
                      : "Rotación lista: ${turns * 90}° · toca Guardar",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
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

class _ProfileOptionCard extends StatelessWidget {
  final IconData icon;
  final List<Color> iconBgGradient;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOptionCard({
    required this.icon,
    required this.iconBgGradient,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(colors: iconBgGradient),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ],
        ),
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: cs.error),
              const SizedBox(height: 16),
              Text(
                "Ups, algo salió mal",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Reintentar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSkeleton extends StatefulWidget {
  const _ProfileSkeleton();

  @override
  State<_ProfileSkeleton> createState() => _ProfileSkeletonState();
}

class _ProfileSkeletonState extends State<_ProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();

    _animation = Tween<double>(begin: -1, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _ShimmerWidget(
                animation: _animation,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _ShimmerWidget(
                animation: _animation,
                child: Container(
                  width: 180,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ShimmerWidget(
                animation: _animation,
                child: Container(
                  width: 220,
                  height: 16,
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _ShimmerWidget(
                animation: _animation,
                child: SizedBox(
                  height: 92,
                  child: Row(
                    children: List.generate(
                      3,
                      (i) => Container(
                        width: 84,
                        height: 84,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildCardSkeleton(cs),
              const SizedBox(height: 12),
              _buildCardSkeleton(cs),
              const SizedBox(height: 12),
              _buildCardSkeleton(cs),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              _buildCardSkeleton(cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSkeleton(ColorScheme cs) {
    return _ShimmerWidget(
      animation: _animation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 180,
                    height: 12,
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerWidget extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _ShimmerWidget({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.surfaceVariant,
                cs.surfaceVariant.withOpacity(0.5),
                cs.surfaceVariant,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(
                slidePercent: animation.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
