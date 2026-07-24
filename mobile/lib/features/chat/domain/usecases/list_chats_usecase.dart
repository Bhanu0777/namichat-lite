import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/chat/data/models/chat_with_last_message_model.dart';
import 'package:namichat_lite/features/chat/domain/repositories/chat_repository.dart';

class ListChatsUseCase {
  ListChatsUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, List<ChatWithLastMessageModel>>> call() =>
      _repository.listChats();
}
