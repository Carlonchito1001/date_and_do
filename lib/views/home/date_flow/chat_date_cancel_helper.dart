import 'package:date_and_doing/models/dd_date.dart';

class ChatDateCancelHelper {
  static bool canCancel(DdDate date) {
    return date.isPending || date.isConfirmed;
  }
}
