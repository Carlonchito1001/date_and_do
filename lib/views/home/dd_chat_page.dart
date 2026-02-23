import 'dart:convert';
import 'dart:ui';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/models/dd_date.dart';

import 'package:date_and_doing/views/home/discover/widgets/chat_date_card.dart';
import 'package:date_and_doing/views/history/history_levels.dart';
import 'package:date_and_doing/views/home/discover/widgets/dd_create_activity_page.dart';
import 'package:date_and_doing/widgets/modal_day_chat.dart';
import 'package:date_and_doing/widgets/modal_alini_unlocked.dart';

import 'dd_mock_data.dart';

class AnalysisResult {
  final String partnerName;
  final String overallTitle;
  final String toneLabel;
  final String overallSummary;
  final Map<String, double> scores;
  final List<String> positives;
  final String note;

  AnalysisResult({
    required this.partnerName,
    required this.overallTitle,
    required this.toneLabel,
    required this.overallSummary,
    required this.scores,
    required this.positives,
    required this.note,
  });
}

int ChatDay = 4;

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

  final _api = ApiService();

  final String currentUser = "Juan";
  final List<Map<String, dynamic>> _messages = [];

  bool _sendingMsg = false;

  bool _loadingDates = true;
  List<DdDate> _dates = [];

  bool _analyzing = false;
  bool _shownAliniUnlockedThisSession = false;

  static const String _iaUrl =
      'https://n8n.fintbot.pe/webhook/be664844-a373-4376-888a-170049d6f2d5';

  static const String _defaultIaNote =
      "Este análisis es generado por IA y está basado en patrones de comunicación. "
      "Usa tu propio criterio para tomar decisiones sobre tus conexiones.";

  @override
  void initState() {
    super.initState();
    _loadDates();
    _loadMessages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowAliniUnlocked();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
      _showToast("❌ Error confirmando: \$e", Colors.red);
    }
  }

  Future<void> _rejectDate(DdDate d) async {
    try {
      await _api.rejectDate(d.id);
      await _loadDates();
      _showToast("✅ Cita rechazada", Colors.orange);
    } catch (e) {
      _showToast("❌ Error rechazando: \$e", Colors.red);
    }
  }

  void _showToast(String msg, Color color) {
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

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sendingMsg) return;

    setState(() => _sendingMsg = true);

    try {
      await _api.sendMessage(
        matchId: widget.matchId,
        receiverId: widget.otherUserId,
        body: text,
      );

      _messageCtrl.clear();
      await _loadMessages();
      _scrollToBottom();

      if (!mounted) return;
      setState(() => _sendingMsg = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sendingMsg = false);
      _showToast("❌ Error enviando: \$e", Colors.red);
    }
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

    if (wantsTry == true) {
      _iniciarAliniVideoCall();
    }
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
    return msg["sender_id"] == _currentUserId;
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loadingMessages = true;
      _messagesError = null;
    });

    try {
      _currentUserId ??= await SharedPreferencesService().getUserIdOrThrow();

      final rawMessages = await _api.getMessagesByMatch(widget.matchId);

      final filtered = rawMessages
          .where((m) => m["ddmsg_txt_status"] == "ACTIVO")
          .toList();

      filtered.sort((a, b) {
        final da = DateTime.parse(a["ddmsg_timestamp_datecreate"].toString());
        final db = DateTime.parse(b["ddmsg_timestamp_datecreate"].toString());
        return da.compareTo(db);
      });

      if (!mounted) return;

      setState(() {
        _messages
          ..clear()
          ..addAll(
            filtered.map((m) {
              final createdAt = DateTime.parse(
                m["ddmsg_timestamp_datecreate"].toString(),
              );

              return {
                "id": m["ddmsg_int_id"],
                "sender_id": m["use_int_sender"],
                "autor": (m["use_int_sender"] == _currentUserId)
                    ? "Yo"
                    : widget.nombre,
                "text": m["ddmsg_txt_body"] ?? "",
                "hora": TimeOfDay.fromDateTime(createdAt).format(context),
                "fecha": createdAt.toIso8601String().substring(0, 10),
                "is_read": m["ddmsg_bool_read"] == true,
              };
            }),
          );
        _loadingMessages = false;
      });

      // Scroll al final después de cargar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Marcar mensajes no leídos como leídos
      await _markUnreadMessagesAsRead(filtered);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messagesError = e.toString();
        _loadingMessages = false;
      });
    }
  }

  Future<void> _markUnreadMessagesAsRead(List<Map<String, dynamic>> messages) async {
    // Verificar si hay mensajes no leídos donde el usuario actual es el receptor
    final hasUnread = messages.any((m) {
      final isRead = m["ddmsg_bool_read"] == true;
      final receiverId = m["use_int_receiver"];
      return !isRead && receiverId == _currentUserId;
    });

    // Si hay mensajes no leídos, marcar todos los del match como leídos
    if (hasUnread) {
      try {
        await _api.markMessagesAsRead(widget.matchId);
      } catch (e) {
        // Silenciar errores - no es crítico
        debugPrint("Error marking messages as read for match ${widget.matchId}: $e");
      }
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
    if (_loadingMessages) {
      return const _ChatSkeleton();
    }

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _calculateItemCount(),
      itemBuilder: (context, index) {
        return _buildListItem(index, cs);
      },
    );
  }

  int _calculateItemCount() {
    int count = 0;
    if (_dates.isNotEmpty) count += _dates.length + 1; // +1 for header
    if (_messages.isNotEmpty) count += _messages.length;
    return count;
  }

  Widget _buildListItem(int index, ColorScheme cs) {
    int currentIndex = 0;

    // Fechas primero
    if (_dates.isNotEmpty) {
      if (index == 0) {
        return _buildSectionHeader("Próximas citas", Icons.event_rounded, cs);
      }
      currentIndex++;

      if (index <= _dates.length) {
        final d = _dates[index - 1];
        // Determinar si el usuario actual es el creador de la cita
        // Tu backend debe incluir el creator_id para esto
        // Por ahora usamos una lógica simple
        final isCreator = d.statusUpper == "ACTIVO" && _currentUserId != null;
        
        return ChatDateCard(
          date: d,
          onConfirm: () => _confirmDate(d),
          onReject: () => _rejectDate(d),
          isCreator: isCreator,
          creatorName: isCreator ? "Tú" : widget.nombre,
        );
      }
      currentIndex += _dates.length;
    }

    // Mensajes
    if (_messages.isNotEmpty) {
      final msgIndex = index - currentIndex;
      if (msgIndex == 0) {
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: _buildSectionHeader("Mensajes", Icons.chat_rounded, cs),
        );
      }

      final msg = _messages[msgIndex - 1];
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
            child: Container(
              height: 1,
              color: cs.primary.withOpacity(0.2),
            ),
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

  // Métodos de análisis IA (sin cambios significativos)
  String _buildConversationText(List<Map<String, dynamic>> msgs) {
    final buffer = StringBuffer();
    for (final m in msgs) {
      final String hora = (m["hora"] ?? "") as String;
      final String autor = (m["autor"] ?? "") as String;
      final String text = (m["text"] ?? "") as String;
      buffer.writeln("[\$hora] \$autor:");
      buffer.writeln(text);
      buffer.writeln();
    }
    return buffer.toString();
  }

  double _normalizePercent(dynamic raw) {
    double v;
    if (raw is num) {
      v = raw.toDouble();
    } else {
      v = double.tryParse(raw.toString()) ?? 0.0;
    }
    if (v <= 1.0) v *= 100.0;
    if (v < 0) v = 0;
    if (v > 100) v = 100;
    return v;
  }

  Future<void> _analyzeChatForToday() async {
    if (_messages.isEmpty) return;

    setState(() => _analyzing = true);

    final day = DateTime.now();
    final dayStr = day.toIso8601String().substring(0, 10);

    final filtered = _messages.where((m) => m["fecha"] == dayStr).toList();
    final msgs = filtered.isNotEmpty ? filtered : _messages;

    final payload = {
      "mode": "today",
      "date": dayStr,
      "partner_name": widget.nombre,
      "current_user": currentUser,
      "conversation_text": _buildConversationText(msgs),
      "messages_raw": msgs
          .map(
            (m) => {
              "author": m["autor"],
              "text": m["text"],
              "time": m["hora"],
              "date": m["fecha"],
            },
          )
          .toList(),
    };

    try {
      final resp = await http.post(
        Uri.parse(_iaUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final result =
            _parseAnalysisResult(resp.body, widget.nombre) ??
            _fallbackAnalysis(resp.body, widget.nombre);
        _showAnalysisModal(result);
      } else {
        _showToast("IA error \${resp.statusCode}", Colors.red);
      }
    } catch (e) {
      _showToast("Error IA: \$e", Colors.red);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  AnalysisResult? _parseAnalysisResult(String body, String partnerName) {
    try {
      dynamic decoded = jsonDecode(body);
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is! Map<String, dynamic>) return null;
      final map = decoded;

      if (map.length == 1 && map.containsKey("output")) {
        final String output = map["output"]?.toString() ?? "";
        if (output.isEmpty) return null;
        return _parseFromSingleOutput(output, partnerName);
      }

      final overallTitle = (map["overall_title"] ?? "Evaluación General")
          .toString();
      final toneLabel = (map["overall_label"] ?? map["tone"] ?? "Análisis")
          .toString();
      final overallSummary = (map["overall_summary"] ?? map["summary"] ?? "")
          .toString();

      final scoresRaw = map["scores"] ?? map["indicadores"];
      final Map<String, double> scores = {};
      if (scoresRaw is Map) {
        scoresRaw.forEach((key, value) {
          if (value != null) scores[key.toString()] = _normalizePercent(value);
        });
      }

      final posRaw =
          map["positives"] ?? map["aspects_positive"] ?? map["positivos"];
      final List<String> positives = [];
      if (posRaw is List) positives.addAll(posRaw.map((e) => e.toString()));

      final note = (map["note"] ?? _defaultIaNote).toString();

      return AnalysisResult(
        partnerName: partnerName,
        overallTitle: overallTitle,
        toneLabel: toneLabel,
        overallSummary: overallSummary,
        scores: scores,
        positives: positives,
        note: note,
      );
    } catch (_) {
      return null;
    }
  }

  AnalysisResult _parseFromSingleOutput(String output, String partnerName) {
    final lines = output
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final Map<String, double> scores = {};
    final List<String> positives = [];
    double? probAvance;
    String overallSummary = "";

    final RegExp percentRegex = RegExp(r'(\d+)\s*%');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      line = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');

      String label = "";
      String rest = line;
      final parts = line.split(':');
      if (parts.length >= 2) {
        label = parts[0].trim();
        rest = parts.sublist(1).join(':').trim();
      }

      double? pct;
      final match = percentRegex.firstMatch(rest);
      if (match != null) {
        pct = double.tryParse(match.group(1)!);
      }
      if (pct != null) {
        final key = label.isEmpty ? 'Indicador \${i + 1}' : label;
        scores[key] = _normalizePercent(pct);
        if (label.toLowerCase().contains("probabilidad de avance")) {
          probAvance = _normalizePercent(pct);
        }
      }

      final cleanRest = rest
          .replaceAll(percentRegex, '')
          .replaceAll('()', '')
          .trim();
      if (cleanRest.isNotEmpty) positives.add(cleanRest);
      if (i == 0) overallSummary = cleanRest;
    }

    String toneLabel;
    final p = probAvance ?? 70;
    if (p >= 80)
      toneLabel = "Muy positivo";
    else if (p >= 60)
      toneLabel = "Positivo";
    else if (p >= 40)
      toneLabel = "Neutral / con matices";
    else
      toneLabel = "Bajo / Riesgo";

    return AnalysisResult(
      partnerName: partnerName,
      overallTitle: "Evaluación de conversación",
      toneLabel: toneLabel,
      overallSummary: overallSummary,
      scores: scores,
      positives: positives,
      note: _defaultIaNote,
    );
  }

  AnalysisResult _fallbackAnalysis(String body, String partnerName) {
    return AnalysisResult(
      partnerName: partnerName,
      overallTitle: "Análisis general",
      toneLabel: "Resumen IA",
      overallSummary: body,
      scores: const {},
      positives: const [],
      note: _defaultIaNote,
    );
  }

  void _showAnalysisModal(AnalysisResult result) {
    // Modal de análisis (simplificado para mantener el archivo manejable)
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
                    "Análisis IA - \${result.partnerName}",
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

// ================== CHAT SKELETON ==================

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

// ================== EMPTY CHAT STATE ==================

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

// ================== CHAT ERROR STATE ==================

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
