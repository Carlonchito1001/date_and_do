import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:date_and_doing/models/analysis_result.dart';

class ChatAiService {
  final String iaUrl;

  ChatAiService({
    required this.iaUrl,
  });

  static const String defaultNote =
      "Este análisis es generado por IA y está basado en patrones de "
      "comunicación. Usa tu propio criterio para tomar decisiones sobre tus "
      "conexiones.";

  // ===== Public API =====

  Future<AnalysisResult> analyze({
    required String mode, // "today" | "by_day"
    required DateTime day,
    required String partnerName,
    required String currentUser,
    required List<Map<String, dynamic>> messagesToSend,
  }) async {
    final dayStr = day.toIso8601String().substring(0, 10);
    final conversationText = _buildConversationText(messagesToSend);

    final payload = {
      "mode": mode,
      "date": dayStr,
      "partner_name": partnerName,
      "current_user": currentUser,
      "conversation_text": conversationText,
      "messages_raw": messagesToSend
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

    final resp = await http.post(
      Uri.parse(iaUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception("IA error ${resp.statusCode}: ${resp.body}");
    }

    return _parseAnalysisResult(resp.body, partnerName) ??
        _fallbackAnalysis(resp.body, partnerName);
  }

  // ===== Helpers =====

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

  /// Caso que tu n8n devuelve: {"output": "1. ... (85%)\n2. ... (90%) ..."}
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

      final cleanRest =
          rest.replaceAll(percentRegex, '').replaceAll('()', '').trim();

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
      note: defaultNote,
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

      // JSON más estructurado (si lo cambias en el futuro)
      final overallTitle =
          (map["overall_title"] ?? "Evaluación General").toString();
      final toneLabel =
          (map["overall_label"] ?? map["tone"] ?? "Análisis").toString();
      final overallSummary =
          (map["overall_summary"] ?? map["summary"] ?? "").toString();

      final scoresRaw = map["scores"] ?? map["indicadores"];
      final Map<String, double> scores = {};
      if (scoresRaw is Map) {
        scoresRaw.forEach((k, v) {
          if (v != null) scores[k.toString()] = _normalizePercent(v);
        });
      }

      final posRaw =
          map["positives"] ?? map["aspects_positive"] ?? map["positivos"];
      final List<String> positives = [];
      if (posRaw is List) positives.addAll(posRaw.map((e) => e.toString()));

      final note = (map["note"] ?? defaultNote).toString();

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
    final txt = body.replaceAll(r'\n', '\n').replaceAll(r'\t', '  ');
    return AnalysisResult(
      partnerName: partnerName,
      overallTitle: "Análisis general",
      toneLabel: "Resumen IA",
      overallSummary: txt,
      scores: const {},
      positives: const [],
      note: defaultNote,
    );
  }
}

