import 'package:flutter/material.dart';

class ChatSystemMessageBubble extends StatelessWidget {
  final String message;

  const ChatSystemMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cs.primary.withOpacity(0.18),
            ),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withOpacity(0.78),
                ),
          ),
        ),
      ),
    );
  }
}