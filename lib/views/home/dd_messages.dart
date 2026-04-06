import 'dart:ui';
import 'package:date_and_doing/widgets/user_photo_view.dart';
import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:date_and_doing/services/multi_chat_websocket_service.dart';

import 'package:date_and_doing/views/home/dd_home.dart';
import 'dd_chat_page.dart';

const List<Map<String, String>> kReportReasons = [
  {"value": "SPAM", "label": "Spam"},
  {"value": "HARASSMENT", "label": "Acoso"},
  {"value": "FAKE_PROFILE", "label": "Perfil falso"},
  {"value": "INAPPROPRIATE_CONTENT", "label": "Contenido inapropiado"},
  {"value": "SCAM", "label": "Estafa"},
  {"value": "OTHER", "label": "Otro"},
];

class DdMessages extends StatefulWidget {
  final VoidCallback? onUnreadCountChanged;

  const DdMessages({super.key, this.onUnreadCountChanged});

  @override
  State<DdMessages> createState() => _DdMessagesState();
}

class _DdMessagesState extends State<DdMessages> {
  final _api = ApiService();
  final _prefs = SharedPreferencesService();
  final _multiWs = MultiChatWebSocketService();

  bool _loading = true;
  String? _error;

  int? _myId;

  // conversations:
  // {
  //  matchId, otherUserId, nombre, foto,
  //  ultimoMensaje, hora, noLeidos, timestamp
  // }
  List<Map<String, dynamic>> _conversations = [];

  // Para actualizar rápido por matchId
  final Map<int, int> _indexByMatchId = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();

