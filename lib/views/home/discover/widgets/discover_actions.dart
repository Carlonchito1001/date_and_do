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

    Widget btn({
      required IconData icon,
      required VoidCallback onTap,
      required Color color,
    }) {
      return InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: 30,
              color: disabled ? cs.onSurface.withOpacity(0.35) : color,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        btn(icon: Icons.close, onTap: onDislike, color: Colors.redAccent),
        const SizedBox(width: 18),
        btn(icon: Icons.star, onTap: onSuperLike, color: Colors.blueAccent),
        const SizedBox(width: 18),
        btn(icon: Icons.favorite, onTap: onLike, color: Colors.green),
      ],
    );
  }
}
