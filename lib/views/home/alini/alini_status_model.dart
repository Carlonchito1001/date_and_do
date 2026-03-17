class AliniStatusModel {
  final bool enabled;
  final int chatDaysCount;
  final int remainingChatDays;
  final DateTime? unlockedAt;

  const AliniStatusModel({
    required this.enabled,
    required this.chatDaysCount,
    required this.remainingChatDays,
    this.unlockedAt,
  });

  factory AliniStatusModel.fromJson(Map<String, dynamic> json) {
    return AliniStatusModel(
      enabled: json["alini_enabled"] == true,
      chatDaysCount: (json["chat_days_count"] as num?)?.toInt() ?? 0,
      remainingChatDays: (json["remaining_chat_days"] as num?)?.toInt() ?? 3,
      unlockedAt:
          json["alini_unlocked_at"] != null &&
              json["alini_unlocked_at"].toString().isNotEmpty
          ? DateTime.tryParse(json["alini_unlocked_at"].toString())
          : null,
    );
  }

  AliniStatusModel copyWith({
    bool? enabled,
    int? chatDaysCount,
    int? remainingChatDays,
    DateTime? unlockedAt,
  }) {
    return AliniStatusModel(
      enabled: enabled ?? this.enabled,
      chatDaysCount: chatDaysCount ?? this.chatDaysCount,
      remainingChatDays: remainingChatDays ?? this.remainingChatDays,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  static const empty = AliniStatusModel(
    enabled: false,
    chatDaysCount: 0,
    remainingChatDays: 3,
    unlockedAt: null,
  );
}
