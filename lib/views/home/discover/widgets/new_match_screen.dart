import 'dart:math';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    
    // Controlador principal para la animación de entrada
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Controlador para el efecto pulse
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Iniciar animación de entrada
    Future.delayed(const Duration(milliseconds: 100), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _goToChat(BuildContext context) {
    Navigator.pop(context); // Cerrar pantalla de match'ñ
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Stack(
        children: [
          // Fondo con gradiente animado
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.3),
                    radius: 0.8 + (_pulseAnimation.value - 1.0) * 0.5,
                    colors: [
                      cs.primary.withOpacity(0.3),
                      Colors.pink.withOpacity(0.2),
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              );
            },
          ),

          // Partículas/Confetti decorativo
          ...List.generate(20, (index) {
            return _ConfettiParticle(
              delay: index * 0.1,
              color: [
                cs.primary,
                Colors.pink,
                Colors.amber,
                cs.secondary,
              ][index % 4],
            );
          }),

          // Contenido principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Título animado
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        Text(
                          '¡Es un Match!',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: cs.primary.withOpacity(0.8),
                                blurRadius: 20,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A ti y a ${widget.matchedUserName} les gustan mutuamente',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Fotos de los usuarios con animación
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Tu foto
                              _UserAvatar(
                                photoUrl: widget.currentUserPhoto,
                                size: 100,
                                borderColor: cs.primary,
                              ),
                              const SizedBox(width: 16),
                              // Icono de corazón
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.pink,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.pink.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Foto del match
                              _UserAvatar(
                                photoUrl: widget.matchedUserPhoto,
                                size: 100,
                                borderColor: Colors.pink,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Nombre del match
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Text(
                      widget.matchedUserName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Botones de acción
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        // Botón principal: Enviar mensaje
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () => _goToChat(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.chat_bubble_rounded),
                            label: const Text(
                              'Enviar mensaje',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Botón secundario: Seguir descubriendo
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () => _keepSwiping(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.swipe_rounded),
                            label: const Text(
                              'Seguir descubriendo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================== USER AVATAR WIDGET ==================

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
        border: Border.all(
          color: borderColor,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: Icon(
        Icons.person_rounded,
        size: size * 0.5,
        color: Colors.white54,
      ),
    );
  }
}

// ================== CONFETTI PARTICLE ==================

class _ConfettiParticle extends StatefulWidget {
  final double delay;
  final Color color;

  const _ConfettiParticle({
    required this.delay,
    required this.color,
  });

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // Posiciones aleatorias
    final random = Random();
    _startX = random.nextDouble() * 400 - 200;
    _startY = -50;
    _endX = random.nextDouble() * 600 - 300;
    _endY = 900;

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
            opacity: opacity,
            child: Transform.rotate(
              angle: rotation,
              child: Container(
                width: 8,
                height: 8,
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