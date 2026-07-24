import 'package:namichat_lite/features/chat/domain/entities/message.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.chatId,
    this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        chatId: json['chat_id'] as String,
        senderId: json['sender_id'] as String?,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        isRead: json['is_read'] as bool? ?? false,
      );

  final String id;
  final String chatId;
  final String? senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  Message toEntity() => Message(
        id: id,
        chatId: chatId,
        senderId: senderId,
        content: content,
        createdAt: createdAt,
        isRead: isRead,
      );
}
