import 'package:flutter/material.dart';
import 'package:date_and_doing/widgets/user_photo_view.dart';
import 'interest_chip.dart';

class DiscoverCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const DiscoverCard({super.key, required this.user});

  String _safeString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty || text.toLowerCase() == 'null' ? fallback : text;
  }

  String _lookingForLabel(String value) {
    switch (value.toLowerCase()) {
      case 'relacion':
        return 'Relación seria';
      case 'casual':
        return 'Algo casual';
      case 'amistad':
        return 'Amistad';
      case 'noc':
        return 'Aún no lo sabe';
      default:
        return value.isEmpty ? '' : value;
    }
  }

  String _genderLabel(String value) {
    switch (value.toLowerCase()) {
      case 'mujer':
        return 'Mujer';
      case 'hombre':
        return 'Hombre';
      case 'otro':
        return 'Otro';
      default:
        return value.isEmpty ? '' : value;
    }
  }

  List<String> _parseInterests(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split(RegExp(r'[,|/]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(6)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    final String name = _safeString(
      user['use_txt_fullname'],
      fallback: 'Sin nombre',
    );
    final String age = _safeString(user['use_txt_age']);
    final String avatar = _safeString(user['use_txt_avatar']);
    final String city = _safeString(user['use_txt_city']);
    final String country = _safeString(user['use_txt_country']);
    final String description = _safeString(user['use_txt_description']);
    final String bio = _safeString(user['ddp_txt_bio']);
    final String job = _safeString(user['ddp_txt_job']);
    final String lookingFor = _safeString(user['ddp_txt_looking_for']);
    final String gender = _safeString(user['ddp_txt_gender']);
    final String interests = _safeString(user['use_txt_interests']);

    final List<String> interestList = _parseInterests(interests);

    final double distance = (user['distance_km'] as num?)?.toDouble() ?? 0.0;

    final String mainText = bio.isNotEmpty
        ? bio
        : description.isNotEmpty
        ? description
        : 'Perfil en crecimiento ✨';

    String locationText() {
      final dist = '${distance.toStringAsFixed(1)} km';
      if (city.isNotEmpty && country.isNotEmpty) {
        return '$city, $country · $dist';
      }
      if (city.isNotEmpty) {
        return '$city · $dist';
      }
      if (country.isNotEmpty) {
        return '$country · $dist';
      }
      return dist;
    }

    Widget buildChip({
      required IconData icon,
      required String label,
      Color? color,
    }) {
      if (label.trim().isEmpty) return const SizedBox.shrink();

      final chipColor = color ?? cs.primary;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: chipColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: chipColor.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: chipColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: txt.bodySmall?.copyWith(
                  color: chipColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _fallbackAvatar() {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: txt.displayLarge?.copyWith(
            color: cs.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: 360,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (avatar.isNotEmpty)
                    UserPhotoView(
                      fallbackUrl: avatar,
                      fit: BoxFit.cover,
                      errorWidget: _fallbackAvatar(),
                    )
                  else
                    _fallbackAvatar(),

                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x14000000),
                          Color(0x33000000),
                          Color(0x99000000),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: 16,
                    left: 16,
                    child: buildChip(
                      icon: Icons.location_on_rounded,
                      label: locationText(),
                      color: Colors.white,
                    ),
                  ),

                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name${age.isNotEmpty ? ', $age' : ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: txt.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        if (job.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            job,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: txt.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.92),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_lookingForLabel(lookingFor).isNotEmpty)
                        buildChip(
                          icon: Icons.favorite_rounded,
                          label: _lookingForLabel(lookingFor),
                          color: Colors.pinkAccent,
                        ),
                      if (_genderLabel(gender).isNotEmpty)
                        buildChip(
                          icon: Icons.person_rounded,
                          label: _genderLabel(gender),
                          color: cs.secondary,
                        ),
                      if (job.isNotEmpty)
                        buildChip(
                          icon: Icons.work_rounded,
                          label: job,
                          color: cs.primary,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    mainText,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: txt.bodyLarge?.copyWith(
                      height: 1.45,
                      color: cs.onSurface.withOpacity(0.86),
                    ),
                  ),

                  if (interestList.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Intereses',
                      style: txt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: interestList
                          .map((e) => InterestChip(label: e))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
