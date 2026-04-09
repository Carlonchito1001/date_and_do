class MatchProfilePhotoModel {
  final int id;
  final String url;
  final bool isPrimary;
  final int order;

  final String? previewBase64;
  final String? mimeType;
  final String? hash;

  const MatchProfilePhotoModel({
    required this.id,
    required this.url,
    required this.isPrimary,
    required this.order,
    required this.previewBase64,
    required this.mimeType,
    required this.hash,
  });

  factory MatchProfilePhotoModel.fromJson(Map<String, dynamic> json) {
    print("=== MATCH PROFILE PHOTO RAW ===");
    print(json);

    final preview = json["ddphoto_txt_preview_base64"]?.toString();
    final url = (json["ddphoto_url"] ?? "").toString();

    print("PHOTO URL: $url");
    print("PHOTO PREVIEW LEN: ${preview == null ? 'null' : preview.length}");

    return MatchProfilePhotoModel(
      id: (json["ddphoto_int_id"] as num).toInt(),
      url: url,
      isPrimary: json["ddphoto_bool_primary"] == true,
      order: (json["ddphoto_int_order"] as num?)?.toInt() ?? 0,
      previewBase64: preview,
      mimeType: json["ddphoto_txt_mime"]?.toString(),
      hash: json["ddphoto_txt_hash"]?.toString(),
    );
  }
}

class MatchProfileUserModel {
  final int id;
  final String fullName;
  final String age;
  final String city;
  final String country;
  final String? description;
  final String? gender;
  final String? occupation;
  final String? interests;
  final String? avatar;

  final String? onlineStatus;
  final DateTime? lastSeenAt;

  const MatchProfileUserModel({
    required this.id,
    required this.fullName,
    required this.age,
    required this.city,
    required this.country,
    this.description,
    this.gender,
    this.occupation,
    this.interests,
    this.avatar,
    this.onlineStatus,
    this.lastSeenAt,
  });

  factory MatchProfileUserModel.fromJson(Map<String, dynamic> json) {
    return MatchProfileUserModel(
      id: (json["use_int_id"] as num).toInt(),
      fullName: (json["use_txt_fullname"] ?? "").toString(),
      age: (json["use_txt_age"] ?? "").toString(),
      city: (json["use_txt_city"] ?? "").toString(),
      country: (json["use_txt_country"] ?? "").toString(),
      description: json["use_txt_description"]?.toString(),
      gender: json["use_txt_gender"]?.toString(),
      occupation: json["use_txt_occupation"]?.toString(),
      interests: json["use_txt_interests"]?.toString(),
      avatar: json["use_txt_avatar"]?.toString(),
      onlineStatus: json["online_status"]?.toString(),
      lastSeenAt:
          json["last_seen_at"] != null &&
              json["last_seen_at"].toString().isNotEmpty
          ? DateTime.tryParse(json["last_seen_at"].toString())?.toLocal()
          : null,
    );
  }
}

class MatchProfileDdProfileModel {
  final String bio;
  final String gender;
  final String lookingFor;
  final String job;

  const MatchProfileDdProfileModel({
    required this.bio,
    required this.gender,
    required this.lookingFor,
    required this.job,
  });

  factory MatchProfileDdProfileModel.fromJson(Map<String, dynamic> json) {
    return MatchProfileDdProfileModel(
      bio: (json["ddp_txt_bio"] ?? "").toString(),
      gender: (json["ddp_txt_gender"] ?? "").toString(),
      lookingFor: (json["ddp_txt_looking_for"] ?? "").toString(),
      job: (json["ddp_txt_job"] ?? "").toString(),
    );
  }
}

class MatchProfileModel {
  final int matchId;
  final MatchProfileUserModel otherUser;
  final MatchProfileDdProfileModel? ddProfile;
  final List<MatchProfilePhotoModel> photos;

  final bool dateEnabled;
  final int remainingChatDaysForDate;
  final int chatDaysCount;

  const MatchProfileModel({
    required this.matchId,
    required this.otherUser,
    required this.ddProfile,
    required this.photos,
    required this.dateEnabled,
    required this.remainingChatDaysForDate,
    required this.chatDaysCount,
  });

  factory MatchProfileModel.fromJson(Map<String, dynamic> json) {
    print("=== MATCH PROFILE RAW ===");
    print(json);
    print(
      "RAW PHOTOS COUNT: ${(json["photos"] as List<dynamic>? ?? []).length}",
    );

    final rawPhotos = (json["photos"] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final photos =
        rawPhotos.map((e) => MatchProfilePhotoModel.fromJson(e)).toList()
          ..sort((a, b) {
            if (a.isPrimary && !b.isPrimary) return -1;
            if (!a.isPrimary && b.isPrimary) return 1;
            return a.order.compareTo(b.order);
          });

    print("PARSED PHOTOS COUNT: ${photos.length}");
    for (final p in photos) {
      print(
        "PHOTO => id=${p.id}, primary=${p.isPrimary}, url=${p.url}, previewLen=${p.previewBase64?.length}",
      );
    }

    return MatchProfileModel(
      matchId: (json["match_id"] as num).toInt(),
      otherUser: MatchProfileUserModel.fromJson(
        json["other_user"] as Map<String, dynamic>,
      ),
      ddProfile: json["dd_profile"] != null
          ? MatchProfileDdProfileModel.fromJson(
              json["dd_profile"] as Map<String, dynamic>,
            )
          : null,
      photos: photos,
      dateEnabled: json["date_enabled"] == true,
      remainingChatDaysForDate:
          (json["remaining_chat_days_for_date"] as num?)?.toInt() ?? 5,
      chatDaysCount: (json["chat_days_count"] as num?)?.toInt() ?? 0,
    );
  }
}
