import 'package:flutter/material.dart';

class AppColors {
  // Colores base (branding)
  static const Color primary = Color(0xFFEF5DA8); // Rosa principal
  static const Color primaryDark = Color(0xFFD1438A);
  static const Color secondary = Color(0xFF7C3AED); // Morado bonito
  static const Color accent = Color(
    0xFFFFB86C,
  ); // Toque cálido (botones, badges)

  // Fondos
  static const Color lightBackground = Color(0xFFFDF2F8); // muy claro rosado
  static const Color lightSurface = Color(0xFFFFFFFF);

  static const Color darkBackground = Color(0xFF1E1F2A);
  static const Color darkSurface = Color(0xFF2A2C39);

  // Texto
  static const Color textDark = Color(0xFF111827); // gris casi negro
  static const Color textLight = Color(0xFFF9FAFB);

  static const Color textMutedDark = Color(0xFF6B7280);
  static const Color textMutedLight = Color(0xFF9CA3AF);

  // Estados
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Bordes / divisores
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF1F2937);

  // Sombras suaves (no son const para usar con opacidad)
  static Color shadowSoft = Colors.black.withOpacity(0.08);
}
