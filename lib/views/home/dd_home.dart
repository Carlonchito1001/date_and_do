import 'dart:async';

import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:date_and_doing/views/profile_user/home_profile.dart';

import 'discover/dd_discover.dart';
import 'dd_matches.dart';
import './dd_messages.dart';

class DdHome extends StatefulWidget {
  const DdHome({super.key});

  @override
  State<DdHome> createState() => _DdHomeState();
}

class _DdHomeState extends State<DdHome> with TickerProviderStateMixin {
  int _currentIndex = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _matchesCount = 0;
  int _messagesCount = 0;

  Timer? _unreadMessagesTimer;
  final _api = ApiService();
  final _prefs = SharedPreferencesService();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    _loadUnreadMessagesCount();

    _unreadMessagesTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadUnreadMessagesCount(),
    );
  }

  Future<void> _loadUnreadMessagesCount() async {
    try {
      final myId = await _prefs.getUserIdOrThrow();
      final allMessages = await _api.getAllMessages();

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

    if (_currentIndex == 2) {
      _loadUnreadMessagesCount();
    }

    setState(() {
      _currentIndex = index;
    });

    _animationController.reset();
    _animationController.forward();
  }

  String _getSectionTitle() {
    switch (_currentIndex) {
      case 0:
        return "Descubrir";
      case 1:
        return "Matches";
      case 2:
        return "Mensajes";
      case 3:
        return "Mi perfil";
      default:
        return "Inicio";
    }
  }

  IconData _getSectionIcon() {
    switch (_currentIndex) {
      case 0:
        return Icons.explore_rounded;
      case 1:
        return Icons.favorite_rounded;
      case 2:
        return Icons.chat_bubble_rounded;
      case 3:
        return Icons.person_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 78,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withOpacity(0.16),
                    cs.secondary.withOpacity(0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.primary.withOpacity(0.10)),
              ),
              child: Icon(_getSectionIcon(), color: cs.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [cs.primary, cs.secondary],
                      ).createShader(bounds);
                    },
                    child: const Text(
                      "Date & Do",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getSectionTitle(),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: cs.outlineVariant.withOpacity(0.35),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            const DdDiscover(),
            const DdMatchesPage(),
            DdMessages(
              onUnreadCountChanged: _loadUnreadMessagesCount,
              onGoToDiscover: () => _onItemTapped(0),
            ),
            const HomeProfile(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? cs.surfaceContainerHighest.withOpacity(0.55)
                : cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
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
    );
  }
}

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
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
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
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? cs.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.icon,
                    color: widget.isSelected
                        ? cs.primary
                        : cs.onSurfaceVariant.withOpacity(0.8),
                    size: widget.isSelected ? 26 : 24,
                  ),
                  if (widget.badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.error,
                          borderRadius: BorderRadius.circular(999),
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
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  color: widget.isSelected
                      ? cs.primary
                      : cs.onSurfaceVariant.withOpacity(0.8),
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
