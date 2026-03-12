import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';

class ChatWebSocketService {
  // ✅ En producción normalmente es wss (si tu backend está en https)
  static const String _baseWsUrl = 'wss://services.fintbot.pe/ws/dateanddo';

  WebSocketChannel? _channel;
  final SharedPreferencesService _prefs = SharedPreferencesService();

  int? _currentMatchId;
  StreamSubscription? _subscription;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> connect(int matchId) async {
    if (_currentMatchId == matchId && _channel != null && _isConnected) {
      return;
    }

    await disconnect();
    _currentMatchId = matchId;

    try {
      final accessToken = await _prefs.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('No access token available');
      }

      final uri = Uri.parse('$_baseWsUrl/match/$matchId/?token=$accessToken');

      _channel = WebSocketChannel.connect(uri);

      _isConnected = true;
      _connectionController.add(true);

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );
    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
      rethrow;
    }
  }

  // ✅ FIX #1: soporta String / List<int> / Uint8List
  void _onMessage(dynamic data) {
    try {
      String text;

      if (data is String) {
        text = data;
      } else if (data is List<int>) {
        text = utf8.decode(data);
      } else if (data is Uint8List) {
        text = utf8.decode(data);
      } else {
        return;
      }

      final jsonMap = jsonDecode(text);
      if (jsonMap is Map<String, dynamic>) {
        _messageController.add(jsonMap);
      }
    } catch (_) {
      // ignore parse errors
    }
  }

  void _onError(dynamic error) {
    _isConnected = false;
    _connectionController.add(false);
  }

  void _onDone() {
    _isConnected = false;
    _connectionController.add(false);
  }

  Future<void> sendMessage({
    required int matchId,
    required int receiverId,
    required String body,
  }) async {
    if (_channel == null || !_isConnected) {
      throw Exception('WebSocket not connected');
    }

    // ✅ Tu backend acepta {type:"message", body:"..."} (como en Postman)
    // Igual le mandamos match/receiver por si tu server lo usa
    final payload = {
      'type': 'message',
      'body': body,
      'match_id': matchId,
      'ddm_int_id': matchId,
      'receiver_id': receiverId,
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  Future<void> reconnect() async {
    if (_currentMatchId != null) {
      await connect(_currentMatchId!);
    }
  }

  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
    } catch (_) {}
    _subscription = null;

    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    _currentMatchId = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}