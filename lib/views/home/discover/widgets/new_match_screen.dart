import 'dart:math';
import 'package:flutter/material.dart';
import 'package:date_and_doing/widgets/user_photo_view.dart';
import '../../dd_chat_page.dart';

class NewMatchScreen extends StatefulWidget {
  final String matchedUserName;
  final String matchedUserPhoto;
  final int matchId;
  final int otherUserId;
  final String? currentUserPhoto;

  const NewMatchScreen({
    super.key,
    required this.matchedUserName,
    required this.matchedUserPhoto,
    required this.matchId,
    required this.otherUserId,
    this.currentUserPhoto,
  });

  @override
  State<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends State<NewMatchScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1700),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _goToChat(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DdChatPage(
          matchId: widget.matchId,
          otherUserId: widget.otherUserId,
          nombre: widget.matchedUserName,
          foto: widget.matchedUserPhoto,
        ),
      ),
    );
  }

  void _keepSwiping(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.25),
                    radius: 0.95 + (_pulseAnimation.value - 1.0) * 0.35,
                    colors: [
                      cs.primary.withOpacity(0.28),
                      Colors.pink.withOpacity(0.18),
                      const Color(0xFF120A14),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.28, 0.72, 1.0],
                  ),
                ),
              );
            },
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.03),
                      Colors.transparent,
                      Colors.black.withOpacity(0.10),
                    ],
                  ),
                ),
              ),
            ),
          ),

          ...List.generate(
            24,
            (index) => _ConfettiParticle(
              delay: index * 0.08,
              color: [
                cs.primary,
                Colors.pinkAccent,
                Colors.amberAccent,
                cs.secondary,
              ][index % 4],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Material(
                      color: Colors.white.withOpacity(0.10),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _keepSwiping(context),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.pink.shade100,
                                  Colors.white,
                                ],
                              ).createShader(bounds);
                            },
                            child: const Text(
                              '¡Es un Match!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.2,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'A ti y a ${widget.matchedUserName} les gustaron mutuamente.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.82),
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 44),

                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return SizedBox(
                          width: 280,
                          height: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.translate(
                                offset: const Offset(-58, 10),
                                child: Transform.rotate(
                                  angle: -0.22,
                                  child: _UserAvatar(
                                    photoUrl: widget.currentUserPhoto,
                                    size: 118,
                                    borderColor: cs.primary,
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(58, 10),
                                child: Transform.rotate(
                                  angle: 0.22,
                                  child: _UserAvatar(
                                    photoUrl: widget.matchedUserPhoto,
                                    size: 118,
                                    borderColor: Colors.pinkAccent,
                                  ),
                                ),
                              ),
                              Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 82,
                                  height: 82,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF4D8D),
                                        Color(0xFFFF7BAC),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.pink.withOpacity(0.40),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.22),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.white,
                                    size: 38,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 26),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: Text(
                        widget.matchedUserName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: FilledButton.icon(
                              onPressed: () => _goToChat(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.chat_bubble_rounded),
                              label: const Text(
                                'Enviar mensaje',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: OutlinedButton.icon(
                              onPressed: () => _keepSwiping(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.22),
                                  width: 1.5,
                                ),
                                backgroundColor: Colors.white.withOpacity(0.04),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.swipe_rounded),
                              label: const Text(
                                'Seguir descubriendo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;
  final Color borderColor;

  const _UserAvatar({
    this.photoUrl,
    required this.size,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 4),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.35),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? UserPhotoView(
                fallbackUrl: photoUrl,
                fit: BoxFit.cover,
                errorWidget: _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[850],
      child: Icon(
        Icons.person_rounded,
        size: size * 0.46,
        color: Colors.white54,
      ),
    );
  }
}

class _ConfettiParticle extends StatefulWidget {
  final double delay;
  final Color color;

  const _ConfettiParticle({required this.delay, required this.color});

  @override
  State<_ConfettiParticle> createState() => _ConfettiParticleState();
}

class _ConfettiParticleState extends State<_ConfettiParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _startX;
  late double _startY;
  late double _endX;
  late double _endY;
  late double _size;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    final random = Random();
    _startX = random.nextDouble() * 420 - 210;
    _startY = -60;
    _endX = random.nextDouble() * 680 - 340;
    _endY = 920;
    _size = 6 + random.nextDouble() * 6;

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final x = _startX + (_endX - _startX) * _animation.value;
        final y = _startY + (_endY - _startY) * _animation.value;
        final rotation = _animation.value * 4 * pi;
        final opacity = 1.0 - _animation.value;

        return Positioned(
          left: MediaQuery.of(context).size.width / 2 + x,
          top: y,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: rotation,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
