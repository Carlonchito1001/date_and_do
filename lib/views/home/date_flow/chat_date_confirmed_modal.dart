import 'package:flutter/material.dart';
import 'package:date_and_doing/models/dd_date.dart';

Future<void> showChatDateConfirmedModal(
  BuildContext context, {
  required DdDate date,
}) async {
  final cs = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.14),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.green,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Nuevo capítulo desbloqueado",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "La cita fue confirmada ✨",
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              date.title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(date.scheduledAt),
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (date.description.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                date.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.78),
                ),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text("Entendido"),
          ),
        ],
      );
    },
  );
}

String _formatDate(DateTime dt) {
  final dd = dt.day.toString().padLeft(2, '0');
  final mm = dt.month.toString().padLeft(2, '0');
  final yyyy = dt.year.toString();
  final hh = dt.hour.toString().padLeft(2, '0');
  final mi = dt.minute.toString().padLeft(2, '0');
  return "$dd/$mm/$yyyy • $hh:$mi";
}