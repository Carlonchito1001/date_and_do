class UserSettingsModel {
  final bool notifMatches;
  final bool notifMessages;
  final bool notifActivities;
  final bool notifMarketing;
  final bool sounds;
  final String language;

  UserSettingsModel({
    required this.notifMatches,
    required this.notifMessages,
    required this.notifActivities,
    required this.notifMarketing,
    required this.sounds,
    required this.language,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      notifMatches: json['dds_bool_notif_matches'] ?? true,
      notifMessages: json['dds_bool_notif_messages'] ?? true,
      notifActivities: json['dds_bool_notif_activities'] ?? true,
      notifMarketing: json['dds_bool_notif_marketing'] ?? false,
      sounds: json['dds_bool_sounds'] ?? true,
      language: json['dds_txt_language'] ?? 'es',
    );
  }

  Map<String, dynamic> toPatch() {
    return {
      'dds_bool_notif_matches': notifMatches,
      'dds_bool_notif_messages': notifMessages,
      'dds_bool_notif_activities': notifActivities,
      'dds_bool_notif_marketing': notifMarketing,
      'dds_bool_sounds': sounds,
      'dds_txt_language': language,
    };
  }
}