    _multiWs.events.listen(_onInboxWsEvent);
  }

  Future<void> _bootstrap() async {
    _myId = await _prefs.getUserIdOrThrow();
    await _loadConversations();
    await _connectSocketsForVisibleConversations();
  }

  Future<void> _showReportDialog({
    required int matchId,
    required String userName,
  }) async {
    String selectedReason = "SPAM";
    final detailsController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text("Reportar a $userName"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Selecciona un motivo"),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      items: kReportReasons
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e["value"],
                              child: Text(e["label"]!),
                            ),
                          )
                          .toList(),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value == null) return;
                              setLocalState(() {
                                selectedReason = value;
                              });
                            },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: detailsController,
                      enabled: !isSubmitting,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Detalles adicionales",
                        hintText: "Cuéntanos qué pasó",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text("Cancelar"),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setLocalState(() {
                            isSubmitting = true;
                          });

                          try {
                            await _api.matchSafetyAction(
                              matchId: matchId,
                              action: "report",
                              reason: selectedReason,
                              details: detailsController.text.trim(),
                            );

                            if (!mounted) return;

                            if (Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop();
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Reporte enviado correctamente"),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;

                            setLocalState(() {
                              isSubmitting = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("No se pudo reportar: $e"),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Reportar"),
                ),
              ],
            );
          },
        );
      },
    );

    detailsController.dispose();
  }

  Future<void> _connectSocketsForVisibleConversations() async {
    // Conecta a todos los matchId que están en la lista.
    // Si quieres optimizar: conecta solo a los primeros 30.
    final ids = _conversations.map((c) => c["matchId"] as int).toList();
    await _multiWs.connectMany(ids);
  }

  void _onInboxWsEvent(Map<String, dynamic> event) {
    if (!mounted) return;

    final type = (event["type"] ?? "").toString();

    // Tu backend termina enviando type = "chat.message" (porque **event pisa el type="message")
    // y también puede mandar "connected" o "chat.read".
    if (type != "chat.message") return;

    final matchId = _asInt(
      event["ddm_int_id"] ?? event["__match_id"] ?? event["match_id"],
    );
    if (matchId == null) return;

    final body = (event["body"] ?? "").toString();
    if (body.isEmpty) return;

    DateTime createdAt;
    try {
      createdAt = DateTime.parse((event["created_at"] ?? "").toString());
    } catch (_) {
      createdAt = DateTime.now();
    }

    final receiverId = _asInt(
      event["receiver_id"] ?? event["use_int_receiver"],
    );
    final isForMe =
        (_myId != null && receiverId != null && receiverId == _myId);

    // Si la conversación no existe en lista (raro), recargamos todo.
    if (!_indexByMatchId.containsKey(matchId)) {
      _loadConversations();
      return;
    }

    setState(() {
      final idx = _indexByMatchId[matchId]!;
      final old = _conversations[idx];

      final newUnread = (old["noLeidos"] as int? ?? 0) + (isForMe ? 1 : 0);

      final updated = {
        ...old,
        "ultimoMensaje": body,
        "hora": TimeOfDay.fromDateTime(createdAt).format(context),
        "timestamp": createdAt.millisecondsSinceEpoch,
        "noLeidos": newUnread,
      };

      // mover al top
      _conversations.removeAt(idx);
      _conversations.insert(0, updated);

      _rebuildIndex();
    });
  }

  Future<void> _loadConversations() async {
    final firstLoad = _conversations.isEmpty;
    if (firstLoad) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    try {
      final myId = _myId ?? await _prefs.getUserIdOrThrow();

      final allMessages = await _api.getAllMessages();
      final allMatches = await _api.getAllMatches();

      // matchId -> other_user info
      final Map<int, Map<String, dynamic>> matchInfo = {};
      for (final m in allMatches) {
        final matchId = _asInt(m["ddm_int_id"]);
        if (matchId == null) continue;

        final other = m["other_user"];
        if (other is Map) {
          matchInfo[matchId] = {
            "otherUserId": _asInt(other["use_int_id"]) ?? 0,
            "nombre": (other["fullname"] ?? "Usuario").toString(),
            "fotoBase64": other["photo_preview_base64"]?.toString(),
            "fotoFallbackUrl":
                (other["photo_fallback_url"] ?? other["photo"] ?? "")
                    .toString(),
          };
        }
      }

      // agrupar mensajes por match
      final Map<int, List<Map<String, dynamic>>> grouped = {};
      for (final msg in allMessages) {
        if (msg["ddmsg_txt_status"] != "ACTIVO") continue;

        final matchId = _asInt(msg["ddm_int_id"]);
        if (matchId == null) continue;

        grouped.putIfAbsent(matchId, () => []);
        grouped[matchId]!.add(msg);
      }

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
          "fotoBase64": matchInfo[matchId]?["fotoBase64"],
          "fotoFallbackUrl": matchInfo[matchId]?["fotoFallbackUrl"] ?? "",
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
        _rebuildIndex();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _rebuildIndex() {
    _indexByMatchId.clear();
    for (int i = 0; i < _conversations.length; i++) {
      _indexByMatchId[_conversations[i]["matchId"] as int] = i;
    }
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  void _openChat(Map<String, dynamic> c) async {
    // Cuando entras al chat, normalmente quieres resetear el badge local.
    setState(() {
      c["noLeidos"] = 0;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DdChatPage(
          matchId: c["matchId"],
          otherUserId: c["otherUserId"],
          nombre: c["nombre"],
          foto: c["fotoFallbackUrl"] ?? "",
          fotoBase64: c["fotoBase64"],
        ),
      ),
    );

    // Al volver, refresca por si cambió algo
    await _loadConversations();
    await _connectSocketsForVisibleConversations();
  }

  @override
  void dispose() {
    _multiWs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _MessagesSkeleton();
    if (_error != null)
      return _MessagesErrorState(message: _error!, onRetry: _loadConversations);
    if (_conversations.isEmpty)
      return _EmptyMessagesState(onRefresh: _loadConversations);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadConversations();
          await _connectSocketsForVisibleConversations();
        },
        child: ListView.separated(
          itemCount: _conversations.length,
          separatorBuilder: (_, __) => const Divider(indent: 72),
          itemBuilder: (context, i) {
            final chat = _conversations[i];

            return ListTile(
              onTap: () => _openChat(chat),
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: ClipOval(
                  child: UserPhotoView(
                    base64String: chat["fotoBase64"]?.toString(),
                    fallbackUrl: chat["fotoFallbackUrl"]?.toString(),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: const Icon(Icons.person),
                  ),
                ),
              ),
              title: Text(chat["nombre"]),
              subtitle: Text(
                chat["ultimoMensaje"],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(chat["hora"], style: const TextStyle(fontSize: 10)),
                      if ((chat["noLeidos"] as int) > 0)
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
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == "report") {
                        await Future.delayed(const Duration(milliseconds: 120));
                        if (!mounted) return;

                        await _showReportDialog(
                          matchId: chat["matchId"] as int,
                          userName: (chat["nombre"] ?? "usuario").toString(),
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: "report",
                        child: Text("Reportar usuario"),
                      ),
                    ],
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
