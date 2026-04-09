import 'package:flutter/material.dart';
import '../utils/chat_date_utils.dart';

class ChatDateSeparator extends StatelessWidget {
  final DateTime date;

  const ChatDateSeparator({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = ChatDateUtils.formatSeparatorLabel(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: cs.outline.withOpacity(0.12),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.55),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: cs.outline.withOpacity(0.08),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withOpacity(0.72),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: cs.outline.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}