import 'dart:async';

import 'package:namichat_lite/core/network/websocket_client.dart';

/// Connection lifecycle states for a single chat channel.
enum SocketStatus {
  idle,
  connecting,
  connected,
  reconnecting,
  disconnected,
  authError,    // closed with 4001 — token rejected
  forbidden,   // closed with 4003 — not a member
}

/// Typed WebSocket event — sealed via [WsEventType].
enum WsEventType { message, typing, presence, pong, unknown }

class WsEvent {
  const WsEvent({required this.type, required this.payload});

  final WsEventType type;
  final Map<String, dynamic> payload;

  factory WsEvent.fromJson(Map<String, dynamic> json) {
    final raw = json['event'] as String?;
    final type = switch (raw) {
      'message'  => WsEventType.message,
      'typing'   => WsEventType.typing,
      'presence' => WsEventType.presence,
      'pong'     => WsEventType.pong,
      _          => WsEventType.unknown,
    };
    return WsEvent(type: type, payload: json);
  }
}

/// Manages the full lifecycle of a **single** chat-room WebSocket connection.
///
/// Responsibilities:
/// - JWT-authenticated connect (`/ws/{chatId}?token=…`)
/// - Heartbeat ping every [pingInterval] with [pingTimeout] liveness check
/// - Exponential-backoff automatic reconnection (up to [maxRetries])
/// - Token refresh callback before each reconnect attempt
/// - Typed event stream exposed as [events]
/// - Graceful close via [dispose]
///
/// One [SocketService] is created per chat room and lives for the lifetime of
/// the [ChatNotifier] that owns it.
class SocketService {
  SocketService({
    required WebSocketClient transport,
    required String chatId,
    required Future<String?> Function() getToken,
    this.pingInterval = const Duration(seconds: 25),
    this.pingTimeout = const Duration(seconds: 10),
    this.maxRetries = 6,
  })  : _transport = transport,
        _chatId = chatId,
        _getToken = getToken;

  final WebSocketClient _transport;
  final String _chatId;
  final Future<String?> Function() _getToken;

  final Duration pingInterval;
  final Duration pingTimeout;
  final int maxRetries;

  // Outward-facing streams.
  final _statusCtrl = StreamController<SocketStatus>.broadcast();
  final _eventCtrl = StreamController<WsEvent>.broadcast();

  Stream<SocketStatus> get statusStream => _statusCtrl.stream;
  Stream<WsEvent> get events => _eventCtrl.stream;

  SocketStatus _status = SocketStatus.idle;
  SocketStatus get status => _status;

  StreamSubscription<Map<String, dynamic>>? _channelSub;
  Timer? _pingTimer;
  Timer? _pongTimeoutTimer;
  bool _pongReceived = false;

  int _retryCount = 0;
  Timer? _retryTimer;
  bool _disposed = false;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Initiates the connection. Safe to call multiple times (no-op if already
  /// connected or connecting).
  Future<void> connect() async {
    if (_disposed) return;
    if (_status == SocketStatus.connecting ||
        _status == SocketStatus.connected) return;
    _retryCount = 0;
    await _doConnect();
  }

  /// Sends a raw JSON frame. No-op when not connected.
  void send(Map<String, dynamic> frame) {
    if (_status == SocketStatus.connected) {
      _transport.send(frame);
    }
  }

  /// Permanently closes the connection and cancels all timers.
  /// Call this when the owning notifier is disposed.
  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    _stopHeartbeat();
    await _channelSub?.cancel();
    await _transport.disconnect();
    _setStatus(SocketStatus.disconnected);
    await _statusCtrl.close();
    await _eventCtrl.close();
  }

  // ── Connection logic ────────────────────────────────────────────────────

  Future<void> _doConnect() async {
    if (_disposed) return;

    _setStatus(
      _retryCount == 0 ? SocketStatus.connecting : SocketStatus.reconnecting,
    );

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      _setStatus(SocketStatus.authError);
      return;
    }

