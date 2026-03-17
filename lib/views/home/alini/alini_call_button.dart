import 'package:flutter/material.dart';
import 'package:date_and_doing/widgets/modal_alini_unlocked.dart';
import 'package:date_and_doing/widgets/modal_day_chat.dart';
import 'alini_status_model.dart';

class AliniCallButton extends StatelessWidget {
  final AliniStatusModel status;
  final VoidCallback onStartCall;

  const AliniCallButton({
    super.key,
    required this.status,
    required this.onStartCall,
  });

  Future<void> _handleTap(BuildContext context) async {
    if (status.enabled) {
      onStartCall();
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ModalDayChat(chatDay: status.remainingChatDays),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(right: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.videocam_rounded,
                size: 24,
                color: status.enabled
                    ? cs.primary
                    : cs.onSurface.withOpacity(0.55),
              ),
              if (!status.enabled)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Icon(Icons.lock_rounded, size: 12, color: cs.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
