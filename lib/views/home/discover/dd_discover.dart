import 'package:date_and_doing/views/profile_user/match_preferences_page.dart';
import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';

import 'widgets/discover_card.dart';
import 'widgets/discover_actions.dart';
import 'widgets/new_match_screen.dart';

class DdDiscover extends StatefulWidget {
  const DdDiscover({super.key});

  @override
  State<DdDiscover> createState() => _DdDiscoverState();
}

class _DdDiscoverState extends State<DdDiscover>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> users = [];
  int currentIndex = 0;
  bool loading = true;
  bool sendingSwipe = false;
  String? error;

  late final AnimationController _controller;
  Animation<Offset>? _posAnim;
  Animation<double>? _rotAnim;

  Offset _dragOffset = Offset.zero;
  double _dragRotation = 0;
  bool _isDragging = false;

  static const double _maxRotation = 0.22;
  static const double _swipeThreshold = 120;

  String? _lastAction;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 240),
          )
          ..addListener(() {
            if (_posAnim != null) {
              setState(() {
                _dragOffset = _posAnim!.value;
                _dragRotation = _rotAnim?.value ?? 0;
              });
            }
          })
          ..addStatusListener((status) async {
            if (status == AnimationStatus.completed) {
              final action = _lastAction;
              if (action != null) {
                await _sendSwipeToBackend(action);
              }
              _resetCardPosition();
            }
          });

    _loadSuggestions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      loading = true;
      error = null;
      currentIndex = 0;
      users = [];
    });

    final service = SharedPreferencesService();
    final token = await service.getAccessToken();

    if (token == null) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'No hay sesión activa. Inicia sesión nuevamente.';
      });
      return;
    }

    try {
      final maxDistance = await service.getMaxDistance();

      final result = await ApiService().sugerenciasMatch(
        accessToken: token,
        maxDistanceKm: maxDistance,
      );

      if (!mounted) return;

      setState(() {
        users = result;
        loading = false;
      });
    } catch (e) {
      debugPrint("DISCOVER ERROR => $e");
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Error al cargar sugerencias. Intenta nuevamente.';
      });
    }
  }

  Future<void> _showNewMatchScreen(Map<String, dynamic> match) async {
    final other = match["other_user"] as Map<String, dynamic>?;
    if (other == null) return;

    final name = (other["fullname"] ?? "Nuevo match").toString();

    final photo = (other["photo_fallback_url"] ?? other["photo"] ?? "")
        .toString();

    final matchIdRaw = match["ddm_int_id"] ?? match["id"] ?? match["match_id"];
    final otherUserIdRaw = other["use_int_id"] ?? 0;

    final int? matchId = _asInt(matchIdRaw);
    final int? otherUserId = _asInt(otherUserIdRaw);

    if (matchId == null || otherUserId == null) {
      debugPrint(
        "MATCH DATA INVALID => matchId=$matchIdRaw otherUserId=$otherUserIdRaw",
      );
      return;
    }

    final userInfo = await SharedPreferencesService().getUserInfo();
    final currentUserPhoto = userInfo?['use_txt_avatar']?.toString();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => NewMatchScreen(
          matchedUserName: name,
          matchedUserPhoto: photo,
          matchId: matchId,
          otherUserId: otherUserId,
          currentUserPhoto: currentUserPhoto,
        ),
      ),
    );
  }

  int? _asInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  int? _currentTargetUserId() {
    if (users.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= users.length) return null;

    final current = users[currentIndex];
    final raw = current['use_int_id'];

    return _asInt(raw);
  }

  Future<void> _sendSwipeToBackend(String type) async {
    if (sendingSwipe) return;

    final token = await SharedPreferencesService().getAccessToken();
    if (token == null) return;

    final targetUserId = _currentTargetUserId();
    if (targetUserId == null) return;

    setState(() => sendingSwipe = true);

    try {
      final res = await ApiService().likes(
        accessToken: token,
        targetUserId: targetUserId,
        type: type,
      );

      if (!mounted) return;

      final match = res["match"];
      if (match != null && match is Map<String, dynamic>) {
        await _showNewMatchScreen(match);
      }

      if (!mounted) return;

      if (currentIndex < users.length - 1) {
        setState(() => currentIndex++);
      } else {
        await _loadSuggestions();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error enviando swipe: $e')));
    } finally {
      if (!mounted) return;
      setState(() => sendingSwipe = false);
    }
  }

  void _resetCardPosition() {
    if (!mounted) return;
    setState(() {
      _dragOffset = Offset.zero;
      _dragRotation = 0;
      _posAnim = null;
      _rotAnim = null;
      _lastAction = null;
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (sendingSwipe) return;
    _isDragging = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || sendingSwipe) return;

    setState(() {
      _dragOffset += details.delta;

      final w = MediaQuery.of(context).size.width;
      final x = (_dragOffset.dx / (w / 2)).clamp(-1.0, 1.0);
      _dragRotation = x * _maxRotation;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging || sendingSwipe) return;
    _isDragging = false;

    if (_dragOffset.dx > _swipeThreshold) {
      _animateOut("LIKE");
      return;
    }
    if (_dragOffset.dx < -_swipeThreshold) {
      _animateOut("DISLIKE");
      return;
    }
    if (_dragOffset.dy < -_swipeThreshold) {
      _animateOut("SUPERLIKE");
      return;
    }

    _animateBackToCenter();
  }

  void _animateBackToCenter() {
    _controller.stop();
    _controller.reset();

    _posAnim = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _rotAnim = Tween<double>(
      begin: _dragRotation,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _lastAction = null;
    _controller.forward();
  }

  void _animateOut(String action) {
    if (sendingSwipe) return;
    if (users.isEmpty) return;

    _controller.stop();
    _controller.reset();

    final size = MediaQuery.of(context).size;

    final dx = action == "DISLIKE" ? -(size.width * 1.2) : (size.width * 1.2);

    final Offset end = action == "SUPERLIKE"
        ? Offset(_dragOffset.dx, -(size.height * 1.1))
        : Offset(dx, _dragOffset.dy);

    final double endRot = action == "DISLIKE" ? -_maxRotation : _maxRotation;

    _posAnim = Tween<Offset>(
      begin: _dragOffset,
      end: end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _rotAnim = Tween<double>(
      begin: _dragRotation,
      end: endRot,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _lastAction = action;

    _controller.forward();
  }

  void _onLike() => _animateOut("LIKE");
  void _onDislike() => _animateOut("DISLIKE");
  void _onSuperLike() => _animateOut("SUPERLIKE");

  double _likeOpacity(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return (_dragOffset.dx / (w * 0.25)).clamp(0.0, 1.0);
  }

  double _nopeOpacity(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return (-_dragOffset.dx / (w * 0.25)).clamp(0.0, 1.0);
  }

  double _superLikeOpacity(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return (-_dragOffset.dy / (h * 0.25)).clamp(0.0, 1.0);
  }

  Widget _swipeLabel({
    required String text,
    required Color color,
    required double opacity,
    double angle = 0,
    Alignment alignment = Alignment.topLeft,
  }) {
    if (opacity <= 0) return const SizedBox.shrink();

    return Align(
      alignment: alignment,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            margin: const EdgeInsets.all(22),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              border: Border.all(color: color, width: 3.2),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasNext => (currentIndex + 1) < users.length;

  Map<String, dynamic>? get _nextUser {
    if (!_hasNext) return null;
    return users[currentIndex + 1];
  }

  Widget _buildNextPreviewCard() {
    final next = _nextUser;
    if (next == null) return const SizedBox.shrink();

    final dragStrength = (_dragOffset.distance / 220).clamp(0.0, 1.0);
    final scale = 0.94 + (0.04 * dragStrength);
    final opacity = 0.78 + (0.22 * dragStrength);

    return Transform.translate(
      offset: const Offset(0, 14),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: DiscoverCard(user: next),
        ),
      ),
    );
  }

  Widget _buildTopHeader(ColorScheme cs) {
    final total = users.length;
    final current = total == 0 ? 0 : (currentIndex + 1).clamp(0, total);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cs.primary.withOpacity(0.18),
                              cs.secondary.withOpacity(0.10),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          color: cs.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Descubre conexiones',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              total > 0
                                  ? 'Perfil $current de $total'
                                  : 'Buscando personas cercanas',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: cs.surfaceContainerHighest.withOpacity(0.45),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MatchPreferencesPage()),
                    );
                  },
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.28),
                      ),
                    ),
                    child: Icon(Icons.tune_rounded, color: cs.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : current / total,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest.withOpacity(0.6),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (loading) {
      return const _DiscoverSkeleton();
    }

    if (error != null) {
      return _DiscoverErrorState(message: error!, onRetry: _loadSuggestions);
    }

    if (users.isEmpty) {
      return _EmptyDiscoverState(onRefresh: _loadSuggestions);
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
                  ? const Color(0xFF150A18)
                  : const Color(0xFFFFF8FB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(cs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          _buildNextPreviewCard(),
                          Transform.translate(
                            offset: _dragOffset,
                            child: Transform.rotate(
                              angle: _dragRotation,
                              child: DiscoverCard(user: users[currentIndex]),
                            ),
                          ),
                          _swipeLabel(
                            text: "LIKE",
                            color: Colors.green,
                            opacity: _likeOpacity(context),
                            angle: -0.22,
                            alignment: Alignment.topLeft,
                          ),
                          _swipeLabel(
                            text: "NOPE",
                            color: Colors.redAccent,
                            opacity: _nopeOpacity(context),
                            angle: 0.22,
                            alignment: Alignment.topRight,
                          ),
                          _swipeLabel(
                            text: "SUPER\nLIKE",
                            color: Colors.blueAccent,
                            opacity: _superLikeOpacity(context),
                            alignment: Alignment.topCenter,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.36),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: DiscoverActions(
                  disabled: sendingSwipe,
                  onDislike: _onDislike,
                  onLike: _onLike,
                  onSuperLike: _onSuperLike,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverSkeleton extends StatefulWidget {
  const _DiscoverSkeleton();

  @override
  State<_DiscoverSkeleton> createState() => _DiscoverSkeletonState();
}

class _DiscoverSkeletonState extends State<_DiscoverSkeleton>
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
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ShimmerContainer(
                          animation: _animation,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _ShimmerContainer(
                        animation: _animation,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ShimmerContainer(
                    animation: _animation,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: cs.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ShimmerContainer(
                        animation: _animation,
                        child: Container(
                          height: 340,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                            color: cs.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ShimmerContainer(
                              animation: _animation,
                              child: Container(
                                width: 180,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ShimmerContainer(
                              animation: _animation,
                              child: Container(
                                width: 140,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _ShimmerContainer(
                              animation: _animation,
                              child: Container(
                                width: double.infinity,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.36),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
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

class _EmptyDiscoverState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyDiscoverState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.35),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      size: 56,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No hay más personas cerca',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ajusta tus preferencias o vuelve más tarde para descubrir nuevas personas.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  FilledButton.icon(
                    onPressed: () => onRefresh(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Buscar más'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MatchPreferencesPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Ajustar preferencias'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
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
      ),
    );
  }
}

class _DiscoverErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DiscoverErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
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
                    'Ups, algo salió mal',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  FilledButton.icon(
                    onPressed: () => onRetry(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
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
