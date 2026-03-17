import 'package:date_and_doing/views/home/date_flow/chat_timeline_api_item.dart';

class ChatTimelineApiMapper {
  static List<Map<String, dynamic>> extractMessages(
    List<ChatTimelineApiItem> items,
    int? currentUserId,
    String partnerName,
  ) {
    final result = <Map<String, dynamic>>[];

    for (final item in items) {
      if (item.isMessage) {
        final m = item.data;
        final createdAt = DateTime.tryParse(
              (m["ddmsg_timestamp_datecreate"] ?? "").toString(),
            ) ??
            item.timestamp;

        final senderId = m["use_int_sender"];
        final isMine =
            currentUserId != null && senderId.toString() == currentUserId.toString();

        result.add({
          "id": m["ddmsg_int_id"],
          "sender_id": senderId,
          "autor": isMine ? "Yo" : partnerName,
          "text": m["ddmsg_txt_body"] ?? "",
          "hora":
              "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}",
          "fecha": createdAt.toIso8601String().substring(0, 10),
          "is_read": m["ddmsg_bool_read"] == true,
          "is_temp": false,
          "is_system": false,
        });
      } else if (item.isEvent) {
        final e = item.data;
        final createdAt = DateTime.tryParse(
              (e["dde_timestamp_datecreate"] ?? "").toString(),
            ) ??
            item.timestamp;

        result.add({
          "id": "event_${e["dde_int_id"] ?? createdAt.millisecondsSinceEpoch}",
          "sender_id": -999,
          "autor": "Sistema",
          "text": (e["dde_txt_title"] ?? "").toString(),
          "hora":
              "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}",
          "fecha": createdAt.toIso8601String().substring(0, 10),
          "is_read": true,
          "is_temp": false,
          "is_system": true,
          "event_type": e["dde_txt_type"],
          "event_body": e["dde_txt_body"],
        });
      }
    }

    result.sort((a, b) {
      final da = DateTime.tryParse(
            "${a["fecha"]}T${a["hora"]}:00",
          ) ??
          DateTime.now();
      final db = DateTime.tryParse(
            "${b["fecha"]}T${b["hora"]}:00",
          ) ??
          DateTime.now();
      return da.compareTo(db);
    });

    return result;
  }
}