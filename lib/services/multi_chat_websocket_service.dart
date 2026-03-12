import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';

/// Maneja múltiples WS (uno por matchId) y emite todos los eventos en un solo stream.
class MultiChatWebSocketService {
  static const String _baseWsUrl = 'ws://services.fintbot.pe/ws/dateanddo';

  final SharedPreferencesService _prefs = SharedPreferencesService();

  final Map<int, WebSocketChannel> _channels = {};
  final Map<int, StreamSubscription> _subs = {};

  final _eventsCtrl = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _eventsCtrl.stream;

  final _connCtrl = StreamController<Map<int, bool>>.broadcast();
  Stream<Map<int, bool>> get connections => _connCtrl.stream;

  bool get isAnyConnected => _channels.isNotEmpty;

  Future<void> connectMatch(int matchId) async {
    if (_channels.containsKey(matchId)) return;

    final accessToken = await _prefs.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available');
    }

    final uri = Uri.parse('$_baseWsUrl/match/$matchId/?token=$accessToken');
    final channel = WebSocketChannel.connect(uri);

    _channels[matchId] = channel;
    _connCtrl.add({matchId: true});

    _subs[matchId] = channel.stream.listen(
      (data) {
        try {
          if (data is String) {
            final jsonMap = jsonDecode(data) as Map<String, dynamic>;

            // Normaliza el matchId aunque el payload no lo incluya siempre.
            jsonMap['__match_id'] ??= jsonMap['ddm_int_id'] ?? jsonMap['match_id'] ?? matchId;

            _eventsCtrl.add(jsonMap);
          }
        } catch (_) {
          // ignore parse errors
        }
      },
      onError: (_) {
        _connCtrl.add({matchId: false});
      },
      onDone: () {
        _connCtrl.add({matchId: false});
        // Deja que el caller decida si reconecta.
      },
    );
  }

  Future<void> connectMany(Iterable<int> matchIds) async {
    for (final id in matchIds) {
      await connectMatch(id);
    }
  }

  Future<void> disconnectMatch(int matchId) async {
    await _subs[matchId]?.cancel();
    _subs.remove(matchId);

    await _channels[matchId]?.sink.close();
    _channels.remove(matchId);

    _connCtrl.add({matchId: false});
  }

  Future<void> disconnectAll() async {
    final ids = _channels.keys.toList();
    for (final id in ids) {
      await disconnectMatch(id);
    }
  }

  /// Si quieres marcar read por WS (tu consumer soporta {"type":"read"}).
  void sendRead(int matchId) {
    final ch = _channels[matchId];
    if (ch == null) return;
    ch.sink.add(jsonEncode({"type": "read"}));
  }

  void dispose() {
    disconnectAll();
    _eventsCtrl.close();
    _connCtrl.close();
  }
}