import 'package:date_and_doing/models/dd_date.dart';

class ChatDateTimelineFilter {
  static List<DdDate> pickRelevant(List<DdDate> dates, int? currentUserId) {
    if (dates.isEmpty) return [];

    final sorted = [...dates]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final List<DdDate> result = [];

    // 1. pendiente que yo debo responder
    DdDate? pendingForMe;
    for (final d in sorted) {
      if (d.isPending &&
          currentUserId != null &&
          d.createdByUserId != null &&
          d.createdByUserId != currentUserId) {
        pendingForMe = d;
        break;
      }
    }
    if (pendingForMe != null) result.add(pendingForMe);

    // 2. próxima confirmada
    DdDate? nextConfirmed;
    for (final d in sorted) {
      if (d.isConfirmed && d.scheduledAt.isAfter(DateTime.now())) {
        nextConfirmed = d;
        break;
      }
    }
    if (nextConfirmed != null &&
        !result.any((e) => e.id == nextConfirmed!.id)) {
      result.add(nextConfirmed);
    }

    // 3. última completada
    final completed = sorted.where((d) => d.isCompleted).toList();
    if (completed.isNotEmpty) {
      final lastCompleted = completed.last;
      if (!result.any((e) => e.id == lastCompleted.id)) {
        result.add(lastCompleted);
      }
    }

    // 4. si no había nada de arriba, muestra la primera pendiente creada por mí
    if (result.isEmpty) {
      for (final d in sorted) {
        if (d.isPending &&
            currentUserId != null &&
            d.createdByUserId != null &&
            d.createdByUserId == currentUserId) {
          result.add(d);
          break;
        }
      }
    }

    return result;
  }
}
