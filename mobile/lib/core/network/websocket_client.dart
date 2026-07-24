import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Low-level WebSocket transport.
///
/// Manages a single channel: connect → stream events → send frames → close.
/// This class is intentionally thin — all lifecycle logic (heartbeat, backoff,
/// reconnect, auth) lives in [SocketService].
class WebSocketClient {
  WebSocketClient({required this.baseWsUrl});

  final String baseWsUrl;

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;

  bool get isConnected => _channel != null;

  /// Opens a channel to [path] (relative to [baseWsUrl]) and returns a
  /// broadcast stream of decoded JSON frames.
  ///
  /// Throws if the underlying channel cannot be created synchronously (URI
  /// parse error). Network-level failures surface as stream errors.
  Stream<Map<String, dynamic>> connect(String path) {
    // Always start fresh.
    _controller?.close();
    _controller = StreamController<Map<String, dynamic>>.broadcast();

    final uri = Uri.parse('$baseWsUrl$path');
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (raw) {
        try {
          _controller?.add(
            jsonDecode(raw as String) as Map<String, dynamic>,
          );
        } catch (_) {
          // Silently drop malformed frames.
        }
      },
      onError: (Object err) => _controller?.addError(err),
      onDone: () {
        _channel = null;
        _controller?.close();
      },
      cancelOnError: false,
    );

    return _controller!.stream;
  }

  /// Sends a JSON-encoded frame. No-ops when not connected.
  void send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (_) {
      // Channel may be closed between the null-check and the add.
    }
  }

  /// Closes the channel gracefully.
  Future<void> disconnect() async {
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    await _controller?.close();
    _controller = null;
  }
}
