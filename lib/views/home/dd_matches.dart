import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:date_and_doing/views/home/matches/match_profile_page.dart';
import 'package:date_and_doing/widgets/user_photo_view.dart';

class DdMatchesPage extends StatefulWidget {
  const DdMatchesPage({super.key});

  @override
  State<DdMatchesPage> createState() => _DdMatchesPageState();
}

class _DdMatchesPageState extends State<DdMatchesPage> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await SharedPreferencesService().getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception("No hay token de acceso");
      }

      final data = await _api.allMatches(accessToken: token);

      if (!mounted) return;
      setState(() {
        _matches = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? _otherUserFrom(Map<String, dynamic> m) {
    final ou = m["other_user"];
    if (ou is Map<String, dynamic>) return ou;
    return null;
  }

  int _matchIdFrom(Map<String, dynamic> m) {
    final raw = m["ddm_int_id"] ?? m["id"] ?? m["match_id"];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? "") ?? 0;
  }

  String _nameFrom(Map<String, dynamic> m) {
    final ou = _otherUserFrom(m);
    final v =
        ou?['use_txt_fullname'] ??
        ou?['fullname'] ??
        m['nombre'] ??
        m['use_txt_fullname'] ??
        m['full_name'] ??
        m['fullname'];

    return (v ?? 'Usuario').toString();
  }

  int _ageFrom(Map<String, dynamic> m) {
    final ou = _otherUserFrom(m);
    final v = ou?['use_txt_age'] ?? ou?['age'] ?? m['edad'] ?? m['age'];

    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String? _photoBase64From(Map<String, dynamic> m) {
    final ou = _otherUserFrom(m);
    final v = ou?['photo_preview_base64'];
    final s = (v ?? '').toString();
    return s.isNotEmpty ? s : null;
  }

  String _photoFallbackFrom(Map<String, dynamic> m) {
    final ou = _otherUserFrom(m);
    final v =
        ou?['photo_fallback_url'] ??
        ou?['photo'] ??
        m['foto'] ??
        m['photo'] ??
        m['avatar'] ??
        m['use_txt_avatar'];

    return (v ?? '').toString();
  }

  String _statusKeyFrom(Map<String, dynamic> m) {
    final status = (m["ddm_txt_status"] ?? m["status"] ?? "ACTIVO")
        .toString()
        .toUpperCase();
    return status;
  }

  bool _isNewMatch(Map<String, dynamic> m) {
    final createdAt = (m["ddm_timestamp_datecreate"] ?? m["created_at"])
        ?.toString();
    if (createdAt == null || createdAt.isEmpty) return false;

    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return false;

    final diff = DateTime.now().difference(dt).inHours;
    return diff <= 24;
  }

  String _newMatchLabel(Map<String, dynamic> m) {
    return _isNewMatch(m) ? "Nuevo" : "Match";
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final matchId = _matchIdFrom(item);
    if (matchId == 0) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MatchProfilePage(matchId: matchId)),
    );

    if (!mounted) return;
    await _loadMatches();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const _MatchesSkeleton();
    }

    if (_error != null) {
      return _MatchesErrorState(message: _error!, onRetry: _loadMatches);
    }

    if (_matches.isEmpty) {
      return _EmptyMatchesState(onRefresh: _loadMatches);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.surface,
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF140A18)
                  : const Color(0xFFFFF8FB),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadMatches,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(0.36),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cs.primary.withOpacity(0.18),
                                cs.secondary.withOpacity(0.10),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.favorite_rounded,
                            color: cs.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tus matches",
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Toca un match para ver su perfil ✨",
                                style: textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "${_matches.length}",
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid.builder(
                  itemCount: _matches.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    final item = _matches[index];
                    final name = _nameFrom(item);
                    final age = _ageFrom(item);
                    final photoBase64 = _photoBase64From(item);
                    final photoFallback = _photoFallbackFrom(item);
                    final status = _statusKeyFrom(item);
                    final label = _newMatchLabel(item);
                    final isNew = _isNewMatch(item);

                    return _MatchCard(
                      name: name,
                      age: age,
                      photoBase64: photoBase64,
                      photoFallbackUrl: photoFallback,
                      status: status,
                      label: label,
                      isNew: isNew,
                      onTap: () => _open(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final String name;
  final int age;
  final String? photoBase64;
  final String photoFallbackUrl;
  final String status;
  final String label;
  final bool isNew;
  final VoidCallback onTap;

  const _MatchCard({
    required this.name,
    required this.age,
    required this.photoBase64,
    required this.photoFallbackUrl,
    required this.status,
    required this.label,
    required this.isNew,
    required this.onTap,
  });

  String _initials(String value) {
    final parts = value.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return "M";
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final badgeColor = isNew
        ? Colors.pinkAccent
        : status == "ACTIVO"
        ? Colors.green
        : Colors.grey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: UserPhotoView(
                        base64String: photoBase64,
                        fallbackUrl: photoFallbackUrl,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: Text(
                            _initials(name),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.04),
                            Colors.black.withOpacity(0.16),
                            Colors.black.withOpacity(0.48),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: badgeColor.withOpacity(0.24),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: status == "ACTIVO"
                              ? Colors.green
                              : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      age > 0 ? "$name, $age" : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          size: 14,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Ver perfil",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchesSkeleton extends StatefulWidget {
  const _MatchesSkeleton();

  @override
  State<_MatchesSkeleton> createState() => _MatchesSkeletonState();
}

class _MatchesSkeletonState extends State<_MatchesSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: _ShimmerContainer(
                animation: _animation,
                child: Container(
                  height: 82,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (_, __) {
                  return _ShimmerContainer(
                    animation: _animation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMatchesState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyMatchesState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.35),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_border_rounded,
                    size: 54,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Aún no tienes matches",
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Cuando hagas match con alguien aparecerá aquí.",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => onRefresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Actualizar"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchesErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _MatchesErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cs.errorContainer.withOpacity(0.24),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: cs.error.withOpacity(0.14)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withOpacity(0.42),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 52,
                    color: cs.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "No se pudieron cargar tus matches",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => onRetry(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Reintentar"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerContainer extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _ShimmerContainer({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.surfaceContainerHighest,
                cs.surfaceContainerHighest.withOpacity(0.5),
                cs.surfaceContainerHighest,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(
                slidePercent: animation.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
