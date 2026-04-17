import 'package:flutter/material.dart';

class DiscoverActions extends StatelessWidget {
  final VoidCallback onDislike;
  final VoidCallback onLike;
  final VoidCallback onSuperLike;
  final bool disabled;

  const DiscoverActions({
    super.key,
    required this.onDislike,
    required this.onLike,
    required this.onSuperLike,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget actionButton({
      required IconData icon,
      required VoidCallback onTap,
      required Color color,
      required double size,
      required double iconSize,
      bool filled = false,
      String? label,
    }) {
      final bgColor = disabled
          ? cs.surfaceContainerHighest.withOpacity(0.45)
          : filled
          ? color
          : cs.surface;

      final borderColor = disabled
          ? cs.outlineVariant.withOpacity(0.20)
          : filled
          ? color.withOpacity(0.0)
          : color.withOpacity(0.18);

      final iconColor = disabled
          ? cs.onSurface.withOpacity(0.30)
          : filled
          ? Colors.white
          : color;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: disabled ? null : onTap,
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(
                    color: borderColor,
                    width: filled ? 0 : 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: disabled
                          ? Colors.black.withOpacity(0.02)
                          : color.withOpacity(filled ? 0.25 : 0.12),
                      blurRadius: filled ? 20 : 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, size: iconSize, color: iconColor),
                ),
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: disabled
                    ? cs.onSurface.withOpacity(0.35)
                    : cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        actionButton(
          icon: Icons.close_rounded,
          onTap: onDislike,
          color: Colors.redAccent,
          size: 62,
          iconSize: 30,
          label: "Nope",
        ),
        const SizedBox(width: 18),
        actionButton(
          icon: Icons.star_rounded,
          onTap: onSuperLike,
          color: Colors.blueAccent,
          size: 72,
          iconSize: 34,
          filled: true,
          label: "Super",
        ),
        const SizedBox(width: 18),
        actionButton(
          icon: Icons.favorite_rounded,
          onTap: onLike,
          color: Colors.green,
          size: 62,
          iconSize: 30,
          label: "Like",
        ),
      ],
    );
  }
}
