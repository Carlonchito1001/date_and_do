import 'package:flutter/material.dart';

class ModalAliniUnlocked extends StatefulWidget {
  final String? partnerName;

  const ModalAliniUnlocked({super.key, this.partnerName});

  @override
  State<ModalAliniUnlocked> createState() => _ModalAliniUnlockedState();
}

class _ModalAliniUnlockedState extends State<ModalAliniUnlocked> {
  bool dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partner = (widget.partnerName?.trim().isNotEmpty ?? false)
        ? widget.partnerName!.trim()
        : 'esta persona especial';

    return AlertDialog(
      backgroundColor: const Color(0xFF10131A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
      contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00E6B8), Color(0xFF00C2FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E6B8).withOpacity(0.28),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.video_call_rounded,
              color: Colors.black,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '¡Alini Video Call está listo! ✨',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFF00E6B8).withOpacity(0.12),
              border: Border.all(
                color: const Color(0xFF00E6B8).withOpacity(0.25),
              ),
            ),
            child: const Text(
              'Conexión desbloqueada',
              style: TextStyle(
                color: Color(0xFF7EFBE0),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.55,
                  fontSize: 14.5,
                ),
                children: [
                  const TextSpan(text: 'Tu conexión con '),
                  TextSpan(
                    text: partner,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' va en buen camino. Ya tienen acceso a una videollamada segura dentro de ',
                  ),
                  const TextSpan(
                    text: 'DATE ❤️ DOING',
                    style: TextStyle(
                      color: Color(0xFF00E6B8),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.04),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.shield_rounded,
                    color: Color(0xFF00E6B8),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'La videollamada se realiza dentro de la app para mantener una experiencia más privada, cómoda y segura.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.04),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: CheckboxListTile(
                value: dontShowAgain,
                onChanged: (value) {
                  setState(() {
                    dontShowAgain = value ?? false;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF00E6B8),
                checkColor: Colors.black,
                title: const Text(
                  'No volver a mostrar este aviso',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(dontShowAgain ? 'hide_forever' : 'dismiss'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withOpacity(0.14)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Seguir chateando'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(dontShowAgain ? 'hide_forever_try' : 'try_now'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00E6B8),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Probar Alini',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
