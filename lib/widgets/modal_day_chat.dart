import 'package:flutter/material.dart';

class ModalDayChat extends StatelessWidget {
  final int chatDay;

  const ModalDayChat({
    super.key,
    required this.chatDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: const Color(0xFF101018), // fondo oscuro elegante
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF6FB5), // rosa
                  Color(0xFFFF9F9A), // salmón
                ],
              ),
            ),
            child: const Center(
              child: Text(
                "❤️",
                style: TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mensaje de DATE ❤️ DOING',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Tu conexión va en serio 🥹',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.pink[100],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aún no puedes usar Alini Video Call.\n\n'
            'Solo te quedan $chatDay días de chat dentro de DATE ❤️ DOING. '
            'Aprovecha este tiempo para conocer mejor a la otra persona antes de dar el siguiente paso 😉',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.pinkAccent.withOpacity(0.4),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.pink.withOpacity(0.12),
                  Colors.purple.withOpacity(0.16),
                ],
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_outline,
                  size: 18,
                  color: Colors.pinkAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Consejo: una buena conversación vale más que mil videollamadas ✨',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.pink[100],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
          ),
          child: const Text('Seguir chateando'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}
