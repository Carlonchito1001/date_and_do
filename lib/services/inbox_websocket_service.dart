// lib/services/inbox_websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class InboxWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  bool get isConnected => _channel != null;

  Future<void> connect({required String wsBaseUrl, required String token}) async {
    disconnect();

    final uri = Uri.parse("$wsBaseUrl/ws/dateanddo/inbox/?token=$token");
    _channel = WebSocketChannel.connect(uri);

    _sub = _channel!.stream.listen((event) {
      try {
        final decoded = jsonDecode(event);
        if (decoded is Map<String, dynamic>) {
          _controller.add(decoded);
        }
      } catch (_) {}
    }, onDone: () {
      disconnect();
    }, onError: (_) {
      disconnect();
    });
  }

  void disconnect() {
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close(status.goingAway);
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}