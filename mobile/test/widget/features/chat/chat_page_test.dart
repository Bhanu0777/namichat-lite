import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:namichat_lite/features/chat/presentation/pages/chat_page.dart';
import 'package:namichat_lite/features/chat/presentation/providers/chat_provider.dart';

import 'package:namichat_lite/core/network/socket_service.dart';
import 'package:namichat_lite/features/chat/data/models/chat_with_last_message_model.dart';
import 'package:namichat_lite/features/chat/domain/usecases/fetch_messages_usecase.dart';
import 'package:namichat_lite/features/chat/domain/repositories/chat_repository.dart';
import 'package:namichat_lite/features/chat/domain/entities/message.dart';
import 'package:namichat_lite/features/chat/domain/entities/user_search_result.dart';
import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';

class _FakeSocketService implements SocketService {
  _FakeSocketService() {
    _statusCtrl.add(SocketStatus.connected);
  }

  final _statusCtrl = StreamController<SocketStatus>.broadcast();
  final _eventCtrl = StreamController<WsEvent>.broadcast();

  @override
  Stream<SocketStatus> get statusStream => _statusCtrl.stream;
  @override
  Stream<WsEvent> get events => _eventCtrl.stream;
  @override
  Future<void> connect() async {
    _statusCtrl.add(SocketStatus.connected);
  }
  @override
  void send(Map<String, dynamic> frame) {}
  @override
  Future<void> dispose() async {
    await _statusCtrl.close();
    await _eventCtrl.close();
  }
  @override
  SocketStatus get status => SocketStatus.connected;
  @override
  final Duration pingInterval = const Duration(seconds: 25);
  @override
  final Duration pingTimeout = const Duration(seconds: 10);
  @override
  final int maxRetries = 6;
}

class _FakeChatRepository implements ChatRepository {
  @override
  Future<Either<Failure, List<ChatWithLastMessageModel>>> listChats() async =>
      const Right([]);

  @override
  Future<Either<Failure, List<Message>>> fetchMessages(
    String chatId, {
    int skip = 0,
    int limit = 50,
  }) async =>
      const Right([]);

  @override
  Future<Either<Failure, String>> openChat(String otherUserId) async =>
      const Right('chat-1');

  @override
  Future<Either<Failure, List<UserSearchResult>>> searchUsers(String query) async =>
      const Right([]);
}

class _FakeFetchMessagesUseCase extends FetchMessagesUseCase {
  _FakeFetchMessagesUseCase() : super(_FakeChatRepository());
}

class _FakeChatNotifier extends ChatNotifier {
  _FakeChatNotifier()
      : super(
          chatId: 'chat-1',
          currentUserId: 'u1',
          socketService: _FakeSocketService(),
          fetchMessages: _FakeFetchMessagesUseCase(),
        );
}

void main() {
  group('ChatPage', () {
    testWidgets('renders app bar with chat title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatNotifierProvider.overrideWith((ref, chatId) => _FakeChatNotifier()),
          ],
          child: MaterialApp(
            home: ChatPage(chatId: 'chat-1'),
            theme: ThemeData(useMaterial3: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chat'), findsOneWidget);
    });

    testWidgets('renders empty state when no messages', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatNotifierProvider.overrideWith((ref, chatId) => _FakeChatNotifier()),
          ],
          child: MaterialApp(
            home: ChatPage(chatId: 'chat-1'),
            theme: ThemeData(useMaterial3: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('renders input bar with hint', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatNotifierProvider.overrideWith((ref, chatId) => _FakeChatNotifier()),
          ],
          child: MaterialApp(
            home: ChatPage(chatId: 'chat-1'),
            theme: ThemeData(useMaterial3: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Type a message\u2026'), findsOneWidget);
    });

    testWidgets('renders send button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatNotifierProvider.overrideWith((ref, chatId) => _FakeChatNotifier()),
          ],
          child: MaterialApp(
            home: ChatPage(chatId: 'chat-1'),
            theme: ThemeData(useMaterial3: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });
  });
}
