class DdDate {
  final int id;
  final int matchId;
  final int? createdByUserId;
  final int? decidedByUserId;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? decisionAt;

  DdDate({
    required this.id,
    required this.matchId,
    required this.title,
    required this.description,
    required this.scheduledAt,
    required this.status,
    this.createdByUserId,
    this.decidedByUserId,
    this.createdAt,
    this.updatedAt,
    this.decisionAt,
  });

  factory DdDate.fromJson(Map<String, dynamic> map) {
    return DdDate(
      id: (map["ddd_int_id"] ?? map["id"] as num).toInt(),
      matchId:
          (map["ddm_int_id"] is Map
                  ? map["ddm_int_id"]["ddm_int_id"]
                  : map["ddm_int_id"])
              is num
          ? ((map["ddm_int_id"] is Map
                        ? map["ddm_int_id"]["ddm_int_id"]
                        : map["ddm_int_id"])
                    as num)
                .toInt()
          : int.parse(
              (map["ddm_int_id"] is Map
                      ? map["ddm_int_id"]["ddm_int_id"]
                      : map["ddm_int_id"])
                  .toString(),
            ),
      createdByUserId: (map["use_int_createdby"] as num?)?.toInt(),
      decidedByUserId: (map["use_int_decidedby"] as num?)?.toInt(),
      title: (map["ddd_txt_title"] ?? "").toString(),
      description: (map["ddd_txt_description"] ?? "").toString(),
      scheduledAt: DateTime.parse(map["ddd_timestamp_date"].toString()),
      status: (map["ddd_txt_status"] ?? "PENDING").toString(),
      createdAt: map["ddd_timestamp_datecreate"] != null
          ? DateTime.tryParse(map["ddd_timestamp_datecreate"].toString())
          : null,
      updatedAt: map["ddd_timestamp_dateupdate"] != null
          ? DateTime.tryParse(map["ddd_timestamp_dateupdate"].toString())
          : null,
      decisionAt:
          map["ddd_timestamp_decision"] != null &&
              map["ddd_timestamp_decision"].toString().isNotEmpty
          ? DateTime.tryParse(map["ddd_timestamp_decision"].toString())
          : null,
    );
  }

  bool get isPending => statusUpper == "PENDING";
  bool get isConfirmed => statusUpper == "CONFIRMED";
  bool get isRejected => statusUpper == "REJECTED";
  bool get isCompleted => statusUpper == "COMPLETED";

  String get statusUpper => status.toUpperCase();
}
