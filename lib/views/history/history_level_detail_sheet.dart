import 'package:flutter/material.dart';
import 'models/world_level.dart';

Future<void> showHistoryLevelDetailSheet(
  BuildContext context, {
  required WorldLevel level,
}) async {
  final cs = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  await showModalBottomSheet(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor(level.status).withOpacity(0.14),
              ),
              child: Icon(
                level.icon,
                size: 34,
                color: _statusColor(level.status),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              level.title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              level.subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    level.date,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _statusColor(level.status).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _statusColor(level.status).withOpacity(0.20),
                ),
              ),
              child: Text(
                _statusText(level.status),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: _statusColor(level.status),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 18),
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
        ),
      );
    },
  );
}

Color _statusColor(WorldLevelStatus status) {
  switch (status) {
    case WorldLevelStatus.done:
      return Colors.green;
    case WorldLevelStatus.current:
      return Colors.orange;
    case WorldLevelStatus.locked:
      return Colors.blueGrey;
  }
}

String _statusText(WorldLevelStatus status) {
  switch (status) {
    case WorldLevelStatus.done:
      return "Nivel completado";
    case WorldLevelStatus.current:
      return "Nivel actual";
    case WorldLevelStatus.locked:
      return "Nivel bloqueado";
  }
}