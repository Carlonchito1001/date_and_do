import 'package:flutter/material.dart';

/// Modelo de datos para un lugar/establecimiento
class PlaceItem {
  final String id;
  final String username;
  final String fullName;
  final String biography;
  final String url;
  final String profilePicUrl;

  PlaceItem({
    required this.id,
    required this.username,
    required this.fullName,
    required this.biography,
    required this.url,
    required this.profilePicUrl,
  });

  factory PlaceItem.fromMap(Map<String, dynamic> m) {
    return PlaceItem(
      id: (m["id"] ?? "").toString(),
      username: (m["username"] ?? "").toString(),
      fullName: (m["full_name"] ?? "").toString(),
      biography: (m["biography"] ?? "").toString(),
      url: (m["url"] ?? "").toString(),
      profilePicUrl: (m["profile_pic_url_hd"] ?? m["profile_pic_url"] ?? "").toString(),
    );
  }

  /// Nombre para mostrar (full_name o @username)
  String get displayName => fullName.trim().isNotEmpty ? fullName.trim() : "@${username.trim()}";

  /// Texto formateado para la descripción de la cita
  String get formattedDescription {
    final parts = <String>[];
    if (fullName.isNotEmpty) parts.add("📍 $fullName");
    if (biography.isNotEmpty) parts.add("📝 $biography");
    if (url.isNotEmpty) parts.add("🔗 $url");
    return parts.join("\n").trim();
  }

  /// Preview corto para la card de cita
  String get shortPreview {
    final bio = biography.trim();
    if (bio.isEmpty) return displayName;
    if (bio.length > 50) return "${bio.substring(0, 50)}...";
    return bio;
  }
}

/// Componente reutilizable para mostrar un item de lugar
class PlaceListItem extends StatelessWidget {
  final PlaceItem place;
  final bool isSelected;
  final VoidCallback onTap;

  const PlaceListItem({
    super.key,
    required this.place,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? cs.primary.withOpacity(0.08) : cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? cs.primary : cs.outline.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? cs.primary.withOpacity(0.15) 
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                _PlaceAvatar(
                  imageUrl: place.profilePicUrl,
                  isSelected: isSelected,
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "@${place.username}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Full name
                      Text(
                        place.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Biography
                      Text(
                        place.biography.isEmpty 
                            ? "Sin descripción disponible" 
                            : place.biography,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.7),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected ? cs.primary : cs.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? cs.primary : cs.outline.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar circular para el lugar
class _PlaceAvatar extends StatelessWidget {
  final String imageUrl;
  final bool isSelected;

  const _PlaceAvatar({
    required this.imageUrl,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? cs.primary : cs.outline.withOpacity(0.2),
          width: isSelected ? 3 : 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: imageUrl.isEmpty
            ? Container(
                color: cs.surfaceVariant,
                child: Icon(
                  Icons.store_rounded,
                  color: cs.onSurface.withOpacity(0.4),
                  size: 28,
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.surfaceVariant,
                  child: Icon(
                    Icons.store_rounded,
                    color: cs.onSurface.withOpacity(0.4),
                    size: 28,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Preview del lugar seleccionado (para mostrar en el formulario)
class SelectedPlacePreview extends StatelessWidget {
  final PlaceItem place;
  final VoidCallback? onRemove;

  const SelectedPlacePreview({
    super.key,
    required this.place,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withOpacity(0.1),
            cs.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: cs.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Lugar seleccionado",
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                  color: cs.error,
                  tooltip: "Cambiar lugar",
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (place.biography.isNotEmpty) ...[
                  Text(
                    place.biography,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withOpacity(0.8),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                if (place.url.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 14,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          place.url,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.primary,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}