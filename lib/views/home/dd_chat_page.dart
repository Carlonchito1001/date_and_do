// dd_chat_page.dart
import 'dart:async';
import 'dart:ui';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/models/dd_date.dart';
import 'package:date_and_doing/models/analysis_result.dart';
import 'package:date_and_doing/services/chat_ai_service.dart';
import 'package:date_and_doing/services/chat_websocket_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:date_and_doing/views/history/history_levels.dart';
import 'package:date_and_doing/views/home/discover/widgets/chat_date_card.dart';
import 'package:date_and_doing/views/home/discover/widgets/dd_create_activity_page.dart';
import 'package:date_and_doing/widgets/modal_alini_unlocked.dart';
import 'package:date_and_doing/widgets/modal_day_chat.dart';
import 'package:flutter/material.dart';

int ChatDay =
    1; // variable global para controlar el día del chat (puede ser parte de un provider o similar en una app real)

enum _ChatMenuAction { refreshDates, historyWorld, ai }

class DdChatPage extends StatefulWidget {
  final int matchId;
  final int otherUserId;
  final String nombre;
  final String foto;

  const DdChatPage({
    super.key,
    required this.matchId,
    required this.otherUserId,
    required this.nombre,
    required this.foto,
  });

  @override
  State<DdChatPage> createState() => _DdChatPageState();
}

class _DdChatPageState extends State<DdChatPage> with TickerProviderStateMixin {
  int? _currentUserId;

  bool _loadingMessages = true;
  String? _messagesError;

  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ApiService _api = ApiService();
  final ChatWebSocketService _wsService = ChatWebSocketService();

  StreamSubscription? _wsSubscription;
  StreamSubscription? _wsConnectionSubscription;

  final List<Map<String, dynamic>> _messages = [];
  bool _sendingMsg = false;

  bool _loadingDates = true;
  List<DdDate> _dates = [];

  bool _analyzing = false;
  bool _shownAliniUnlockedThisSession = false;

  // ✅ Usa tu ChatAiService (ya lo tienes)
  late final ChatAiService _ai = ChatAiService(
    iaUrl:
        'https://n8n.fintbot.pe/webhook/be664844-a373-4376-888a-170049d6f2d5',
  );

  final String currentUser = "Juan";

