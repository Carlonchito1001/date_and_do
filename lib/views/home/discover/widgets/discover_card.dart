import 'package:flutter/material.dart';

class DiscoverCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const DiscoverCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    final String name = (user['use_txt_fullname'] ?? '').toString();
    final String age = (user['use_txt_age'] ?? '').toString();
    final String description =
        (user['use_txt_description'] ?? 'Sin descripción').toString();

    final String? avatar = (user['use_txt_avatar'] ?? '').toString().isEmpty
        ? null
        : (user['use_txt_avatar'] ?? '').toString();

    final double distance = (user['distance_km'] as num?)?.toDouble() ?? 0.0;

    final String? country = user['use_txt_country']?.toString();
    final String? city = user['use_txt_city']?.toString();

    String locationText() {
      final dist = '${distance.toStringAsFixed(1)} km';
      if (city != null &&
          city!.isNotEmpty &&
          country != null &&
          country!.isNotEmpty) {
        return '$city, $country · $dist';
      }
      if (country != null && country!.isNotEmpty) {
        return '$country · $dist';
      }
      return dist;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 260,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                image: avatar != null
                    ? DecorationImage(
                        image: NetworkImage(avatar),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: avatar == null
                    ? LinearGradient(colors: [cs.primary, cs.secondary])
                    : null,
              ),
              child: avatar == null
                  ? Center(
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: txt.displayLarge?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name${age.isNotEmpty ? ', $age' : ''}',
                    style:
                        txt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        locationText(),
                        style: txt.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: txt.bodyMedium?.copyWith(
                      height: 1.4,
                      color: cs.onSurface.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
