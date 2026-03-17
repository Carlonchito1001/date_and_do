import 'package:date_and_doing/models/dd_date.dart';

class ChatDatePermissions {
  final bool isCreator;
  final bool canRespond;
  final bool canConfirm;
  final bool canReject;
  final bool showWaitingLabel;

  const ChatDatePermissions({
    required this.isCreator,
    required this.canRespond,
    required this.canConfirm,
    required this.canReject,
    required this.showWaitingLabel,
  });

  factory ChatDatePermissions.fromDate({
    required DdDate date,
    required int? currentUserId,
  }) {
    final isCreator =
        currentUserId != null &&
        date.createdByUserId != null &&
        currentUserId == date.createdByUserId;

    final canRespond = !isCreator && date.isPending;
    final canConfirm = canRespond;
    final canReject = canRespond;
    final showWaitingLabel = isCreator && date.isPending;

    return ChatDatePermissions(
      isCreator: isCreator,
      canRespond: canRespond,
      canConfirm: canConfirm,
      canReject: canReject,
      showWaitingLabel: showWaitingLabel,
    );
  }
}