import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoPermissionHelper {
  static Future<bool> requestPhotoPermission({
    required BuildContext context,
    required ImageSource source,
  }) async {
    // Para galería NO pedimos permiso manual.
    // image_picker abre el selector nativo y evita problemas en Android 13/14/15.
    if (source == ImageSource.gallery) {
      return true;
    }

    final status = await Permission.camera.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    final requested = await Permission.camera.request();

    if (requested.isGranted || requested.isLimited) {
      return true;
    }

    if (!context.mounted) return false;

    if (requested.isPermanentlyDenied || requested.isRestricted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Permiso requerido"),
          content: const Text(
            "Para tomar una foto, debes activar el permiso de cámara desde la configuración de la aplicación.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: const Text("Abrir configuración"),
            ),
          ],
        ),
      );

      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Necesitas permitir la cámara para tomar una foto."),
      ),
    );

    return false;
  }
}
