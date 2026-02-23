import 'package:date_and_doing/views/home/dd_home.dart';
import 'package:date_and_doing/views/home/discover/dd_discover.dart';
import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'dd_chat_page.dart';

class DdMessages extends StatefulWidget {
  const DdMessages({super.key});

  @override
  State<DdMessages> createState() => _DdMessagesState();
}

class _DdMessagesState extends State<DdMessages> {
  final _api = ApiService();
  final _prefs = SharedPreferencesService();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final myId = await _prefs.getUserIdOrThrow();

      // 1) Traer mensajes y matches
      final allMessages = await _api.getAllMessages();
      final allMatches = await _api.getAllMatches();

      // 2) Mapear matchId -> other_user
      final Map<int, Map<String, dynamic>> matchInfo = {};
      for (final m in allMatches) {
        final matchId = _asInt(m["ddm_int_id"]);
        if (matchId == null) continue;

        final other = m["other_user"];
        if (other is Map) {
          matchInfo[matchId] = {
            "otherUserId": _asInt(other["use_int_id"]) ?? 0,
            "nombre": (other["fullname"] ?? "Usuario").toString(),
            "foto": (other["photo"] ?? "https://via.placeholder.com/150")
                .toString(),
          };
        }
      }

      // 3) Agrupar mensajes por match
      final Map<int, List<Map<String, dynamic>>> grouped = {};
      for (final msg in allMessages) {
        if (msg["ddmsg_txt_status"] != "ACTIVO") continue;

        final matchId = _asInt(msg["ddm_int_id"]);
        if (matchId == null) continue;

        grouped.putIfAbsent(matchId, () => []);
        grouped[matchId]!.add(msg);
      }

      // 4) Construir conversaciones
      final List<Map<String, dynamic>> conversations = [];

      grouped.forEach((matchId, msgs) {
        msgs.sort((a, b) {
          final da = DateTime.parse(a["ddmsg_timestamp_datecreate"].toString());
          final db = DateTime.parse(b["ddmsg_timestamp_datecreate"].toString());
          return da.compareTo(db);
        });

        final last = msgs.last;
        final createdAt = DateTime.parse(
          last["ddmsg_timestamp_datecreate"].toString(),
        );

        final unread = msgs.where((m) {
          final receiver = _asInt(m["use_int_receiver"]);
          final read = m["ddmsg_bool_read"] == true;
          return receiver == myId && !read;
        }).length;

        int otherUserId = matchInfo[matchId]?["otherUserId"] ?? 0;
        if (otherUserId == 0) {
          final sender = _asInt(last["use_int_sender"]) ?? 0;
          final receiver = _asInt(last["use_int_receiver"]) ?? 0;
          otherUserId = sender == myId ? receiver : sender;
        }

        conversations.add({
          "matchId": matchId,
          "otherUserId": otherUserId,
          "nombre": matchInfo[matchId]?["nombre"] ?? "Chat #$matchId",
          "foto":
              matchInfo[matchId]?["foto"] ?? "https://via.placeholder.com/150",
          "ultimoMensaje": (last["ddmsg_txt_body"] ?? "").toString(),
          "hora": TimeOfDay.fromDateTime(createdAt).format(context),
          "noLeidos": unread,
          "timestamp": createdAt.millisecondsSinceEpoch,
        });
      });

      conversations.sort(
        (a, b) => (b["timestamp"] as int).compareTo(a["timestamp"] as int),
      );

      if (!mounted) return;
      setState(() {
        _conversations = conversations;
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

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  void _openChat(Map<String, dynamic> c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DdChatPage(
          matchId: c["matchId"],
          otherUserId: c["otherUserId"],
          nombre: c["nombre"],
          foto: c["foto"],
        ),
      ),
    ).then((_) => _loadConversations());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _MessagesSkeleton();
    }

    if (_error != null) {
      return _MessagesErrorState(message: _error!, onRetry: _loadConversations);
    }

    if (_conversations.isEmpty) {
      return _EmptyMessagesState(onRefresh: _loadConversations);
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: ListView.separated(
          itemCount: _conversations.length,
          separatorBuilder: (_, __) => const Divider(indent: 72),
          itemBuilder: (context, i) {
            final chat = _conversations[i];

            return ListTile(
              onTap: () => _openChat(chat),
              leading: CircleAvatar(
                backgroundImage: NetworkImage(chat["foto"]),
              ),
              title: Text(chat["nombre"]),
              subtitle: Text(
                chat["ultimoMensaje"],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(chat["hora"], style: const TextStyle(fontSize: 11)),
                  if (chat["noLeidos"] > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "${chat["noLeidos"]}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ================== EMPTY STATE ==================

class _EmptyMessagesState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyMessagesState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
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
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '¡No tienes mensajes aún!',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cuando hagas match con alguien, podrás chatear aquí',
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
                          // Navegar a discover para hacer matches
                          // Navigator.of(
                          //   context,
                          // ).popUntil((route) => route.isFirst);

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DdHome()),
                          );
                        },
                        icon: const Icon(Icons.explore_rounded),
                        label: const Text('Descubrir personas'),
                        style: TextButton.styleFrom(
                          foregroundColor: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== SKELETON LOADER ==================

class _MessagesSkeleton extends StatefulWidget {
  const _MessagesSkeleton();

  @override
  State<_MessagesSkeleton> createState() => _MessagesSkeletonState();
}

class _MessagesSkeletonState extends State<_MessagesSkeleton>
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
      body: ListView.separated(
        itemCount: 6,
        separatorBuilder: (_, __) => const Divider(indent: 72),
        itemBuilder: (context, i) {
          return _ShimmerContainer(
            animation: _animation,
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
              ),
              title: Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              subtitle: Container(
                width: 200,
                height: 14,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              trailing: Container(
                width: 40,
                height: 12,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================== ERROR STATE ==================

class _MessagesErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MessagesErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
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
                onPressed: onRetry,
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
      ),
    );
  }
}

// ================== SHIMMER WIDGET ==================

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
