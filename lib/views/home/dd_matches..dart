import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:date_and_doing/views/home/dd_home.dart';
import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'dd_chat_page.dart';

class DdMatches extends StatefulWidget {
  const DdMatches({super.key});

  @override
  State<DdMatches> createState() => _DdMatchesState();
}

class _DdMatchesState extends State<DdMatches> {
  final _api = ApiService();
  final _sp = SharedPreferencesService();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> matches = [];

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
      final accessToken = await _sp.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('No hay access_token. Inicia sesión otra vez.');
      }

      final data = await _api.allMatches(accessToken: accessToken);

      if (!mounted) return;
      setState(() {
        matches = data;
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
    final v = m['other_user'];
    return (v is Map<String, dynamic>) ? v : null;
  }

  int _matchIdFrom(Map<String, dynamic> m) {
    final v = m['ddm_int_id'] ?? m['id'] ?? m['match_id'];
    if (v == null) throw Exception("No encuentro ddm_int_id en match");
    return v is int ? v : int.parse(v.toString());
  }

  int _otherUserIdFrom(Map<String, dynamic> m) {
    final ou = _otherUserFrom(m);
    final v = ou?['use_int_id'];
    if (v == null) return 0;
    return v is int ? v : int.parse(v.toString());
  }

  String _nameFrom(Map<String, dynamic> m) {
    final ou = _otherUserFrom(m);
    final v =
        ou?['fullname'] ??
        m['nombre'] ??
        m['use_txt_fullname'] ??
        m['full_name'] ??
        m['fullname'];
    return (v ?? 'Usuario').toString();
  }

  int _ageFrom(Map<String, dynamic> m) {
    final ou = _otherUserFrom(m);
    final v = ou?['age'] ?? m['edad'] ?? m['age'];
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String _photoFrom(Map<String, dynamic> m) {
    final ou = _otherUserFrom(m);
    final v =
        ou?['photo'] ??
        m['foto'] ??
        m['photo'] ??
        m['avatar'] ??
        m['use_txt_avatar'];

    final s = (v ?? '').toString();
    return s.isNotEmpty
        ? s
        : 'https://via.placeholder.com/600x900.png?text=DATE%20%26%20DOING';
  }

  String _statusKeyFrom(Map<String, dynamic> m) {
    final ou = _otherUserFrom(m);
    final v = ou?['online_status'] ?? m['status'] ?? m['online_status'];
    return (v ?? 'unknown').toString().toLowerCase();
  }

  Color _statusColor(String status) {
    if (status.contains("online")) return Colors.green;
    if (status.contains("unknown")) return Colors.grey;
    if (status.contains("offline")) return Colors.grey;
    return Colors.grey;
  }

  String _statusText(String status) {
    if (status.contains("online")) return "En línea";
    if (status.contains("unknown")) return "Desconectado";
    if (status.contains("offline")) return "Desconectado";
    return "Desconectado";
  }

  bool _isNewMatch(Map<String, dynamic> m) {
    final v = m['is_new_match'];
    return v == true || v?.toString() == "true";
  }

  String _newMatchLabel(Map<String, dynamic> m) {
    return (m['new_match_label'] ?? 'Nuevo match').toString();
  }

  void _openChatFromMatch(Map<String, dynamic> match) {
    final nombre = _nameFrom(match);
    final foto = _photoFrom(match);
    final matchId = _matchIdFrom(match);
    final otherUserId = _otherUserIdFrom(match);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DdChatPage(
          matchId: matchId,
          otherUserId: otherUserId,
          nombre: nombre,
          foto: foto,
        ),
      ),
    ).then((_) => _loadMatches());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Tus Matches'),
      //   centerTitle: true,
      //   actions: [
      //     IconButton(
      //       onPressed: _loading ? null : _loadMatches,
      //       icon: const Icon(Icons.refresh),
      //     ),
      //   ],
      // ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMatches,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Conexiones recientes",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Toca un match para iniciar el chat ✨",
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(child: _MatchesSkeleton())
              else if (_error != null)
                SliverFillRemaining(
                  child: _MatchesErrorState(
                    message: _error!,
                    onRetry: _loadMatches,
                  ),
                )
              else if (matches.isEmpty)
                SliverFillRemaining(
                  child: _EmptyMatchesState(onRefresh: _loadMatches),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid.builder(
                    itemCount: matches.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                    itemBuilder: (context, index) {
                      final item = matches[index];
                      final nombre = _nameFrom(item);
                      final edad = _ageFrom(item);
                      final foto = _photoFrom(item);
                      final status = _statusKeyFrom(item);
                      final isNew = _isNewMatch(item);
                      final newLabel = _newMatchLabel(item);

                      return AnimatedOpacity(
                        opacity: 1.0,
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        child: _MatchCard(
                          nombre: nombre,
                          edad: edad,
                          foto: foto,
                          statusText: isNew
                              ? "$newLabel 💖"
                              : _statusText(status),
                          statusColor: isNew
                              ? Colors.pinkAccent
                              : _statusColor(status),
                          onTap: () => _openChatFromMatch(item),
                        ),
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

// ================== EMPTY STATE ==================

class _EmptyMatchesState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyMatchesState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Aún no tienes matches!',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sigue deslizando para encontrar a alguien especial 💕',
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => onRefresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualizar'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DdHome()),
                );
              },
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Descubrir personas'),
              style: TextButton.styleFrom(foregroundColor: cs.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== SKELETON LOADER ==================

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

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, i) {
        return _ShimmerCard(
          animation: _animation,
          color: cs.surfaceContainerHighest,
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final Animation<double> animation;
  final Color color;

  const _ShimmerCard({required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.5), color],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(
                slidePercent: animation.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 5,
        shadowColor: Colors.black26,
        clipBehavior: Clip.antiAlias,
        child: Container(color: color),
      ),
    );
  }
}

// ================== ERROR STATE ==================

class _MatchesErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _MatchesErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: cs.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Ups! Algo salió mal',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== SHIMMER WIDGET ==================

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

// ================== MATCH CARD ==================

class _MatchCard extends StatelessWidget {
  final String nombre;
  final int edad;
  final String foto;
  final String statusText;
  final Color statusColor;
  final VoidCallback onTap;

  const _MatchCard({
    super.key,
    required this.nombre,
    required this.edad,
    required this.foto,
    required this.statusText,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 5,
        shadowColor: Colors.black26,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                foto,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.person_rounded,
                      size: 64,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    edad > 0 ? "$nombre, $edad" : nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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
