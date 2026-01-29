import 'package:flutter/material.dart';
import 'package:date_and_doing/models/dd_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final DdMessage msg;
  final bool isMine;

  const ChatMessageBubble({
    super.key,
    required this.msg,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bubbleColor =
        isMine ? cs.primary.withOpacity(0.15) : cs.surfaceVariant;
    final textColor = cs.onSurface;

    final timeText =
        "${msg.createdAt.hour.toString().padLeft(2, "0")}:${msg.createdAt.minute.toString().padLeft(2, "0")}";

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: msg.error
              ? Border.all(color: cs.error.withOpacity(0.8), width: 1.2)
              : null,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.body,
              style: textTheme.bodyMedium?.copyWith(color: textColor),
            ),
            const SizedBox(height: 2),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeText,
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 6),

                if (isMine) ...[
                  if (msg.sending)
                    Text(
                      "⏳",
                      style: textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    )
                  else if (msg.error)
                    Text(
                      "⚠️",
                      style: textTheme.labelSmall?.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  else
                    Text(
                      msg.isRead ? "✓✓" : "✓",
                      style: textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
