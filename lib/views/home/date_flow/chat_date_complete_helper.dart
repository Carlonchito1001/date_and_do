import 'package:date_and_doing/models/dd_date.dart';

class ChatDateCompleteHelper {
  static bool canComplete(DdDate date) {
    if (!date.isConfirmed) return false;
    return date.scheduledAt.isBefore(DateTime.now());
  }
}