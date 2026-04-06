import 'dart:convert';
import 'dart:typed_data';

class PhotoMemoryCacheHelper {
  static final Map<String, Uint8List> _cache = {};

  static Uint8List? getBytes({
    required int photoId,
    required String? hash,
    required String? base64String,
  }) {
    if (base64String == null || base64String.isEmpty) return null;

    final key = '${photoId}_${hash ?? "nohash"}';

    final existing = _cache[key];
    if (existing != null) return existing;

    try {
      final bytes = base64Decode(base64String);
      _cache[key] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  static void invalidatePhoto(int photoId) {
    _cache.removeWhere((key, value) => key.startsWith('${photoId}_'));
  }

  static void clearAll() {
    _cache.clear();
  }
}