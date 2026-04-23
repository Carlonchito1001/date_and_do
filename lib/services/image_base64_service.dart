import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageBase64Service {
  static Future<File> normalizeOrientation(File file) async {
    try {
      final rotated = await FlutterExifRotation.rotateImage(path: file.path);
      return rotated;
    } catch (_) {
      return file;
    }
  }

  static Future<Uint8List> compressToJpegBytes(
    File file, {
    int quality = 72,
    int minWidth = 720,
    int minHeight = 720,
  }) async {
    final normalized = await normalizeOrientation(file);

    final result = await FlutterImageCompress.compressWithFile(
      normalized.absolute.path,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      return await normalized.readAsBytes();
    }
    return result;
  }

  static String bytesToBase64(Uint8List bytes) => base64Encode(bytes);

  static String bytesToDataUriJpeg(Uint8List bytes) =>
      "data:image/jpeg;base64,${base64Encode(bytes)}";

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

  static Future<File> normalizeAndCompressToJpegFile(
    File file, {
    int quality = 75,
    int minWidth = 720,
    int minHeight = 720,
  }) async {
    final normalized = await normalizeOrientation(file);

    final bytes = await FlutterImageCompress.compressWithFile(
      normalized.absolute.path,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: CompressFormat.jpeg,
    );

    if (bytes == null) {
      return normalized;
    }

    final targetPath =
        '${normalized.parent.path}/fixed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outFile = File(targetPath);
    await outFile.writeAsBytes(bytes, flush: true);
    return outFile;
  }
}
