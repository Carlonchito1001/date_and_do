import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class UserPhotoView extends StatelessWidget {
  final String? base64String;
  final String? fallbackUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  const UserPhotoView({
    super.key,
    this.base64String,
    this.fallbackUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
  });

  Uint8List? _decodeBase64(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeBase64(base64String);

    Widget content;

    if (bytes != null) {
      content = Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.shade300,
              alignment: Alignment.center,
              child: const Icon(Icons.person),
            ),
      );
    } else if (fallbackUrl != null && fallbackUrl!.trim().isNotEmpty) {
      content = Image.network(
        fallbackUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.shade300,
              alignment: Alignment.center,
              child: const Icon(Icons.person),
            ),
      );
    } else {
      content =
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade300,
            alignment: Alignment.center,
            child: const Icon(Icons.person),
          );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }
}