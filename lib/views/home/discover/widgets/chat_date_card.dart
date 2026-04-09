import 'package:flutter/material.dart';
import 'package:date_and_doing/models/dd_date.dart';

class ChatDateCard extends StatelessWidget {
  final DdDate date;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final bool isCreator;
  final String creatorName;

  const ChatDateCard({
    super.key,
    required this.date,
    this.onConfirm,
    this.onReject,
    this.onComplete,
    this.onCancel,
    this.onReschedule,
    required this.isCreator,
    required this.creatorName,
  });

  Color _statusColor() {
    if (date.isConfirmed) return Colors.green;
    if (date.isRejected) return Colors.red;
    if (date.isCanceled) return Colors.orange;
    if (date.isCompleted) return Colors.blueGrey;
    return Colors.orange;
  }

  IconData _statusIcon() {
    if (date.isConfirmed) return Icons.check_circle_rounded;
    if (date.isRejected) return Icons.cancel_rounded;
    if (date.isCanceled) return Icons.block_rounded;
    if (date.isCompleted) return Icons.emoji_events_rounded;
    return Icons.schedule_rounded;
  }

  String _statusText() {
    if (date.isConfirmed) return "Cita confirmada";
    if (date.isRejected) return "Cita rechazada";
    if (date.isCanceled) return "Cita cancelada";
    if (date.isCompleted) return "Cita completada";
    return "Cita pendiente";
  }

  String _headlineText() {
    if (date.isPending) {
      return isCreator
          ? "Tú propusiste esta cita"
          : "$creatorName te propuso una cita";
    }

    if (date.isConfirmed) {
      return isCreator
          ? "Tu propuesta fue aceptada"
          : "Aceptaste esta propuesta";
    }

    if (date.isRejected) {
      return isCreator
          ? "Tu propuesta fue rechazada"
          : "Rechazaste esta propuesta";
    }

    if (date.isCanceled) {
      return "Esta cita fue cancelada";
    }

    if (date.isCompleted) {
      return "Esta cita ya forma parte de su historia";
    }

    return "Estado de la cita";
  }

  String _supportText() {
    if (date.isPending && isCreator) {
      return "Tu match todavía no responde esta invitación.";
    }

    if (date.isPending && !isCreator) {
      return "Puedes aceptar o rechazar esta propuesta.";
    }

    if (date.isConfirmed) {
      return "Ya tienen un plan confirmado ✨";
    }

    if (date.isRejected) {
      return "Esta propuesta no continuó.";
    }

    if (date.isCanceled) {
      return "La actividad ya no sigue en pie.";
    }

    if (date.isCompleted) {
      return "Un nuevo recuerdo fue creado 🌍";
    }

    return "";
  }

  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return "$dd/$mm/$yyyy • $hh:$mi";
  }

  Widget _statusBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(), color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            _statusText(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = _statusColor();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [statusColor.withOpacity(0.10), cs.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.35), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statusBadge(statusColor),

            const SizedBox(height: 12),

            Text(
              _headlineText(),
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.68),
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              date.title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),

            if (date.description.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                date.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.82),
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outline.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDate(date.scheduledAt),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withOpacity(0.86),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_supportText().isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    date.isConfirmed
                        ? Icons.favorite_rounded
                        : date.isRejected
                        ? Icons.info_outline_rounded
                        : date.isCanceled
                        ? Icons.info_outline_rounded
                        : date.isCompleted
                        ? Icons.emoji_events_rounded
                        : Icons.hourglass_top_rounded,
                    size: 18,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _supportText(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (date.isPending && !isCreator) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Aceptar",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onReject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Rechazar",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (date.isConfirmed && onComplete != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.emoji_events_rounded, size: 18),
                    label: const Text(
                      "Marcar como realizada",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),

            if ((date.isPending || date.isConfirmed) &&
                (onCancel != null || onReschedule != null))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    if (onCancel != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "Cancelar",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    if (onCancel != null && onReschedule != null)
                      const SizedBox(width: 10),
                    if (onReschedule != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReschedule,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blueGrey,
                            side: const BorderSide(color: Colors.blueGrey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "Reprogramar",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
