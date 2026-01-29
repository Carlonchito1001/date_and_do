import 'package:flutter/material.dart';
import 'package:date_and_doing/models/dd_date.dart';

class DateCard extends StatelessWidget {
  final DdDate date;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;

  const DateCard({
    super.key,
    required this.date,
    this.onConfirm,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final chip = date.isConfirmed
        ? "CONFIRMADA ✅"
        : date.isRejected
            ? "RECHAZADA ❌"
            : "ACTIVO ⏳";

    final dt = date.scheduledAt;
    final dateLabel =
        "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: cs.onSurface.withOpacity(0.7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  date.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  chip,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            date.description,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dateLabel,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w700,
            ),
          ),

          if (date.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    child: const Text("Confirmar"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text("Rechazar"),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
