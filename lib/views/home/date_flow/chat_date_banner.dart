import 'package:flutter/material.dart';
import 'package:date_and_doing/models/dd_date.dart';

class ChatDateBanner extends StatelessWidget {
  final DdDate date;
  final bool isCreator;
  final VoidCallback? onTap;

  const ChatDateBanner({
    super.key,
    required this.date,
    required this.isCreator,
    this.onTap,
  });

  Color _bannerColor() {
    if (date.isConfirmed) return Colors.green;
    if (date.isRejected) return Colors.red;
    if (date.isCompleted) return Colors.blueGrey;
    return Colors.orange;
  }

  IconData _bannerIcon() {
    if (date.isConfirmed) return Icons.event_available_rounded;
    if (date.isRejected) return Icons.event_busy_rounded;
    if (date.isCompleted) return Icons.emoji_events_rounded;
    return Icons.schedule_rounded;
  }

  String _title() {
    if (date.isConfirmed) return "Próxima cita";
    if (date.isRejected) return "Cita rechazada";
    if (date.isCompleted) return "Recuerdo completado";
    return isCreator
        ? "Esperando respuesta"
        : "Tienes una propuesta pendiente";
  }

  String _subtitle() {
    final formattedDate = _formatDate(date.scheduledAt);

    if (date.isCompleted) {
      return "${date.title} • $formattedDate";
    }

    if (date.isRejected) {
      return date.title;
    }

    return "${date.title} • $formattedDate";
  }

  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return "$dd/$mm • $hh:$mi";
  }

  @override
  Widget build(BuildContext context) {
    final color = _bannerColor();
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _bannerIcon(),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurface.withOpacity(0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}