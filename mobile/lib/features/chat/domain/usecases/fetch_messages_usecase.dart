import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/chat/domain/entities/message.dart';
import 'package:namichat_lite/features/chat/domain/repositories/chat_repository.dart';

class FetchMessagesUseCase {
  FetchMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, List<Message>>> call(
    String chatId, {
    int skip = 0,
    int limit = 50,
  }) =>
      _repository.fetchMessages(chatId, skip: skip, limit: limit);
}
