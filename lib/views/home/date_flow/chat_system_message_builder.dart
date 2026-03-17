import 'package:date_and_doing/models/dd_date.dart';

class ChatSystemMessageBuilder {
  static Map<String, dynamic> dateCreated({
    required DdDate date,
    required String actorName,
  }) {
    return {
      "id": "sys_created_${date.id}_${DateTime.now().millisecondsSinceEpoch}",
      "sender_id": -999,
      "autor": "Sistema",
      "text": "$actorName propuso una cita: ${date.title}",
      "hora": _timeFrom(date),
      "fecha": _dateFrom(date),
      "is_read": true,
      "is_temp": false,
      "is_system": true,
    };
  }

  static Map<String, dynamic> dateConfirmed({
    required DdDate date,
    required String actorName,
  }) {
    return {
      "id": "sys_confirmed_${date.id}_${DateTime.now().millisecondsSinceEpoch}",
      "sender_id": -999,
      "autor": "Sistema",
      "text": "$actorName confirmó la cita: ${date.title}",
      "hora": _timeFrom(date),
      "fecha": _dateFrom(date),
      "is_read": true,
      "is_temp": false,
      "is_system": true,
    };
  }

  static Map<String, dynamic> dateRejected({
    required DdDate date,
    required String actorName,
  }) {
    return {
      "id": "sys_rejected_${date.id}_${DateTime.now().millisecondsSinceEpoch}",
      "sender_id": -999,
      "autor": "Sistema",
      "text": "$actorName rechazó la cita: ${date.title}",
      "hora": _timeFrom(date),
      "fecha": _dateFrom(date),
      "is_read": true,
      "is_temp": false,
      "is_system": true,
    };
  }

  static String _timeFrom(DdDate date) {
    final dt = date.decisionAt ?? date.createdAt ?? DateTime.now();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  static String _dateFrom(DdDate date) {
    final dt = date.decisionAt ?? date.createdAt ?? DateTime.now();
    return dt.toIso8601String().substring(0, 10);
  }
}