import 'package:flutter/material.dart';
import 'package:date_and_doing/models/dd_date.dart';

Future<void> showChatDateBannerSheet(
  BuildContext context, {
  required DdDate date,
  required bool isCreator,
  VoidCallback? onConfirm,
  VoidCallback? onReject,
}) async {
  final cs = Theme.of(context).colorScheme;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _statusColor(date).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon(date),
                      color: _statusColor(date),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusTitle(date, isCreator),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _InfoRow(
                icon: Icons.title_rounded,
                label: "Título",
                value: date.title,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.notes_rounded,
                label: "Descripción",
                value: date.description.trim().isEmpty
                    ? "Sin descripción"
                    : date.description,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                label: "Fecha",
                value: _formatDate(date.scheduledAt),
              ),

              const SizedBox(height: 18),

              if (date.isPending && !isCreator) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Aceptar"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onReject?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Rechazar"),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Cerrar"),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.65),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(DdDate date) {
  if (date.isConfirmed) return Colors.green;
  if (date.isRejected) return Colors.red;
  if (date.isCompleted) return Colors.blueGrey;
  return Colors.orange;
}

IconData _statusIcon(DdDate date) {
  if (date.isConfirmed) return Icons.event_available_rounded;
  if (date.isRejected) return Icons.event_busy_rounded;
  if (date.isCompleted) return Icons.emoji_events_rounded;
  return Icons.schedule_rounded;
}

String _statusTitle(DdDate date, bool isCreator) {
  if (date.isConfirmed) return "Cita confirmada";
  if (date.isRejected) return "Cita rechazada";
  if (date.isCompleted) return "Cita completada";
  return isCreator ? "Esperando respuesta" : "Propuesta pendiente";
}

String _formatDate(DateTime dt) {
  final dd = dt.day.toString().padLeft(2, '0');
  final mm = dt.month.toString().padLeft(2, '0');
  final yyyy = dt.year.toString();
  final hh = dt.hour.toString().padLeft(2, '0');
  final mi = dt.minute.toString().padLeft(2, '0');
  return "$dd/$mm/$yyyy • $hh:$mi";
}