  @override
  void initState() {
    super.initState();
    _bootstrap();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowAliniUnlocked();
    });
  }

  Future<void> _bootstrap() async {
    await _loadUserId();
    await _loadDates();
    await _loadMessages();
    await _initWebSocket();
    if (!mounted) return;
    // _scrollToBottom(animate: false);
    // Future.delayed(const Duration(milliseconds: 120), () {
    //   if (mounted) _scrollToBottom(animate: false);
    // });
  }

  Future<void> _loadUserId() async {
    _currentUserId = await SharedPreferencesService().getUserIdOrThrow();
  }

  Future<void> _initWebSocket() async {
    try {
      await _wsService.connect(widget.matchId);

      _wsSubscription = _wsService.messageStream.listen(_onWebSocketMessage);
      _wsConnectionSubscription = _wsService.connectionStream.listen(
        _onWebSocketConnectionChanged,
      );
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
    }
  }

  void _onWebSocketConnectionChanged(bool isConnected) {
    if (!mounted) return;
    _showToast(
      isConnected ? 'Conectado' : 'Desconectado. Reconectando...',
      isConnected ? Colors.green : Colors.orange,
    );
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    if (animate) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(0);
    }
  }

  // ✅ WS: backend manda chat.message
  void _onWebSocketMessage(Map<String, dynamic> message) async {
    if (!mounted) return;

    _currentUserId ??= await SharedPreferencesService().getUserIdOrThrow();

    final type = (message['type'] ?? '').toString();
    if (type != 'chat.message') return;

    // ✅ Filtra por match
    final wsMatchId = message['ddm_int_id'];
    if (wsMatchId != null &&
        wsMatchId.toString() != widget.matchId.toString()) {
      return;
    }

    final body = (message['body'] ?? '').toString();
    if (body.isEmpty) return;

    final senderId = message['sender_id'];
    final receiverId = message['receiver_id'];
    final serverMsgId = message['ddmsg_int_id'];

    if (senderId == null) return;

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(message['created_at']?.toString() ?? '');
    } catch (_) {
      createdAt = DateTime.now();
    }

    final isMine = senderId.toString() == _currentUserId.toString();

    final newMessage = {
      'id': serverMsgId ?? DateTime.now().millisecondsSinceEpoch,
      'sender_id': senderId,
      'autor': isMine ? 'Yo' : widget.nombre,
      'text': body,
      'hora': TimeOfDay.fromDateTime(createdAt).format(context),
      'fecha': createdAt.toIso8601String().substring(0, 10),
      'is_read': (message['read'] == true),
      'is_temp': false,
    };

    setState(() {
      // evita duplicados por id
      if (serverMsgId != null &&
          _messages.any((m) => m['id'].toString() == serverMsgId.toString())) {
        return;
      }

      if (isMine) {
        // ✅ reemplaza el último temp con ese texto
        final idx = _messages.lastIndexWhere(
          (m) => m['is_temp'] == true && (m['text']?.toString() == body),
        );
        if (idx != -1) {
          _messages[idx] = newMessage;
        } else {
          _messages.add(newMessage);
        }
      } else {
        _messages.add(newMessage);
      }
    });

    _scrollToBottom(animate: true);

    // marcar como leído si yo soy receptor
    if (_currentUserId != null &&
        receiverId != null &&
        receiverId.toString() == _currentUserId.toString()) {
      try {
        await _api.markMessagesAsRead(widget.matchId);
      } catch (_) {}
    }
  }

  Future<void> _loadDates() async {
    setState(() => _loadingDates = true);
    try {
      final list = await _api.getDatesForMatch(widget.matchId);
      list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      if (!mounted) return;
      setState(() {
        _dates = list;
        _loadingDates = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDates = false);
      _showToast("Error cargando citas", Colors.red);
    }
  }

  Future<void> _confirmDate(DdDate d) async {
    try {
      await _api.confirmDate(d.id);
      await _loadDates();
      _showToast("✅ Cita confirmada", Colors.green);
    } catch (e) {
      _showToast("❌ Error confirmando: $e", Colors.red);
    }
  }

  Future<void> _rejectDate(DdDate d) async {
    try {
      await _api.rejectDate(d.id);
      await _loadDates();
      _showToast("✅ Cita rechazada", Colors.orange);
    } catch (e) {
      _showToast("❌ Error rechazando: $e", Colors.red);
    }
  }

  void _showToast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ Enviar tipo WhatsApp (temp inmediato)
  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sendingMsg) return;

    _currentUserId ??= await SharedPreferencesService().getUserIdOrThrow();

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id': tempId,
      'sender_id': _currentUserId,
      'autor': 'Yo',
      'text': text,
      'hora': TimeOfDay.now().format(context),
      'fecha': DateTime.now().toIso8601String().substring(0, 10),
      'is_read': false,
      'is_temp': true,
    };

    setState(() {
      _sendingMsg = true;
      _messages.add(tempMsg);
    });

    _messageCtrl.clear();
    _scrollToBottom(animate: true);

    try {
      if (_wsService.isConnected) {
        await _wsService.sendMessage(
          matchId: widget.matchId,
          receiverId: widget.otherUserId,
          body: text,
        );
      } else {
        // fallback HTTP
        await _api.sendMessage(
          matchId: widget.matchId,
          receiverId: widget.otherUserId,
          body: text,
        );
        await _loadMessages();
      }

      if (!mounted) return;
      setState(() => _sendingMsg = false);
      _scrollToBottom(animate: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sendingMsg = false;
        _messages.removeWhere((m) => m['id'] == tempId);
      });
      _showToast('Error enviando: $e', Colors.red);
    }
  }

  // ✅ Cargar mensajes SOLO del match (y conservar temps)
  Future<void> _loadMessages() async {
    setState(() {
      _loadingMessages = true;
      _messagesError = null;
    });

    try {
      _currentUserId ??= await SharedPreferencesService().getUserIdOrThrow();

      final list = await _api.getMessagesByMatch(widget.matchId);

      final filtered = list
          .where((m) => (m["ddmsg_txt_status"] ?? "ACTIVO") == "ACTIVO")
          .toList();

      filtered.sort((a, b) {
        final da = DateTime.parse(
          (a["ddmsg_timestamp_datecreate"] ??
                  a["created_at"] ??
                  DateTime.now().toIso8601String())
              .toString(),
        );
        final db = DateTime.parse(
          (b["ddmsg_timestamp_datecreate"] ??
                  b["created_at"] ??
                  DateTime.now().toIso8601String())
              .toString(),
        );
        return da.compareTo(db);
      });

      if (!mounted) return;

      final tempMessages = _messages
          .where((m) => m['is_temp'] == true)
          .toList();

      setState(() {
        _messages
          ..clear()
          ..addAll(
            filtered.map((m) {
              final createdAt = DateTime.parse(
                (m["ddmsg_timestamp_datecreate"] ??
                        m["created_at"] ??
                        DateTime.now().toIso8601String())
                    .toString(),
              );

              final senderId = m["use_int_sender"] ?? m["sender_id"];
              final isMine = senderId.toString() == _currentUserId.toString();

              return {
                "id": m["ddmsg_int_id"] ?? m["id"],
                "sender_id": senderId,
                "autor": isMine ? "Yo" : widget.nombre,
                "text": m["ddmsg_txt_body"] ?? m["body"] ?? "",
                "hora": TimeOfDay.fromDateTime(createdAt).format(context),
                "fecha": createdAt.toIso8601String().substring(0, 10),
                "is_read": (m["ddmsg_bool_read"] == true || m["read"] == true),
                "is_temp": false,
              };
            }),
          );

        if (tempMessages.isNotEmpty) _messages.addAll(tempMessages);
        _loadingMessages = false;
      });

      _scrollToBottom(animate: false);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _scrollToBottom(animate: false);
      });
      await _markUnreadMessagesAsRead(filtered);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messagesError = e.toString();
        _loadingMessages = false;
      });
    }
  }

  Future<void> _markUnreadMessagesAsRead(
    List<Map<String, dynamic>> messages,
  ) async {
    final hasUnread = messages.any((m) {
      final isRead = (m["ddmsg_bool_read"] == true || m["read"] == true);
      final receiverId = m["use_int_receiver"] ?? m["receiver_id"];
      return !isRead && receiverId.toString() == _currentUserId.toString();
    });

    if (!hasUnread) return;
    try {
      await _api.markMessagesAsRead(widget.matchId);
    } catch (_) {}
  }

  void _checkAndShowAliniUnlocked() async {
    if (ChatDay < 3) return;
    if (_shownAliniUnlockedThisSession) return;

    _shownAliniUnlockedThisSession = true;

    final wantsTry = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ModalAliniUnlocked(partnerName: widget.nombre),
    );

    if (wantsTry == true) _iniciarAliniVideoCall();
  }

  void _iniciarAliniVideoCall() {
    _showToast("Iniciando Alini Video Call...", Colors.blue);
  }

  void validateAliniDias({
    required BuildContext context,
    required int chatDay,
    required VoidCallback onAllowed,
  }) {
    if (chatDay <= 2) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => ModalDayChat(chatDay: chatDay),
      );
    } else {
      onAllowed();
    }
  }

  bool _esMio(Map<String, dynamic> msg) {
    if (_currentUserId == null) return false;
    final senderId = msg['sender_id'];
    if (senderId == null) return false;
    return senderId.toString() == _currentUserId.toString();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _wsConnectionSubscription?.cancel();
    _wsService.disconnect();
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===================== IA (usando ChatAiService) =====================

  Future<void> _analyzeChatForToday() async {
    if (_messages.isEmpty) return;

    setState(() => _analyzing = true);
    try {
      final day = DateTime.now();
      final dayStr = day.toIso8601String().substring(0, 10);

      final filtered = _messages.where((m) => m["fecha"] == dayStr).toList();
      final msgs = filtered.isNotEmpty ? filtered : _messages;

      final result = await _ai.analyze(
        mode: "today",
        day: day,
        partnerName: widget.nombre,
        currentUser: currentUser,
        messagesToSend: msgs,
      );

      if (!mounted) return;
      _showAnalysisModal(result);
    } catch (e) {
      _showToast("Error IA: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _showAnalysisModal(AnalysisResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    "Análisis IA - ${result.partnerName}",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade500,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.toneLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.overallSummary,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
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

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(cs),
      body: SafeArea(
        child: Column(
          children: [
            if (_analyzing)
              LinearProgressIndicator(
                minHeight: 2,
                color: cs.primary,
                backgroundColor: cs.surfaceVariant,
              ),
            Expanded(child: _buildBody(cs)),
            _buildInputArea(cs),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme cs) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 8),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AppBar(
            elevation: 0,
            backgroundColor: cs.surface.withOpacity(0.85),
            titleSpacing: 0,
            title: Row(
              children: [
                Hero(
                  tag: 'avatar_${widget.matchId}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(widget.foto),
                      onBackgroundImageError: (_, __) {},
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        "En línea",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              _buildActionButton(
                icon: Icons.date_range_rounded,
                tooltip: "Crear cita",
                onPressed: () async {
                  final created = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DdCreateActivityPage(
                        matchId: widget.matchId,
                        partnerName: widget.nombre,
                      ),
                    ),
                  );
                  if (created == true) _loadDates();
                },
              ),
              _buildMoreMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(icon, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMenu() {
    return PopupMenuButton<_ChatMenuAction>(
      tooltip: "Más opciones",
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (action) {
        switch (action) {
          case _ChatMenuAction.refreshDates:
            _loadDates();
            break;
          case _ChatMenuAction.historyWorld:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryLevelsPage(
                  matchId: widget.matchId,
                  partnerName: widget.nombre,
                ),
              ),
            );
            break;
          case _ChatMenuAction.ai:
            if (!_analyzing) _analyzeChatForToday();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _ChatMenuAction.refreshDates,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.refresh_rounded),
            title: Text("Recargar citas"),
          ),
        ),
        const PopupMenuItem(
          value: _ChatMenuAction.historyWorld,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.emoji_events_rounded),
            title: Text("History World"),
          ),
        ),
        PopupMenuItem(
          value: _ChatMenuAction.ai,
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text("Análisis IA"),
            subtitle: _analyzing ? const Text("Analizando...") : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loadingMessages) return const _ChatSkeleton();

    if (_messagesError != null) {
      return _ChatErrorState(message: _messagesError!, onRetry: _loadMessages);
    }

    if (_messages.isEmpty && _dates.isEmpty) {
      return _EmptyChatState(
        onCreateDate: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DdCreateActivityPage(
                matchId: widget.matchId,
                partnerName: widget.nombre,
              ),
            ),
          );
          if (created == true) _loadDates();
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: _calculateItemCount(),
      itemBuilder: (context, index) => _buildListItem(index, cs),
    );
  }

  // ✅ FIX CRÍTICO: ahora sí contamos el header de mensajes
  int _calculateItemCount() {
    int count = 0;

    if (_dates.isNotEmpty) {
      count += 1; // header "Próximas citas"
      count += _dates.length;
    }

    if (_messages.isNotEmpty) {
      count += 1; // header "Mensajes"  ✅ (ESTO FALTABA)
      count += _messages.length;
    }

    return count;
  }

  Widget _buildListItem(int index, ColorScheme cs) {
    final total = _calculateItemCount();
    final realIndex = total - 1 - index;
    int i = realIndex;

    // ---- DATES ----
    if (_dates.isNotEmpty) {
      if (i == 0) {
        return _buildSectionHeader("Próximas citas", Icons.event_rounded, cs);
      }
      i -= 1;

      if (i < _dates.length) {
        final d = _dates[i];
        final isCreator = d.statusUpper == "ACTIVO" && _currentUserId != null;

        return ChatDateCard(
          date: d,
          onConfirm: () => _confirmDate(d),
          onReject: () => _rejectDate(d),
          isCreator: isCreator,
          creatorName: isCreator ? "Tú" : widget.nombre,
        );
      }
      i -= _dates.length;
    }

    // ---- MESSAGES ----
    if (_messages.isNotEmpty) {
      if (i == 0) {
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: _buildSectionHeader("Mensajes", Icons.chat_rounded, cs),
        );
      }
      i -= 1;

      if (i < _messages.length) {
        final msg = _messages[i];
        final esMio = _esMio(msg);

        return _MessageBubble(
          message: msg["text"] as String,
          time: msg["hora"] as String,
          isMine: esMio,
          isRead: msg["is_read"] == true,
          senderName: esMio ? null : msg["autor"] as String,
          avatarUrl: esMio ? null : widget.foto,
        );
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: cs.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(height: 1, color: cs.primary.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.onSurface.withOpacity(0.1), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _buildInputButton(
                icon: Icons.videocam_rounded,
                onPressed: () {
                  validateAliniDias(
                    context: context,
                    chatDay: ChatDay,
                    onAllowed: _iniciarAliniVideoCall,
                  );
                },
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageCtrl,
                          decoration: InputDecoration(
                            hintText: "Escribe un mensaje...",
                            hintStyle: TextStyle(
                              color: cs.onSurface.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          textInputAction: TextInputAction.send,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_messageCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _messageCtrl.clear();
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Material(
                  color: _sendingMsg ? cs.surface : cs.primary,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _sendingMsg ? null : _sendMessage,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: _sendingMsg
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: cs.onPrimary,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(right: 8),
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }
}

// ================== MESSAGE BUBBLE ==================

class _MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMine;
  final bool isRead;
  final String? senderName;
  final String? avatarUrl;

  const _MessageBubble({
    required this.message,
    required this.time,
    required this.isMine,
    this.isRead = false,
    this.senderName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine && avatarUrl != null) ...[
            CircleAvatar(radius: 16, backgroundImage: NetworkImage(avatarUrl!)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMine
                    ? LinearGradient(
                        colors: [cs.primary, cs.primary.withOpacity(0.8)],
                      )
                    : null,
                color: isMine ? null : cs.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMine ? 20 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMine && senderName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        senderName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMine ? Colors.white : cs.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: isMine
                              ? Colors.white.withOpacity(0.7)
                              : cs.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 14,
                          color: isRead
                              ? Colors.blue.shade300
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================== STATES ==================

class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) {
        final isMine = index % 2 == 0;
        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMine ? 20 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 20),
              ),
            ),
            child: Container(
              width: isMine ? 200 : 180,
              height: 16,
              color: cs.surfaceContainerHighest,
            ),
          ),
        );
      },
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final VoidCallback onCreateDate;
  const _EmptyChatState({required this.onCreateDate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Inicia la conversación!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Envía un mensaje o propón una actividad para comenzar',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreateDate,
              icon: const Icon(Icons.event_rounded),
              label: const Text('Proponer actividad'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ChatErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Error al cargar mensajes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
