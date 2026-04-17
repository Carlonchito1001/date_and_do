import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/views/onboarding/onboarding_photo_model.dart';
import '../home/dd_home.dart';
import 'package:date_and_doing/widgets/cached_base64_photo.dart';
import 'package:date_and_doing/helpers/photo_memory_cache_helper.dart';
import 'package:date_and_doing/services/image_base64_service.dart';

class OnboardingPhotosPage extends StatefulWidget {
  final bool isOnboardingFlow;

  const OnboardingPhotosPage({super.key, this.isOnboardingFlow = true});

  @override
  State<OnboardingPhotosPage> createState() => _OnboardingPhotosPageState();
}

class _OnboardingPhotosPageState extends State<OnboardingPhotosPage> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _uploading = false;
  bool _continuing = false;
  String? _error;

  bool _cameraAutoOpened = false;

  List<OnboardingPhotoModel> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final photos = await _api.getUserPhotos();

      if (!mounted) return;

      setState(() {
        _photos = photos;
        _loading = false;
      });

      if (widget.isOnboardingFlow && photos.isEmpty && !_cameraAutoOpened) {
        _cameraAutoOpened = true;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _pickAndUploadPhoto(source: ImageSource.camera);
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickAndUploadPhoto({
    ImageSource source = ImageSource.gallery,
  }) async {
    if (_uploading) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (picked == null) {
        if (!mounted) return;

        if (widget.isOnboardingFlow && _photos.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Necesitas tomar o subir al menos una foto para continuar.",
              ),
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() => _uploading = true);

      final originalFile = File(picked.path);

      final fixedFile = await ImageBase64Service.normalizeAndCompressToJpegFile(
        originalFile,
        quality: 80,
        minWidth: 1080,
        minHeight: 1080,
      );

      await _api.uploadUserPhoto(fixedFile);
      await _loadPhotos();

      if (!mounted) return;

      setState(() => _uploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto subida correctamente")),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _uploading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error subiendo foto: $e")));
    }
  }

  Future<void> _makePrimary(OnboardingPhotoModel photo) async {
    try {
      await _api.makeUserPhotoPrimary(photo.id);
      await _loadPhotos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto principal actualizada")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error marcando principal: $e")));
    }
  }

  Future<void> _deletePhoto(OnboardingPhotoModel photo) async {
    try {
      PhotoMemoryCacheHelper.invalidatePhoto(photo.id);
      await _api.deleteUserPhoto(photo.id);
      await _loadPhotos();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Foto eliminada")));

      // Si sigue en onboarding y se quedó sin fotos, volver a abrir cámara una vez
      if (widget.isOnboardingFlow && _photos.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _pickAndUploadPhoto(source: ImageSource.camera);
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error eliminando foto: $e")));
    }
  }

  Future<void> _continue() async {
    if (_continuing) return;

    if (widget.isOnboardingFlow && _photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes agregar al menos una foto para continuar."),
        ),
      );
      return;
    }

    try {
      if (!mounted) return;
      setState(() => _continuing = true);

      final profile = await _api.getOnboardingProfile();

      if (!mounted) return;

      setState(() => _continuing = false);

      if (widget.isOnboardingFlow) {
        if (profile.profileCompleted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DdHome()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Aún falta completar algunos datos del perfil o definir una foto principal.",
              ),
            ),
          );
        }
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _continuing = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error validando perfil: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOnboardingFlow ? "Tus fotos" : "Editar fotos"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _loadPhotos)
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          "Agrega fotos para que tu perfil destaque",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tu primera foto será muy importante. También puedes elegir cuál será la principal.",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _uploading
                                    ? null
                                    : () => _pickAndUploadPhoto(
                                        source: ImageSource.camera,
                                      ),
                                icon: _uploading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.photo_camera_rounded),
                                label: Text(
                                  _uploading ? "Subiendo..." : "Tomar foto",
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _uploading
                                    ? null
                                    : () => _pickAndUploadPhoto(
                                        source: ImageSource.gallery,
                                      ),
                                icon: const Icon(Icons.photo_library_rounded),
                                label: const Text("Galería"),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        if (_photos.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(
                                alpha: 0.25,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Text(
                              "Aún no tienes fotos. Toma una foto con tu cámara para continuar.",
                            ),
                          )
                        else
                          ..._photos.map(
                            (photo) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _PhotoCard(
                                photo: photo,
                                onMakePrimary: () => _makePrimary(photo),
                                onDelete: () => _deletePhoto(photo),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: (_continuing || _uploading)
                              ? null
                              : _continue,
                          child: _continuing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.isOnboardingFlow
                                      ? "Continuar"
                                      : "Guardar y volver",
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final OnboardingPhotoModel photo;
  final VoidCallback onMakePrimary;
  final VoidCallback onDelete;

  const _PhotoCard({
    required this.photo,
    required this.onMakePrimary,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: CachedBase64Photo(
                photo: photo,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_rounded, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: photo.isPrimary
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Foto principal",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: onMakePrimary,
                        child: const Text("Hacer principal"),
                      ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.red,
              ),
            ],
          ),
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
              "No se pudieron cargar tus fotos",
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
