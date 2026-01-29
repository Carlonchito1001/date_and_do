import 'dart:convert';
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

class _DdChatPageState extends State<DdChatPage> {
  int? _currentUserId;
  bool _loadingMessages = true;
  String? _messagesError;
  final TextEditingController _messageCtrl = TextEditingController();

  final _api = ApiService();

  final String currentUser = "Juan";
  final List<Map<String, dynamic>> _messages = [];

  bool _sendingMsg = false;

  bool _loadingDates = true;
  String? _datesError;
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

  Future<void> _loadDates() async {
    setState(() {
      _loadingDates = true;
      _datesError = null;
    });

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
      setState(() {
        _datesError = e.toString();
        _loadingDates = false;
      });
    }
  }

  Future<void> _confirmDate(DdDate d) async {
    try {
      await _api.confirmDate(d.id);
      await _loadDates();
      _toast("✅ Cita confirmada");
    } catch (e) {
      _toast("❌ Error confirmando: $e");
    }
  }

  Future<void> _rejectDate(DdDate d) async {
    try {
      await _api.rejectDate(d.id);
      await _loadDates();
      _toast("✅ Cita rechazada");
    } catch (e) {
      _toast("❌ Error rechazando: $e");
    }
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

      // 👉 fuente de verdad: backend
      await _loadMessages();

      if (!mounted) return;
      setState(() => _sendingMsg = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sendingMsg = false);
      _toast("❌ Error enviando: $e");
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Iniciando Alini Video Call...")),
    );
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

  String _buildConversationText(List<Map<String, dynamic>> msgs) {
    final buffer = StringBuffer();

    for (final m in msgs) {
      final String hora = (m["hora"] ?? "") as String;
      final String autor = (m["autor"] ?? "") as String;
      final String text = (m["text"] ?? "") as String;

      buffer.writeln("[$hora] $autor:");
      buffer.writeln(text);
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _extractAnalysis(String body) {
    try {
      dynamic decoded = jsonDecode(body);

      if (decoded is String) decoded = jsonDecode(decoded);

      if (decoded is Map<String, dynamic>) {
        final map = decoded;
        final txt =
            map["analysis"] ??
            map["output"] ??
            map["resumen"] ??
            map["message"];
        if (txt is String) {
          return txt.replaceAll(r'\n', '\n').replaceAll(r'\t', '  ');
        }
      }

      return body.replaceAll(r'\n', '\n').replaceAll(r'\t', '  ');
    } catch (_) {
      return body.replaceAll(r'\n', '\n').replaceAll(r'\t', '  ');
    }
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
              };
            }),
          );
        _loadingMessages = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messagesError = e.toString();
        _loadingMessages = false;
      });
    }
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
        final key = label.isEmpty ? 'Indicador ${i + 1}' : label;
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
    if (p >= 80) {
      toneLabel = "Muy positivo";
    } else if (p >= 60) {
      toneLabel = "Positivo";
    } else if (p >= 40) {
      toneLabel = "Neutral / con matices";
    } else {
      toneLabel = "Bajo / Riesgo";
    }

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

  AnalysisResult _fallbackAnalysis(String body, String partnerName) {
    final txt = _extractAnalysis(body);
    return AnalysisResult(
      partnerName: partnerName,
      overallTitle: "Análisis general",
      toneLabel: "Resumen IA",
      overallSummary: txt,
      scores: const {},
      positives: const [],
      note: _defaultIaNote,
    );
  }

  void _showAnalysisModal(AnalysisResult result) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outline.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: cs.primaryContainer.withOpacity(
                                0.95,
                              ),
                              child: Icon(
                                Icons.lightbulb_outline,
                                color: cs.onPrimaryContainer,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Análisis Fint IA",
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Conversación con ${result.partnerName}",
                                    style: textTheme.bodySmall?.copyWith(
                                      color: cs.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Evaluación General",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                result.toneLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                result.overallSummary,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (result.scores.isNotEmpty) ...[
                          Text(
                            "Análisis de Personalidad",
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...result.scores.entries.map(
                            (e) => _buildScoreRow(
                              label: e.key,
                              value: e.value,
                              cs: cs,
                              textTheme: textTheme,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (result.positives.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade500,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Aspectos Positivos",
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...result.positives.map(
                            (p) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green.shade500,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      p,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cs.primary.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            "Nota: ${result.note}",
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text("Entendido"),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildScoreRow({
    required String label,
    required double value,
    required ColorScheme cs,
    required TextTheme textTheme,
  }) {
    final percentText = "${value.toStringAsFixed(0)}%";
    final progressValue = value / 100.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                ),
              ),
              Text(
                percentText,
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: cs.surfaceVariant.withOpacity(0.7),
              valueColor: AlwaysStoppedAnimation<Color>(
                cs.primary.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
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
        _toast("IA error ${resp.statusCode}");
      }
    } catch (e) {
      _toast("Error IA: $e");
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.foto),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: widget.nombre,
                    child: Text(
                      widget.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    "Match #${widget.matchId}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Crear cita",
            icon: const Icon(Icons.date_range),
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
          PopupMenuButton<_ChatMenuAction>(
            tooltip: "Más opciones",
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
                  leading: Icon(Icons.emoji_events),
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
          ),
        ],
      ),
      body: Column(
        children: [
          if (_analyzing)
            LinearProgressIndicator(
              minHeight: 2,
              color: cs.primary,
              backgroundColor: cs.surfaceVariant,
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                if (_loadingDates) const LinearProgressIndicator(minHeight: 2),
                if (_datesError != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: cs.onErrorContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Error cargando citas: $_datesError",
                            style: TextStyle(
                              color: cs.onErrorContainer,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: _loadDates,
                          child: Text(
                            "Reintentar",
                            style: TextStyle(
                              color: cs.onErrorContainer,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ..._dates.map(
                  (d) => ChatDateCard(
                    date: d,
                    onConfirm: () => _confirmDate(d),
                    onReject: () => _rejectDate(d),
                  ),
                ),
                const SizedBox(height: 6),
                ..._messages.map((msg) {
                  final esMio = _esMio(msg);
                  final bubbleColor = esMio
                      ? cs.primary.withOpacity(0.15)
                      : cs.surfaceVariant;
                  final textColor = cs.onSurface;

                  return Align(
                    alignment: esMio
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(esMio ? 16 : 4),
                          bottomRight: Radius.circular(esMio ? 4 : 16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: esMio
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!esMio)
                            Text(
                              msg["autor"] as String,
                              style: textTheme.labelSmall?.copyWith(
                                color: cs.onSurface.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (!esMio) const SizedBox(height: 2),
                          Text(
                            msg["text"] as String,
                            style: textTheme.bodyMedium?.copyWith(
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            msg["hora"] as String,
                            style: textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      validateAliniDias(
                        context: context,
                        chatDay: ChatDay,
                        onAllowed: _iniciarAliniVideoCall,
                      );
                    },
                    icon: const Icon(Icons.videocam),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      decoration: const InputDecoration(
                        hintText: "Escribe un mensaje...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: _sendingMsg
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    color: cs.primary,
                    onPressed: _sendingMsg ? null : _sendMessage,
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
