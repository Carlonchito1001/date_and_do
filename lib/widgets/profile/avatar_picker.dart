import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/image_base64_service.dart';

class AvatarPickResult {
  final File file;
  final String base64; // base64 puro o data-uri según config
  final Uint8ListBytes? previewBytes; // opcional

  AvatarPickResult({
    required this.file,
    required this.base64,
    this.previewBytes,
  });
}

/// Wrapper para bytes (solo para tipar bonito)
class Uint8ListBytes {
  final List<int> bytes;
  Uint8ListBytes(this.bytes);
}

class AvatarPicker extends StatefulWidget {
  final String? initialImageUrl;
  final double radius;
  final List<Color> ringGradient;
  final ValueChanged<AvatarPickResult> onPicked;

  /// compresión
  final int quality;
  final int minSize;

  /// si tu backend requiere data:image/jpeg;base64,xxx
  final bool sendAsDataUri;

  const AvatarPicker({
    super.key,
    required this.onPicked,
    this.initialImageUrl,
    this.radius = 48,
    this.ringGradient = const [],
    this.quality = 72,
    this.minSize = 720,
    this.sendAsDataUri = false,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  final _picker = ImagePicker();
  bool _processing = false;

  File? _localFile;
  String? _localBase64;

  Future<void> _showPickSheet() async {
    final cs = Theme.of(context).colorScheme;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text("Elegir de galería"),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text("Tomar foto"),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null) return;
    await _pick(source);
  }

  Future<void> _pick(ImageSource source) async {
    try {
      setState(() => _processing = true);

      final xfile = await _picker.pickImage(
        source: source,
        imageQuality: 100, // NO confíes solo en esto, igual comprimimos nosotros
        maxWidth: 2000, // primer recorte suave
      );

      if (xfile == null) {
        if (mounted) setState(() => _processing = false);
        return;
      }

      final file = File(xfile.path);

      // Comprimir + base64
      final base64 = await ImageBase64Service.fileToBase64Jpeg(
        file,
        quality: widget.quality,
        minWidth: widget.minSize,
        minHeight: widget.minSize,
        dataUri: widget.sendAsDataUri,
      );

      if (!mounted) return;

      setState(() {
        _localFile = file;
        _localBase64 = base64;
        _processing = false;
      });

      widget.onPicked(
        AvatarPickResult(
          file: file,
          base64: base64,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error seleccionando imagen: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final hasGradient = widget.ringGradient.isNotEmpty;
    final ring = hasGradient
        ? BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: widget.ringGradient),
          )
        : BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary.withOpacity(0.12),
          );

    final imageProvider = _localFile != null
        ? FileImage(_localFile!)
        : (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty
            ? NetworkImage(widget.initialImageUrl!)
            : null);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: ring,
              child: CircleAvatar(
                radius: widget.radius,
                backgroundColor: cs.surface,
                backgroundImage: imageProvider as ImageProvider<Object>?,
                child: imageProvider == null
                    ? Icon(
                        Icons.person,
                        size: widget.radius,
                        color: cs.onSurface.withOpacity(0.65),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: InkWell(
                onTap: _processing ? null : _showPickSheet,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _processing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : Icon(
                          Icons.camera_alt_outlined,
                          size: 18,
                          color: cs.onPrimary,
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _processing ? null : _showPickSheet,
          icon: Icon(Icons.image_outlined, color: cs.primary),
          label: Text(
            _localBase64 == null ? "Cambiar foto" : "Foto lista para guardar",
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
