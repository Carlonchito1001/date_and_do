import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';

import 'widgets/discover_card.dart';
import 'widgets/discover_actions.dart';

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
      currentIndex = 0;
      users = [];
    });

    final token = await SharedPreferencesService().getAccessToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => loading = false);
      return;
    }

    try {
      final result = await ApiService().sugerenciasMatch(accessToken: token);
      if (!mounted) return;

      setState(() {
        users = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando sugerencias: $e')));
    }
  }

  int? _currentTargetUserId() {
    if (users.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= users.length) return null;

    final current = users[currentIndex];
    final raw = current['use_int_id'];

    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  Future<void> _sendSwipeToBackend(String type) async {
    if (sendingSwipe) return;

    final token = await SharedPreferencesService().getAccessToken();
    if (token == null) return;

    final targetUserId = _currentTargetUserId();
    if (targetUserId == null) return;

    setState(() => sendingSwipe = true);

    try {
      await ApiService().likes(
        accessToken: token,
        targetUserId: targetUserId,
        type: type,
      );

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
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
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
    final opacity = 0.88 + (0.12 * dragStrength);

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: DiscoverCard(user: next),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (users.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No hay sugerencias disponibles'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadSuggestions,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Stack(
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
                          angle: -0.25,
                          alignment: Alignment.topLeft,
                        ),
                        _swipeLabel(
                          text: "NOPE",
                          color: Colors.redAccent,
                          opacity: _nopeOpacity(context),
                          angle: 0.25,
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
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: DiscoverActions(
                  disabled: sendingSwipe,
                  onDislike: _onDislike,
                  onLike: _onLike,
                  onSuperLike: _onSuperLike,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
