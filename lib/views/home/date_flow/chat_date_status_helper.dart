import 'package:date_and_doing/models/dd_date.dart';

class ChatDateStatusHelper {
  static String statusLabel(DdDate date) {
    if (date.isConfirmed) return "¡Confirmada!";
    if (date.isRejected) return "Rechazada";
    if (date.isCompleted) return "Completada";
    return "Pendiente";
  }

  static bool shouldAppearInHistory(DdDate date) {
    return date.isConfirmed || date.isCompleted;
  }

  static bool isPendingForReceiver({
    required DdDate date,
    required int? currentUserId,
  }) {
    if (!date.isPending) return false;
    if (currentUserId == null) return false;
    if (date.createdByUserId == null) return false;

    return currentUserId != date.createdByUserId;
  }

  static bool isPendingForCreator({
    required DdDate date,
    required int? currentUserId,
  }) {
    if (!date.isPending) return false;
    if (currentUserId == null) return false;
    if (date.createdByUserId == null) return false;

    return currentUserId == date.createdByUserId;
  }
}