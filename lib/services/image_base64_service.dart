import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageBase64Service {
  /// Comprime y devuelve bytes JPEG.
  /// - maxWidth/maxHeight controlan tamaño final
  /// - quality 60-85 suele verse bien en perfiles
  static Future<Uint8List> compressToJpegBytes(
    File file, {
    int quality = 72,
    int minWidth = 720,
    int minHeight = 720,
  }) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      // fallback: si falla compresión, usa original
      return await file.readAsBytes();
    }
    return result;
  }

  /// Devuelve base64 puro (sin data:image/...).
  static String bytesToBase64(Uint8List bytes) => base64Encode(bytes);

  /// Devuelve data-uri: data:image/jpeg;base64,xxxx
  static String bytesToDataUriJpeg(Uint8List bytes) =>
      "data:image/jpeg;base64,${base64Encode(bytes)}";

  /// Flujo completo: File -> (compress) -> base64
  static Future<String> fileToBase64Jpeg(
    File file, {
    int quality = 72,
    int minWidth = 720,
    int minHeight = 720,
    bool dataUri = false,
  }) async {
    final bytes = await compressToJpegBytes(
      file,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
    );
    return dataUri ? bytesToDataUriJpeg(bytes) : bytesToBase64(bytes);
  }
}
