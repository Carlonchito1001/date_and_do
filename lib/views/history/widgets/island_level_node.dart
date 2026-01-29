import 'package:flutter/material.dart';
import '../models/world_level.dart';

class IslandLevelNode extends StatelessWidget {
  final WorldLevel level;
  final TextTheme textTheme;
  final VoidCallback? onTap;

  const IslandLevelNode({
    super.key,
    required this.level,
    required this.textTheme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color baseColor;
    Widget badge;

    switch (level.status) {
      case WorldLevelStatus.done:
        baseColor = Colors.greenAccent.shade400;
        badge = const Icon(Icons.check, size: 16, color: Colors.white);
        break;
      case WorldLevelStatus.current:
        baseColor = Colors.orangeAccent.shade400;
        badge = const Icon(
          Icons.play_arrow_rounded,
          size: 18,
          color: Colors.white,
        );
        break;
      case WorldLevelStatus.locked:
        baseColor = Colors.blueGrey.shade400;
        badge = const Icon(Icons.lock_rounded, size: 16, color: Colors.white);
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Isla + nivel
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 🌴 ISLA (arena)
              Positioned(
                bottom: -20,
                child: Container(
                  width: 120,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE0B2), Color(0xFFFFB74D)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // Franja de pasto en la isla
              Positioned(
                bottom: -10,
                child: Container(
                  width: 110,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              // 🌟 CÍRCULO DEL NIVEL
              if (level.status == WorldLevelStatus.current)
                // anillo alrededor del nivel actual
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 3,
                    ),
                  ),
                ),
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [baseColor.withOpacity(0.9), baseColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withOpacity(0.6),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(level.icon, color: Colors.white, size: 36),
              ),

              // Badge (check / play / lock)
              Positioned(
                right: 0,
                top: 4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: badge),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Tarjetita blanca con texto
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  level.title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  level.date,
                  style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
