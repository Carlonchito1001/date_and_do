import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:date_and_doing/helpers/photo_memory_cache_helper.dart';
import 'package:date_and_doing/views/onboarding/onboarding_photo_model.dart';

class CachedBase64Photo extends StatelessWidget {
  final OnboardingPhotoModel photo;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  const CachedBase64Photo({
    super.key,
    required this.photo,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = PhotoMemoryCacheHelper.getBytes(
      photoId: photo.id,
      hash: photo.hash,
      base64String: photo.previewBase64,
    );

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
              child: const Icon(Icons.broken_image_rounded),
            ),
      );
    } else if (photo.url != null && photo.url!.isNotEmpty) {
      content = Image.network(
        photo.url!,
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
              child: const Icon(Icons.broken_image_rounded),
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
            child: const Icon(Icons.image_not_supported_rounded),
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