    try {
      await _channelSub?.cancel();
      _stopHeartbeat();

      final path = '/ws/$_chatId?token=$token';
      final stream = _transport.connect(path);

      _channelSub = stream.listen(
        _onFrame,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _setStatus(SocketStatus.connected);
      _retryCount = 0;
      _startHeartbeat();
    } catch (e) {
      _onError(e);
    }
  }

  // ── Frame handling ──────────────────────────────────────────────────────

  void _onFrame(Map<String, dynamic> json) {
    if (_disposed) return;

    final event = WsEvent.fromJson(json);

    if (event.type == WsEventType.pong) {
      _pongReceived = true;
      _pongTimeoutTimer?.cancel();
      return; // Don't forward pong to feature layer.
    }

    _eventCtrl.add(event);
  }

  void _onError(Object error) {
    if (_disposed) return;

    final closeCode = _maybeExtractCloseCode(error);
    if (closeCode == 4001) {
      _setStatus(SocketStatus.authError);
      return;
    }
    if (closeCode == 4003) {
      _setStatus(SocketStatus.forbidden);
      return;
    }

    _stopHeartbeat();

    _setStatus(SocketStatus.disconnected);
    _scheduleRetry();
  }


  void _onDone() {
    if (_disposed) return;
    _stopHeartbeat();

    final closeCode = _transport.isConnected ? null : _readCloseCode();
    if (closeCode == 4001) {
      _setStatus(SocketStatus.authError);
      return;
    }
    if (closeCode == 4003) {
      _setStatus(SocketStatus.forbidden);
      return;
    }

    _setStatus(SocketStatus.disconnected);
    _scheduleRetry();
  }

  // Try to detect app-level close codes (4001 / 4003).
  // `web_socket_channel` may expose close details depending on the underlying
  // implementation; we keep this best-effort and fall back to `null`.
  //
  // NOTE: The `web_socket_channel` package does not expose close codes
  // consistently across platforms. If reliable close-code detection is
  // required, consider switching to a lower-level WebSocket client or
  // wrapping the channel to capture close events.
  int? _readCloseCode() {
    return null;
  }

  /// Try to detect app-level close codes from error messages.
  ///
  /// This is a best-effort heuristic: some WebSocket implementations embed
  /// the close code in the error message, while others do not expose it at
  /// all. Returns `4001` for auth failures, `4003` for membership
  /// violations, or `null` when the code cannot be determined.
  int? _maybeExtractCloseCode(Object error) {
    final text = error.toString();
    if (text.contains('4001')) return 4001;
    if (text.contains('4003')) return 4003;
    return null;
  }


  // ── Heartbeat ───────────────────────────────────────────────────────────

  void _startHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) => _sendPing());
  }

  void _stopHeartbeat() {
    _pingTimer?.cancel();
    _pongTimeoutTimer?.cancel();
    _pingTimer = null;
    _pongTimeoutTimer = null;
  }

  void _sendPing() {
    if (_status != SocketStatus.connected) return;

    _pongReceived = false;
    _transport.send({'type': 'ping'});

    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = Timer(pingTimeout, () {
      if (!_pongReceived && !_disposed) {
        // Server didn't pong in time — treat as dead connection.
        _stopHeartbeat();
        _transport.disconnect();
        _setStatus(SocketStatus.disconnected);
        _scheduleRetry();
      }
    });
  }

  // ── Reconnect with exponential backoff ──────────────────────────────────

  void _scheduleRetry() {
    if (_disposed) return;
    if (_retryCount >= maxRetries) {
      _setStatus(SocketStatus.disconnected);
      return;
    }

    // Backoff: 1 s, 2 s, 4 s, 8 s, 16 s, 32 s (capped).
    final delay = Duration(seconds: _clamp(1 << _retryCount, 1, 32));
    _retryCount++;

    _retryTimer?.cancel();
    _retryTimer = Timer(delay, _doConnect);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _setStatus(SocketStatus s) {
    if (_disposed && s != SocketStatus.disconnected) return;
    _status = s;
    if (!_statusCtrl.isClosed) _statusCtrl.add(s);
  }

  static int _clamp(int v, int min, int max) =>
      v < min ? min : (v > max ? max : v);
}
