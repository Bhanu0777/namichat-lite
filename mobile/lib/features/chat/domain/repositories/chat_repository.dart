import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/chat/data/models/chat_with_last_message_model.dart';
import 'package:namichat_lite/features/chat/domain/entities/message.dart';
import 'package:namichat_lite/features/chat/domain/entities/user_search_result.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<ChatWithLastMessageModel>>> listChats();

  /// Search users by username, Nami ID, or display name.
  Future<Either<Failure, List<UserSearchResult>>> searchUsers(String query);

  /// Opens an existing direct chat or creates a new one. Returns the chat ID.
  Future<Either<Failure, String>> openChat(String otherUserId);

  /// Fetches paginated message history for [chatId], newest-first.
  Future<Either<Failure, List<Message>>> fetchMessages(
    String chatId, {
    int skip = 0,
    int limit = 50,
  });
}
