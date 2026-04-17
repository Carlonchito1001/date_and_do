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

    Widget buildSoftChip({
      required IconData icon,
      required String label,
      Color? color,
      bool dark = false,
    }) {
      if (label.trim().isEmpty) return const SizedBox.shrink();

      final chipColor = color ?? cs.primary;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withOpacity(0.14)
              : chipColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: dark
                ? Colors.white.withOpacity(0.24)
                : chipColor.withOpacity(0.18),
          ),
          boxShadow: dark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: dark ? Colors.white : chipColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: txt.bodySmall?.copyWith(
                  color: dark ? Colors.white : chipColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget fallbackAvatar() {
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
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: 390,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (avatar.isNotEmpty)
                    UserPhotoView(
                      fallbackUrl: avatar,
                      fit: BoxFit.cover,
                      errorWidget: fallbackAvatar(),
                    )
                  else
                    fallbackAvatar(),

                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.06),
                          Colors.black.withOpacity(0.18),
                          Colors.black.withOpacity(0.65),
                        ],
                        stops: const [0.0, 0.35, 1.0],
                      ),
                    ),
                  ),

                  Positioned(
                    top: 18,
                    left: 18,
                    right: 18,
                    child: Row(
                      children: [
                        Expanded(
                          child: buildSoftChip(
                            icon: Icons.location_on_rounded,
                            label: locationText(),
                            dark: true,
                          ),
                        ),
                        if (_lookingForLabel(lookingFor).isNotEmpty) ...[
                          const SizedBox(width: 8),
                          buildSoftChip(
                            icon: Icons.favorite_rounded,
                            label: _lookingForLabel(lookingFor),
                            color: Colors.pinkAccent,
                            dark: true,
                          ),
                        ],
                      ],
                    ),
                  ),

                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name${age.isNotEmpty ? ', $age' : ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: txt.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        if (job.isNotEmpty ||
                            _genderLabel(gender).isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (job.isNotEmpty)
                                buildSoftChip(
                                  icon: Icons.work_rounded,
                                  label: job,
                                  dark: true,
                                ),
                              if (_genderLabel(gender).isNotEmpty)
                                buildSoftChip(
                                  icon: Icons.person_rounded,
                                  label: _genderLabel(gender),
                                  dark: true,
                                ),
                            ],
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
                  if (mainText.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withOpacity(0.34),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.outlineVariant.withOpacity(0.22),
                        ),
                      ),
                      child: Text(
                        mainText,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: txt.bodyLarge?.copyWith(
                          height: 1.45,
                          color: cs.onSurface.withOpacity(0.88),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  if (interestList.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.interests_rounded,
                          size: 18,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Intereses',
                          style: txt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
