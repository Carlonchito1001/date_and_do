import 'package:flutter/material.dart';

class ModalAliniUnlocked extends StatelessWidget {
  final String? partnerName;

  const ModalAliniUnlocked({
    super.key,
    this.partnerName,
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

      // ==== HEADER ====
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Iconito circular con gradiente (estilo feature premium)
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF00E6B8), // teal
                      Color(0xFF4AE0FF), // celeste
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.videocam_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Alini Video Call está listo! ✨',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Chip con marca DATE ❤️ DOING
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.pinkAccent.withOpacity(0.45),
              ),
              color: Colors.pink.withOpacity(0.10),
            ),
            child: const Text(
              'DATE ❤️ DOING • Conexión segura',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),

      // ==== CONTENIDO ====
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            partnerName != null
                ? 'Tu conexión con ${partnerName!} va en buen camino 🫶'
                : 'Su conexión va en buen camino 🫶',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.tealAccent[100],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ya cumpliste los días mínimos de chat dentro de DATE ❤️ DOING.\n\n'
            'Ahora pueden dar el siguiente paso y tener una videollamada segura, '
            'sin compartir números ni redes personales antes de tiempo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // Mini card de “tip” / tranquilidad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.tealAccent.withOpacity(0.35),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00E6B8).withOpacity(0.10),
                  const Color(0xFF4AE0FF).withOpacity(0.12),
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_moon_outlined,
                  size: 18,
                  color: Color(0xFF00E6B8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tu videollamada se mantiene dentro de DATE ❤️ DOING. '
                    'Sin compartir datos personales si aún no se sienten listos.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.tealAccent[100],
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ==== BOTONES ====
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
          ),
          child: const Text('Seguir chateando'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00E6B8),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: const Text('Probar Alini'),
        ),
      ],
    );
  }
}
