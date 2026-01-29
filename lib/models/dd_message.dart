class DdMessage {
  final int id; // ddmsg_int_id
  final int matchId; // ddm_int_id
  final int senderId; // use_int_sender
  final int receiverId; // use_int_receiver
  final String body; // ddmsg_txt_body
  final bool isRead; // ddmsg_bool_read
  final String status; // ddmsg_txt_status
  final DateTime createdAt; // ddmsg_timestamp_datecreate

  // flags UI
  final bool sending;
  final bool error;

  DdMessage({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.isRead,
    required this.status,
    required this.createdAt,
    this.sending = false,
    this.error = false,
  });

  factory DdMessage.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v) => v is int ? v : int.parse(v.toString());
    bool toBool(dynamic v) => v == true || v?.toString() == "true";

    return DdMessage(
      id: toInt(j["ddmsg_int_id"] ?? j["id"]),
      matchId: toInt(j["ddm_int_id"] ?? j["match_id"]),
      senderId: toInt(j["use_int_sender"] ?? j["sender_id"]),
      receiverId: toInt(j["use_int_receiver"] ?? j["receiver_id"]),
      body: (j["ddmsg_txt_body"] ?? j["body"] ?? "").toString(),
      isRead: toBool(j["ddmsg_bool_read"] ?? j["is_read"]),
      status: (j["ddmsg_txt_status"] ?? j["status"] ?? "").toString(),
      createdAt: DateTime.tryParse(
            (j["ddmsg_timestamp_datecreate"] ?? j["created_at"]).toString(),
          ) ??
          DateTime.now(),
    );
  }

  DdMessage copyWith({
    bool? sending,
    bool? error,
  }) {
    return DdMessage(
      id: id,
      matchId: matchId,
      senderId: senderId,
      receiverId: receiverId,
      body: body,
      isRead: isRead,
      status: status,
      createdAt: createdAt,
      sending: sending ?? this.sending,
      error: error ?? this.error,
    );
  }
}
