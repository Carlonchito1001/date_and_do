import 'package:date_and_doing/models/dd_date.dart';

class ChatDateHighlight {
  static DdDate? pick(List<DdDate> dates, int? currentUserId) {
    if (dates.isEmpty) return null;

    final sorted = [...dates]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    for (final d in sorted) {
      if (d.isPending &&
          currentUserId != null &&
          d.createdByUserId != null &&
          d.createdByUserId != currentUserId) {
        return d;
      }
    }

    for (final d in sorted) {
      if (d.isConfirmed && d.scheduledAt.isAfter(DateTime.now())) {
        return d;
      }
    }

    for (final d in sorted.reversed) {
      if (d.isCanceled) return d;
    }

    for (final d in sorted.reversed) {
      if (d.isRejected) return d;
    }

    for (final d in sorted) {
      if (d.isPending &&
          currentUserId != null &&
          d.createdByUserId != null &&
          d.createdByUserId == currentUserId) {
        return d;
      }
    }

    final completed = sorted.where((d) => d.isCompleted).toList();
    if (completed.isNotEmpty) {
      return completed.last;
    }

    return null;
  }
}
