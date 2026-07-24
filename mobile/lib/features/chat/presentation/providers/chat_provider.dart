import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:namichat_lite/core/di/injection_container.dart';
import 'package:namichat_lite/core/network/socket_service.dart';
import 'package:namichat_lite/features/chat/domain/entities/message.dart';
import 'package:namichat_lite/features/chat/domain/usecases/fetch_messages_usecase.dart';
import 'package:namichat_lite/features/chat/presentation/providers/chat_state.dart';

// ---------------------------------------------------------------------------
// Provider — one notifier per chat room, auto-disposed when the page pops.
// The SocketService lifetime is managed by socketServiceProvider (DI).
// ---------------------------------------------------------------------------

final chatNotifierProvider = StateNotifierProvider.autoDispose
    .family<ChatNotifier, ChatState, String>((ref, chatId) {
  final authState = ref.watch(authNotifierProvider);
  final currentUserId = authState.user?.id ?? '';

  return ChatNotifier(
    chatId: chatId,
    currentUserId: currentUserId,
    socketService: ref.watch(socketServiceProvider(chatId)),
    fetchMessages: ref.watch(fetchMessagesUseCaseProvider),
  );
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier({
    required String chatId,
    required String currentUserId,
    required SocketService socketService,
    required FetchMessagesUseCase fetchMessages,
  })  : _socket = socketService,
        _fetchMessages = fetchMessages,
        super(ChatState(chatId: chatId, currentUserId: currentUserId)) {
    _init();
  }

  final SocketService _socket;
  final FetchMessagesUseCase _fetchMessages;

  StreamSubscription<SocketStatus>? _statusSub;
  StreamSubscription<WsEvent>? _eventSub;
  Timer? _typingTimer;
  bool _isTyping = false;

  // ── Bootstrap ────────────────────────────────────────────────────────────

  Future<void> _init() async {
    _statusSub = _socket.statusStream.listen(_onSocketStatus);
    _eventSub  = _socket.events.listen(_onEvent);
    await _loadHistory();
    await _socket.connect();
  }

  // ── Socket status mirror ─────────────────────────────────────────────────

  void _onSocketStatus(SocketStatus s) {
    if (!mounted) return;
    state = state.copyWith(socketStatus: s);
  }

  // ── Event dispatch ───────────────────────────────────────────────────────

  void _onEvent(WsEvent event) {
    if (!mounted) return;
    switch (event.type) {
      case WsEventType.message:
        _onMessage(event.payload);
      case WsEventType.typing:
        _onTyping(event.payload);
      case WsEventType.presence:
        _onPresence(event.payload);
      case WsEventType.pong:
      case WsEventType.unknown:
        break;
    }
  }

  void _onMessage(Map<String, dynamic> raw) {
    final msgRaw = raw['message'] as Map<String, dynamic>?;
    if (msgRaw == null) return;

    final incoming = Message(
      id:        msgRaw['id'] as String,
      chatId:    msgRaw['chat_id'] as String,
      senderId:  msgRaw['sender_id'] as String?,
      content:   msgRaw['content'] as String,
      createdAt: DateTime.parse(msgRaw['created_at'] as String).toLocal(),
      isRead:    msgRaw['is_read'] as bool? ?? false,
    );

    // Replace matching optimistic placeholder, then append confirmed message.
    final updated = state.messages.where((m) {
      if (!m.isPending) return true;
      return !(m.content == incoming.content &&
               m.senderId == incoming.senderId);
    }).toList()
      ..add(incoming);

    state = state.copyWith(messages: updated);
  }

  void _onTyping(Map<String, dynamic> raw) {
    final userId = raw['user_id'] as String?;
    if (userId == state.currentUserId) return; // ignore self

    final username  = raw['username'] as String? ?? '';
    final isTyping  = raw['is_typing'] as bool? ?? false;

    final updated = Set<String>.from(state.typingUsernames);
    isTyping ? updated.add(username) : updated.remove(username);
    state = state.copyWith(typingUsernames: updated);
  }

  void _onPresence(Map<String, dynamic> raw) {
    final userId = raw['user_id'] as String?;
    if (userId == null) return;

    final online  = raw['online'] as bool? ?? false;
    final updated = Set<String>.from(state.onlineUserIds);
    online ? updated.add(userId) : updated.remove(userId);
    state = state.copyWith(onlineUserIds: updated);
  }

  // ── REST history ─────────────────────────────────────────────────────────

  Future<void> _loadHistory({bool loadMore = false}) async {
    if (state.isLoadingHistory) return;
    state = state.copyWith(isLoadingHistory: true, clearHistoryError: true);

    final skip   = loadMore ? state.messages.length : 0;
    final result = await _fetchMessages(state.chatId, skip: skip, limit: 50);
    if (!mounted) return;

    result.fold(
      (failure) => state = state.copyWith(
        isLoadingHistory: false,
        historyError: failure.message,
      ),
      (incoming) {
        final chronological = incoming.reversed.toList();
        final merged = loadMore
            ? [...chronological, ...state.messages]
            : chronological;
        state = state.copyWith(
          isLoadingHistory: false,
          messages:         merged,
          hasMoreHistory:   incoming.length == 50,
        );
      },
    );
  }

  Future<void> loadMoreHistory() async {
    if (!state.hasMoreHistory || state.isLoadingHistory) return;
    await _loadHistory(loadMore: true);
  }

  // ── Send message ─────────────────────────────────────────────────────────

  void sendMessage(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty || !state.isConnected) return;

    final optimistic = Message(
      id:        const Uuid().v4(),
      chatId:    state.chatId,
      senderId:  state.currentUserId,
      content:   trimmed,
      createdAt: DateTime.now(),
      isPending: true,
    );
    state = state.copyWith(
      messages:       [...state.messages, optimistic],
      clearSendError: true,
    );

    _socket.send({'type': 'message', 'content': trimmed});
    _stopTyping();
  }

  // ── Typing indicator ─────────────────────────────────────────────────────

  void notifyTyping() {
    if (!state.isConnected) return;
    if (!_isTyping) {
      _isTyping = true;
      _socket.send({'type': 'typing', 'is_typing': true});
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);
  }

  void _stopTyping() {
    if (!_isTyping) return;
    _isTyping = false;
    _typingTimer?.cancel();
    if (state.isConnected) {
      _socket.send({'type': 'typing', 'is_typing': false});
    }
  }

  // ── Manual reconnect ─────────────────────────────────────────────────────

  Future<void> reconnect() => _socket.connect();

  // ── Dispose ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _stopTyping();
    _typingTimer?.cancel();
    _statusSub?.cancel();
    _eventSub?.cancel();
    // SocketService lifetime owned by socketServiceProvider — don't dispose here.
    super.dispose();
  }
}
