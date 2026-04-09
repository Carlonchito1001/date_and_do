import 'package:date_and_doing/views/home/date_flow/chat_timeline_api_item.dart';

class ChatTimelineApiMapper {
  static DateTime _safeToLocal(dynamic raw, DateTime fallback) {
    if (raw == null) return fallback.toLocal();

    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return fallback.toLocal();
    }
  }

  static String _formatHour(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _formatDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static List<Map<String, dynamic>> extractMessages(
    List<ChatTimelineApiItem> items,
    int? currentUserId,
    String partnerName,
  ) {
    final result = <Map<String, dynamic>>[];

    for (final item in items) {
      if (item.isMessage) {
        final m = item.data;

        final createdAt = _safeToLocal(
          m["ddmsg_timestamp_datecreate"],
          item.timestamp,
        );

        final senderId = m["use_int_sender"];
        final isMine =
            currentUserId != null &&
            senderId.toString() == currentUserId.toString();

        result.add({
          "id": m["ddmsg_int_id"],
          "sender_id": senderId,
          "autor": isMine ? "Yo" : partnerName,
          "text": m["ddmsg_txt_body"] ?? "",
          "hora": _formatHour(createdAt),
          "fecha": _formatDateKey(createdAt),
          "created_at_iso": createdAt.toIso8601String(),
          "sort_ts_ms": createdAt.millisecondsSinceEpoch,
          "is_read": m["ddmsg_bool_read"] == true,
          "is_temp": false,
          "is_system": false,
        });
      } else if (item.isEvent) {
        final e = item.data;

        final createdAt = _safeToLocal(
          e["dde_timestamp_datecreate"],
          item.timestamp,
        );

        result.add({
          "id": "event_${e["dde_int_id"] ?? createdAt.millisecondsSinceEpoch}",
          "sender_id": -999,
          "autor": "Sistema",
          "text": (e["dde_txt_title"] ?? "").toString(),
          "hora": _formatHour(createdAt),
          "fecha": _formatDateKey(createdAt),
          "created_at_iso": createdAt.toIso8601String(),
          "sort_ts_ms": createdAt.millisecondsSinceEpoch,
          "is_read": true,
          "is_temp": false,
          "is_system": true,
          "event_type": e["dde_txt_type"],
          "event_body": e["dde_txt_body"],
        });
      }
    }

    result.sort((a, b) {
      final aTs = (a["sort_ts_ms"] as int?) ?? 0;
      final bTs = (b["sort_ts_ms"] as int?) ?? 0;
      return aTs.compareTo(bTs);
    });

    return result;
  }
}
