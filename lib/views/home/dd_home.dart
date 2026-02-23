import 'dart:async';
import 'dart:ui';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:date_and_doing/views/profile_user/home_profile.dart';
import 'package:flutter/material.dart';
import 'discover/dd_discover.dart';
import './dd_matches..dart';
import './dd_messages.dart';

class DdHome extends StatefulWidget {
  const DdHome({super.key});

  @override
  State<DdHome> createState() => _DdHomeState();
}

class _DdHomeState extends State<DdHome> with TickerProviderStateMixin {
  int _currentIndex = 0;

  // Controladores para animaciones
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Contadores de notificaciones
  int _matchesCount = 0;
  int _messagesCount = 0;

  // Timer para actualizar mensajes no leídos
  Timer? _unreadMessagesTimer;
  final _api = ApiService();
  final _prefs = SharedPreferencesService();

  // Keys para mantener el estado de cada página
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Cargar mensajes no leídos inmediatamente
    _loadUnreadMessagesCount();

    // Actualizar cada 10 segundos
    _unreadMessagesTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadUnreadMessagesCount(),
    );
  }

  Future<void> _loadUnreadMessagesCount() async {
    try {
      final myId = await _prefs.getUserIdOrThrow();
      final allMessages = await _api.getAllMessages();

      // Contar mensajes no leídos donde yo soy el receptor
      final unreadCount = allMessages.where((m) {
        final isRead = m["ddmsg_bool_read"] == true;
        final receiverId = m["use_int_receiver"];
        final status = m["ddmsg_txt_status"];
        return !isRead && receiverId == myId && status == "ACTIVO";
      }).length;

      if (mounted) {
        setState(() {
          _messagesCount = unreadCount;
        });
      }
    } catch (e) {
      // Silenciar errores - no es crítico
      debugPrint("Error loading unread messages: $e");
    }
  }

  @override
  void dispose() {
    _unreadMessagesTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;

    // Si venimos del tab de mensajes (índice 2), actualizar conteo
    if (_currentIndex == 2) {
      _loadUnreadMessagesCount();
    }

    setState(() {
      _currentIndex = index;
    });

    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,

      // AppBar elegante con blur
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 8),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              elevation: 0,
              backgroundColor: cs.surface.withOpacity(0.7),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.surface.withOpacity(0.9),
                      cs.surface.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withOpacity(0.2),
                          cs.secondary.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: cs.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [cs.primary, cs.secondary],
                      ).createShader(bounds);
                    },
                    child: const Text(
                      "Date & Do",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              centerTitle: false,
              actions: [
                // Botón de notificaciones
                _NotificationButton(
                  icon: Icons.notifications_outlined,
                  count: 0,
                  onTap: () {
                    // Mostrar notificaciones
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),

      // Body con animación de fade
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            DdDiscover(),
            DdMatches(),
            DdMessages(),
            HomeProfile(),
          ],
        ),
      ),

      // Bottom Navigation Bar premium
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? cs.surfaceVariant.withOpacity(0.5) : cs.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: cs.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavBarItem(
                    icon: Icons.explore_rounded,
                    label: "Descubrir",
                    isSelected: _currentIndex == 0,
                    onTap: () => _onItemTapped(0),
                    colorScheme: cs,
                  ),
                  _NavBarItem(
                    icon: Icons.favorite_rounded,
                    label: "Matches",
                    isSelected: _currentIndex == 1,
                    badgeCount: _matchesCount,
                    onTap: () => _onItemTapped(1),
                    colorScheme: cs,
                  ),
                  _NavBarItem(
                    icon: Icons.chat_bubble_rounded,
                    label: "Mensajes",
                    isSelected: _currentIndex == 2,
                    badgeCount: _messagesCount,
                    onTap: () => _onItemTapped(2),
                    colorScheme: cs,
                  ),
                  _NavBarItem(
                    icon: Icons.person_rounded,
                    label: "Perfil",
                    isSelected: _currentIndex == 3,
                    onTap: () => _onItemTapped(3),
                    colorScheme: cs,
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

// ================== NOTIFICATION BUTTON ==================

class _NotificationButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  const _NotificationButton({
    required this.icon,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Stack(
            children: [
              Icon(icon, color: cs.onSurface.withOpacity(0.8), size: 24),
              if (count > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== CUSTOM NAV BAR ITEM ==================

class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.badgeCount = 0,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [
                      cs.primary.withOpacity(0.15),
                      cs.secondary.withOpacity(0.1),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),

                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? cs.primary.withOpacity(0.2)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.isSelected
                          ? cs.primary
                          : cs.onSurface.withOpacity(0.5),
                      size: widget.isSelected ? 26 : 24,
                    ),
                  ),
                  if (widget.badgeCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cs.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          widget.badgeCount > 9 ? '9+' : '${widget.badgeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: widget.isSelected
                      ? cs.primary
                      : cs.onSurface.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
