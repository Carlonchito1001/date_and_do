import 'package:date_and_doing/models/dd_date.dart';

class ChatDateActionPolicy {
  final bool isCreator;
  final bool isReceiver;

  final bool canConfirm;
  final bool canReject;
  final bool canCancel;
  final bool canReschedule;
  final bool canComplete;

  final bool showWaitingLabel;

  const ChatDateActionPolicy({
    required this.isCreator,
    required this.isReceiver,
    required this.canConfirm,
    required this.canReject,
    required this.canCancel,
    required this.canReschedule,
    required this.canComplete,
    required this.showWaitingLabel,
  });

  factory ChatDateActionPolicy.fromDate({
    required DdDate date,
    required int? currentUserId,
  }) {
    final isCreator =
        currentUserId != null &&
        date.createdByUserId != null &&
        currentUserId == date.createdByUserId;

    final isReceiver =
        currentUserId != null &&
        date.createdByUserId != null &&
        currentUserId != date.createdByUserId;

    final isPast = date.scheduledAt.isBefore(DateTime.now());

    bool canConfirm = false;
    bool canReject = false;
    bool canCancel = false;
    bool canReschedule = false;
    bool canComplete = false;
    bool showWaitingLabel = false;

    if (date.isPending) {
      if (isCreator) {
        canCancel = true;
        canReschedule = true;
        showWaitingLabel = true;
      } else if (isReceiver) {
        canConfirm = true;
        canReject = true;
        canReschedule = true;
      }
    } else if (date.isConfirmed) {
      if (isPast) {
        canComplete = true;
      } else {
        canCancel = true;
        canReschedule = true;
      }
    }

    return ChatDateActionPolicy(
      isCreator: isCreator,
      isReceiver: isReceiver,
      canConfirm: canConfirm,
      canReject: canReject,
      canCancel: canCancel,
      canReschedule: canReschedule,
      canComplete: canComplete,
      showWaitingLabel: showWaitingLabel,
    );
  }
}