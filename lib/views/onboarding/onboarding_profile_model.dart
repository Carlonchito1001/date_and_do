class OnboardingProfileModel {
  final int? id;

  final String fullName;
  final String age;
  final String city;
  final String country;
  final double? latitude;
  final double? longitude;

  final String bio;
  final String gender;
  final String lookingFor;
  final String job;

  final bool profileCompleted;

  const OnboardingProfileModel({
    this.id,
    required this.fullName,
    required this.age,
    required this.city,
    required this.country,
    this.latitude,
    this.longitude,
    required this.bio,
    required this.gender,
    required this.lookingFor,
    required this.job,
    required this.profileCompleted,
  });

  factory OnboardingProfileModel.fromJson(Map<String, dynamic> json) {
    return OnboardingProfileModel(
      id: (json["ddp_int_id"] as num?)?.toInt(),
      fullName: (json["use_txt_fullname"] ?? "").toString(),
      age: (json["use_txt_age"] ?? "").toString(),
      city: (json["use_txt_city"] ?? "").toString(),
      country: (json["use_txt_country"] ?? "").toString(),
      latitude: (json["use_double_latitude"] as num?)?.toDouble(),
      longitude: (json["use_double_longitude"] as num?)?.toDouble(),
      bio: (json["ddp_txt_bio"] ?? "").toString(),
      gender: (json["ddp_txt_gender"] ?? "").toString(),
      lookingFor: (json["ddp_txt_looking_for"] ?? "").toString(),
      job: (json["ddp_txt_job"] ?? "").toString(),
      profileCompleted: json["ddp_bool_profile_completed"] == true,
    );
  }
}