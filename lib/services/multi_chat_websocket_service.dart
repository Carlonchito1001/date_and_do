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

  bool _isDisposed = false;

  bool get isAnyConnected => _channels.isNotEmpty;

  void _emitEvent(Map<String, dynamic> event) {
    if (_isDisposed || _eventsCtrl.isClosed) return;
    _eventsCtrl.add(event);
  }

  void _emitConnection(Map<int, bool> connection) {
    if (_isDisposed || _connCtrl.isClosed) return;
    _connCtrl.add(connection);
  }

  Future<void> connectMatch(int matchId) async {
    if (_isDisposed) return;
    if (_channels.containsKey(matchId)) return;

    final accessToken = await _prefs.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available');
    }

    final uri = Uri.parse('$_baseWsUrl/match/$matchId/?token=$accessToken');
    final channel = WebSocketChannel.connect(uri);

    _channels[matchId] = channel;
    _emitConnection({matchId: true});

    _subs[matchId] = channel.stream.listen(
      (data) {
        if (_isDisposed) return;

        try {
          if (data is String) {
            final jsonMap = jsonDecode(data) as Map<String, dynamic>;

            jsonMap['__match_id'] ??=
                jsonMap['ddm_int_id'] ?? jsonMap['match_id'] ?? matchId;

            _emitEvent(jsonMap);
          }
        } catch (_) {
          // ignore parse errors
        }
      },
      onError: (_) {
        _emitConnection({matchId: false});
      },
      onDone: () {
        _emitConnection({matchId: false});
      },
      cancelOnError: false,
    );
  }

  Future<void> connectMany(Iterable<int> matchIds) async {
    if (_isDisposed) return;

    for (final id in matchIds) {
      await connectMatch(id);
    }
  }

  Future<void> disconnectMatch(int matchId) async {
    final sub = _subs.remove(matchId);
    if (sub != null) {
      await sub.cancel();
    }

    final channel = _channels.remove(matchId);
    if (channel != null) {
      await channel.sink.close();
    }

    _emitConnection({matchId: false});
  }

  Future<void> disconnectAll() async {
    final ids = _channels.keys.toList();
    for (final id in ids) {
      await disconnectMatch(id);
    }
  }

  /// Si quieres marcar read por WS (tu consumer soporta {"type":"read"}).
  void sendRead(int matchId) {
    if (_isDisposed) return;

    final ch = _channels[matchId];
    if (ch == null) return;

    ch.sink.add(jsonEncode({"type": "read"}));
  }

  void dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    final ids = _channels.keys.toList();
    for (final id in ids) {
      final sub = _subs.remove(id);
      if (sub != null) {
        await sub.cancel();
      }

      final channel = _channels.remove(id);
      if (channel != null) {
        await channel.sink.close();
      }
    }

    await _eventsCtrl.close();
    await _connCtrl.close();
  }
}
