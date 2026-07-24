import 'package:flutter_test/flutter_test.dart';
import 'package:namichat_lite/features/chat/domain/entities/message.dart';

void main() {
  final now = DateTime(2026, 7, 15, 12, 0);

  group('Message entity', () {
    test('two identical messages are equal', () {
      final a = Message(
        id: 'm1',
        chatId: 'c1',
        senderId: 'u1',
        content: 'Hello',
        createdAt: now,
      );
      final b = Message(
        id: 'm1',
        chatId: 'c1',
        senderId: 'u1',
        content: 'Hello',
        createdAt: now,
      );
      expect(a, equals(b));
    });

    test('messages with different ids are not equal', () {
      final a = Message(id: 'm1', chatId: 'c1', senderId: 'u1', content: 'Hi', createdAt: now);
      final b = Message(id: 'm2', chatId: 'c1', senderId: 'u1', content: 'Hi', createdAt: now);
      expect(a, isNot(equals(b)));
    });

    test('default isRead is false', () {
      final msg = Message(id: 'm1', chatId: 'c1', senderId: 'u1', content: 'Hi', createdAt: now);
      expect(msg.isRead, isFalse);
    });

    test('default isPending is false', () {
      final msg = Message(id: 'm1', chatId: 'c1', senderId: 'u1', content: 'Hi', createdAt: now);
      expect(msg.isPending, isFalse);
    });

    test('senderId can be null', () {
      final msg = Message(id: 'm1', chatId: 'c1', senderId: null, content: 'System', createdAt: now);
      expect(msg.senderId, isNull);
    });

    test('props contains all fields', () {
      final msg = Message(
        id: 'm1',
        chatId: 'c1',
        senderId: 'u1',
        content: 'Hello',
        createdAt: now,
        isRead: true,
        isPending: true,
      );
      expect(msg.props, containsAll(['m1', 'c1', 'u1', 'Hello']));
    });
  });
}
