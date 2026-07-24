import 'package:equatable/equatable.dart';

/// A single chat message in the domain layer.
class Message extends Equatable {
  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.isPending = false,
  });

  final String id;
  final String chatId;

  /// Null when the server sets sender_id to NULL (e.g. system messages).
  final String? senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  /// True for optimistically-inserted messages not yet confirmed by server.
  final bool isPending;

  @override
  List<Object?> get props =>
      [id, chatId, senderId, content, createdAt, isRead, isPending];
}
