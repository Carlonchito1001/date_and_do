class DdDate {
  final int id; // ddd_int_id
  final int matchId; // ddm_int_id
  final String title; // ddd_txt_title
  final String description; // ddd_txt_description
  final DateTime scheduledAt; // ddd_timestamp_date
  final String status; // ddd_txt_status

  DdDate({
    required this.id,
    required this.matchId,
    required this.title,
    required this.description,
    required this.scheduledAt,
    required this.status,
  });

  factory DdDate.fromJson(Map<String, dynamic> j) {
    int pickInt(dynamic v) => v is int ? v : int.parse(v.toString());

    return DdDate(
      id: pickInt(j["ddd_int_id"] ?? j["id"]),
      matchId: pickInt(j["ddm_int_id"] ?? j["match_id"]),
      title: (j["ddd_txt_title"] ?? "").toString(),
      description: (j["ddd_txt_description"] ?? "").toString(),
      scheduledAt: DateTime.parse(j["ddd_timestamp_date"].toString()),
      status: (j["ddd_txt_status"] ?? "").toString(),
    );
  }

  String get statusUpper => status.toUpperCase();

  bool get isPending => statusUpper == "ACTIVO"; // tu backend
  bool get isConfirmed => statusUpper == "CONFIRMADA";
  bool get isRejected => statusUpper == "RECHAZADA";
}
