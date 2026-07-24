import 'package:namichat_lite/features/chat/data/models/message_model.dart';

class ChatWithLastMessageModel {
  const ChatWithLastMessageModel({
    required this.id,
    required this.title,
    required this.chatType,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ChatWithLastMessageModel.fromJson(Map<String, dynamic> json) {
    final lastMessageJson = json['last_message'] as Map<String, dynamic>?;
    return ChatWithLastMessageModel(
      id: json['id'] as String,
      title: json['title'] as String,
      chatType: json['chat_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      lastMessage: lastMessageJson != null
          ? MessageModel.fromJson(lastMessageJson)
          : null,
      unreadCount: (json['unread_count'] as int?) ?? 0,
    );
  }

  final String id;
  final String title;
  final String chatType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MessageModel? lastMessage;
  final int unreadCount;
}
