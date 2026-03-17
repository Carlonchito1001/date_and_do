import 'package:flutter/material.dart';
import 'package:date_and_doing/models/dd_date.dart';

class ChatDateCard extends StatelessWidget {
  final DdDate date;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final bool isCreator;
  final String creatorName;

  const ChatDateCard({
    super.key,
    required this.date,
    this.onConfirm,
    this.onReject,
    required this.isCreator,
    required this.creatorName,
  });

  Color _statusColor() {
    if (date.isConfirmed) return Colors.green;
    if (date.isRejected) return Colors.red;
    if (date.isCompleted) return Colors.blueGrey;
    return Colors.orange;
  }

  IconData _statusIcon() {
    if (date.isConfirmed) return Icons.check_circle_rounded;
    if (date.isRejected) return Icons.cancel_rounded;
    if (date.isCompleted) return Icons.emoji_events_rounded;
    return Icons.schedule_rounded;
  }

  String _statusText() {
    if (date.isConfirmed) return "Cita confirmada";
    if (date.isRejected) return "Cita rechazada";
    if (date.isCompleted) return "Cita completada";
    return "Cita pendiente";
  }

  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return "$dd/$mm/$yyyy • $hh:$mi";
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
          colors: [
            statusColor.withOpacity(0.10),
            cs.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.35),
          width: 1.4,
        ),
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
            // Estado
            Row(
              children: [
                Icon(
                  _statusIcon(),
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _statusText(),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Quién propuso
            Text(
              isCreator
                  ? "Tú propusiste esta cita"
                  : "$creatorName te propuso una cita",
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.65),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 14),

            // Título
            Text(
              date.title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            // Descripción
            if (date.description.trim().isNotEmpty)
              Text(
                date.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.80),
                  height: 1.35,
                ),
              ),

            if (date.description.trim().isNotEmpty) const SizedBox(height: 12),

            // Fecha
            Row(
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
                      color: cs.onSurface.withOpacity(0.85),
                    ),
                  ),
                ),
              ],
            ),

            // Pendiente y yo soy receptor: mostrar botones
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

            // Pendiente y yo soy creador
            if (date.isPending && isCreator)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      size: 18,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Esperando respuesta...",
                      style: textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Confirmada
            if (date.isConfirmed)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 18,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Esta cita ya forma parte de su historia ✨",
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Rechazada
            if (date.isRejected)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "La propuesta no fue aceptada.",
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Completada
            if (date.isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 18,
                      color: Colors.blueGrey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Cita completada. Un nuevo recuerdo fue creado 🌍",
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.blueGrey.shade700,
                          fontWeight: FontWeight.w600,
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