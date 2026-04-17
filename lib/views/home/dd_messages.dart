import 'dart:async';

import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/multi_chat_websocket_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:date_and_doing/widgets/user_photo_view.dart';

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
  final VoidCallback? onGoToDiscover;

  const DdMessages({super.key, this.onUnreadCountChanged, this.onGoToDiscover});

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

  StreamSubscription<Map<String, dynamic>>? _multiWsEventsSub;

  List<Map<String, dynamic>> _conversations = [];
  final Map<int, int> _indexByMatchId = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _multiWsEventsSub = _multiWs.events.listen(_onInboxWsEvent);
  }

  DateTime _safeParseToLocal(dynamic raw) {
    if (raw == null) return DateTime.now().toLocal();

    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return DateTime.now().toLocal();
    }
  }

  String _formatHour(DateTime dt) {
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  void _sortConversationsInPlace() {
    _conversations.sort(
      (a, b) => ((b["timestamp"] as int?) ?? 0).compareTo(
        (a["timestamp"] as int?) ?? 0,
      ),
    );
  }

  void _rebuildIndex() {
    _indexByMatchId.clear();
    for (int i = 0; i < _conversations.length; i++) {
      _indexByMatchId[_conversations[i]["matchId"] as int] = i;
    }
  }

  Future<void> _bootstrap() async {
    try {
      _myId = await _prefs.getUserIdOrThrow();
      if (!mounted) return;

      await _loadConversations();
      if (!mounted) return;

      await _connectSocketsForVisibleConversations();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _connectSocketsForVisibleConversations() async {
    final ids = _conversations.map((c) => c["matchId"] as int).toList();
    await _multiWs.connectMany(ids);
  }

  void _onInboxWsEvent(Map<String, dynamic> event) {
    if (!mounted) return;

    final type = (event["type"] ?? "").toString();
    if (type != "chat.message") return;

    final matchId = _asInt(
      event["ddm_int_id"] ?? event["__match_id"] ?? event["match_id"],
    );
    if (matchId == null) return;

    final body = (event["body"] ?? "").toString();
    if (body.isEmpty) return;

    final createdAt = _safeParseToLocal(event["created_at"]);
    final receiverId = _asInt(
      event["receiver_id"] ?? event["use_int_receiver"],
    );
    final isForMe =
        (_myId != null && receiverId != null && receiverId == _myId);

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
        "hora": _formatHour(createdAt),
        "timestamp": createdAt.millisecondsSinceEpoch,
        "noLeidos": newUnread,
      };

      _conversations.removeAt(idx);
      _conversations.insert(0, updated);

      _sortConversationsInPlace();
      _rebuildIndex();
    });

    widget.onUnreadCountChanged?.call();
  }

  Future<void> _showReportDialog({
    required int matchId,
    required String userName,
  }) async {
    String selectedReason = "SPAM";
    final detailsController = TextEditingController();
    bool isSubmitting = false;
    final cs = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: cs.surface,
              title: Text(
                "Reportar a $userName",
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Selecciona un motivo",
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: detailsController,
                      enabled: !isSubmitting,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "Detalles adicionales",
                        hintText: "Cuéntanos qué pasó",
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
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
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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
          final da = _safeParseToLocal(a["ddmsg_timestamp_datecreate"]);
          final db = _safeParseToLocal(b["ddmsg_timestamp_datecreate"]);
          return da.compareTo(db);
        });

        final last = msgs.last;
        final createdAt = _safeParseToLocal(last["ddmsg_timestamp_datecreate"]);

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
          "hora": _formatHour(createdAt),
          "timestamp": createdAt.millisecondsSinceEpoch,
          "noLeidos": unread,
        });
      });

      conversations.sort(
        (a, b) => ((b["timestamp"] as int?) ?? 0).compareTo(
          (a["timestamp"] as int?) ?? 0,
        ),
      );

      if (!mounted) return;

      setState(() {
        _conversations = conversations;
        _loading = false;
        _rebuildIndex();
      });

      widget.onUnreadCountChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openChat(Map<String, dynamic> c) async {
    setState(() {
      c["noLeidos"] = 0;
    });

    widget.onUnreadCountChanged?.call();

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

    await _loadConversations();
    await _connectSocketsForVisibleConversations();
  }

  @override
  void dispose() {
    _multiWsEventsSub?.cancel();
    _multiWs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _MessagesSkeleton();

    if (_error != null) {
      return _MessagesErrorState(message: _error!, onRetry: _loadConversations);
    }

    if (_conversations.isEmpty) {
      return _EmptyMessagesState(
        onRefresh: _loadConversations,
        onGoToDiscover: widget.onGoToDiscover,
      );
    }

    final cs = Theme.of(context).colorScheme;

    return ColoredBox(
      color: cs.surface,
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadConversations();
          await _connectSocketsForVisibleConversations();
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: _conversations.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 84,
            endIndent: 8,
            color: cs.outlineVariant.withOpacity(0.25),
          ),
          itemBuilder: (context, i) {
            final chat = _conversations[i];
            final unreadCount = (chat["noLeidos"] as int?) ?? 0;
            final hasUnread = unreadCount > 0;

            return _ConversationTile(
              nombre: chat["nombre"]?.toString() ?? "Usuario",
              ultimoMensaje: chat["ultimoMensaje"]?.toString() ?? "",
              hora: chat["hora"]?.toString() ?? "",
              unreadCount: unreadCount,
              fotoBase64: chat["fotoBase64"]?.toString(),
              fotoFallbackUrl: chat["fotoFallbackUrl"]?.toString(),
              hasUnread: hasUnread,
              onTap: () => _openChat(chat),
              onReport: () async {
                await Future.delayed(const Duration(milliseconds: 120));
                if (!mounted) return;

                await _showReportDialog(
                  matchId: chat["matchId"] as int,
                  userName: (chat["nombre"] ?? "usuario").toString(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String nombre;
  final String ultimoMensaje;
  final String hora;
  final int unreadCount;
  final String? fotoBase64;
  final String? fotoFallbackUrl;
  final bool hasUnread;
  final VoidCallback onTap;
  final Future<void> Function() onReport;

  const _ConversationTile({
    required this.nombre,
    required this.ultimoMensaje,
    required this.hora,
    required this.unreadCount,
    required this.fotoBase64,
    required this.fotoFallbackUrl,
    required this.hasUnread,
    required this.onTap,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasUnread
                        ? cs.primary.withOpacity(0.35)
                        : cs.outlineVariant.withOpacity(0.25),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: UserPhotoView(
                    base64String: fotoBase64,
                    fallbackUrl: fotoFallbackUrl,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorWidget: Icon(Icons.person, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          hora,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: hasUnread
                                ? cs.primary
                                : cs.onSurfaceVariant.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ultimoMensaje.isEmpty
                                ? 'Sin mensajes aún'
                                : ultimoMensaje,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.2,
                              color: hasUnread
                                  ? cs.onSurface.withOpacity(0.88)
                                  : cs.onSurfaceVariant,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (unreadCount > 0)
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        PopupMenuButton<String>(
                          tooltip: 'Opciones',
                          onSelected: (value) async {
                            if (value == "report") {
                              await onReport();
                            }
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: cs.onSurfaceVariant.withOpacity(0.9),
                            size: 20,
                          ),
                          itemBuilder: (context) => const [
                            PopupMenuItem<String>(
                              value: "report",
                              child: Text("Reportar usuario"),
                            ),
                          ],
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

// ================== EMPTY STATE ==================

class _EmptyMessagesState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final VoidCallback? onGoToDiscover;

  const _EmptyMessagesState({required this.onRefresh, this.onGoToDiscover});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: cs.surface,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary.withOpacity(0.10),
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 52,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Aún no tienes mensajes',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Cuando hagas match con alguien, tus conversaciones aparecerán aquí.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 26),
                      FilledButton.icon(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Actualizar'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: onGoToDiscover,
                        icon: const Icon(Icons.explore_rounded),
                        label: const Text('Descubrir personas'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
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
      duration: const Duration(milliseconds: 1400),
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

    return ColoredBox(
      color: cs.surface,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: 7,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 84,
          endIndent: 8,
          color: cs.outlineVariant.withOpacity(0.20),
        ),
        itemBuilder: (context, i) {
          return _ShimmerConversationTile(animation: _animation);
        },
      ),
    );
  }
}

class _ShimmerConversationTile extends StatelessWidget {
  final Animation<double> animation;

  const _ShimmerConversationTile({required this.animation});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _ShimmerContainer(
      animation: animation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 130,
                        height: 15,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 34,
                        height: 11,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 13,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
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

// ================== ERROR STATE ==================

class _MessagesErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _MessagesErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: cs.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.errorContainer.withOpacity(0.20),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.error.withOpacity(0.12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withOpacity(0.40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 42,
                    color: cs.error,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Ups, algo salió mal',
                  style: textTheme.titleLarge?.copyWith(
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
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
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
                cs.surfaceContainerHighest.withOpacity(0.45),
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
