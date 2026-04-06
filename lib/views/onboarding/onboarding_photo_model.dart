class OnboardingPhotoModel {
  final int id;
  final String? filePath;
  final String? url;

  final String? previewBase64;
  final String? mimeType;
  final String? hash;
  final String? previewDataUri;
  final bool hasPreview;

  final bool isPrimary;
  final int order;
  final String status;

  const OnboardingPhotoModel({
    required this.id,
    required this.filePath,
    required this.url,
    required this.previewBase64,
    required this.mimeType,
    required this.hash,
    required this.previewDataUri,
    required this.hasPreview,
    required this.isPrimary,
    required this.order,
    required this.status,
  });

  factory OnboardingPhotoModel.fromJson(Map<String, dynamic> json) {
    return OnboardingPhotoModel(
      id: (json["ddphoto_int_id"] as num).toInt(),
      filePath: json["ddphoto_img_file"]?.toString(),
      url: json["ddphoto_url"]?.toString(),

      previewBase64: json["ddphoto_txt_preview_base64"]?.toString(),
      mimeType: json["ddphoto_txt_mime"]?.toString(),
      hash: json["ddphoto_txt_hash"]?.toString(),
      previewDataUri: json["ddphoto_preview_data_uri"]?.toString(),
      hasPreview: json["has_preview"] == true,

      isPrimary: json["ddphoto_bool_primary"] == true,
      order: (json["ddphoto_int_order"] as num?)?.toInt() ?? 0,
      status: (json["ddphoto_txt_status"] ?? "").toString(),
    );
  }
}