import 'package:date_and_doing/models/dd_date.dart';

class ChatDateHighlight {
  static DdDate? pick(List<DdDate> dates, int? currentUserId) {
    if (dates.isEmpty) return null;

    final sorted = [...dates]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    // 1) cita pendiente que yo debo responder
    for (final d in sorted) {
      if (d.isPending &&
          currentUserId != null &&
          d.createdByUserId != null &&
          d.createdByUserId != currentUserId) {
        return d;
      }
    }

    // 2) próxima cita confirmada
    for (final d in sorted) {
      if (d.isConfirmed && d.scheduledAt.isAfter(DateTime.now())) {
        return d;
      }
    }

    // 3) cita pendiente que yo propuse
    for (final d in sorted) {
      if (d.isPending &&
          currentUserId != null &&
          d.createdByUserId != null &&
          d.createdByUserId == currentUserId) {
        return d;
      }
    }

    // 4) última completada
    final completed = sorted.where((d) => d.isCompleted).toList();
    if (completed.isNotEmpty) {
      return completed.last;
    }

    return null;
  }
}