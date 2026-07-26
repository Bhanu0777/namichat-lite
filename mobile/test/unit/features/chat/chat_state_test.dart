import 'package:flutter_test/flutter_test.dart';
import 'package:namichat_lite/features/chat/domain/entities/message.dart';
import 'package:namichat_lite/features/chat/presentation/providers/chat_state.dart';

void main() {
  final msg = Message(
    id: 'm1',
    chatId: 'c1',
    senderId: 'u1',
    content: 'Hello',
    createdAt: DateTime(2026, 7, 15),
  );

  group('ChatState', () {
    test('default state has empty messages', () {
      const state = ChatState();
      expect(state.messages, isEmpty);
      expect(state.chatId, '');
      expect(state.socketStatus, SocketStatus.idle);
    });

    test('copyWith preserves unchanged fields', () {
      final state = ChatState(chatId: 'c1', messages: [msg]);
      final copy = state.copyWith(socketStatus: SocketStatus.connected);
      expect(copy.chatId, 'c1');
      expect(copy.messages.length, 1);
      expect(copy.socketStatus, SocketStatus.connected);
    });

    test('isConnected is true only when socketStatus is connected', () {
      expect(const ChatState(socketStatus: SocketStatus.connected).isConnected, isTrue);
      expect(const ChatState(socketStatus: SocketStatus.idle).isConnected, isFalse);
      expect(const ChatState(socketStatus: SocketStatus.reconnecting).isConnected, isFalse);
      expect(const ChatState(socketStatus: SocketStatus.disconnected).isConnected, isFalse);
    });

    test('isPeerOnline is true when onlineUserIds is not empty', () {
      expect(const ChatState(onlineUserIds: {'u2'}).isPeerOnline, isTrue);
      expect(const ChatState(onlineUserIds: <String>{}).isPeerOnline, isFalse);
    });

    test('clearHistoryError removes historyError', () {
      final state = ChatState(historyError: 'load failed');
      final copy = state.copyWith(clearHistoryError: true);
      expect(copy.historyError, isNull);
    });

    test('clearSendError removes sendError', () {
      final state = ChatState(sendError: 'send failed');
      final copy = state.copyWith(clearSendError: true);
      expect(copy.sendError, isNull);
    });

    test('isReconnecting is true when reconnecting', () {
      expect(ChatState(socketStatus: SocketStatus.reconnecting).isReconnecting, isTrue);
      expect(ChatState(socketStatus: SocketStatus.connected).isReconnecting, isFalse);
    });
  });
}
