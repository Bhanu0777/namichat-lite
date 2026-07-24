import 'package:namichat_lite/core/network/socket_service.dart';
import 'package:namichat_lite/features/chat/domain/entities/message.dart';

export 'package:namichat_lite/core/network/socket_service.dart'
    show SocketStatus, WsEvent, WsEventType;

/// Immutable state for a single private-chat session.
class ChatState {
  const ChatState({
    this.chatId = '',
    this.currentUserId = '',
    this.messages = const [],
    this.socketStatus = SocketStatus.idle,
    this.isLoadingHistory = false,
    this.hasMoreHistory = true,
    this.historyError,
    this.sendError,
    this.typingUsernames = const {},
    this.onlineUserIds = const {},
  });

  final String chatId;
  final String currentUserId;

  /// Chronological order — oldest first, newest last.
  final List<Message> messages;

  final SocketStatus socketStatus;
  final bool isLoadingHistory;
  final bool hasMoreHistory;
  final String? historyError;
  final String? sendError;

  /// Usernames currently typing (other users only).
  final Set<String> typingUsernames;

  /// User IDs of peers who are online in this room right now.
  final Set<String> onlineUserIds;

  bool get isConnected => socketStatus == SocketStatus.connected;
  bool get isPeerOnline => onlineUserIds.isNotEmpty;
  bool get isReconnecting => socketStatus == SocketStatus.reconnecting;

  ChatState copyWith({
    String? chatId,
    String? currentUserId,
    List<Message>? messages,
    SocketStatus? socketStatus,
    bool? isLoadingHistory,
    bool? hasMoreHistory,
    String? historyError,
    bool clearHistoryError = false,
    String? sendError,
    bool clearSendError = false,
    Set<String>? typingUsernames,
    Set<String>? onlineUserIds,
  }) {
    return ChatState(
      chatId: chatId ?? this.chatId,
      currentUserId: currentUserId ?? this.currentUserId,
      messages: messages ?? this.messages,
      socketStatus: socketStatus ?? this.socketStatus,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      historyError:
          clearHistoryError ? null : (historyError ?? this.historyError),
      sendError: clearSendError ? null : (sendError ?? this.sendError),
      typingUsernames: typingUsernames ?? this.typingUsernames,
      onlineUserIds: onlineUserIds ?? this.onlineUserIds,
    );
  }
}
