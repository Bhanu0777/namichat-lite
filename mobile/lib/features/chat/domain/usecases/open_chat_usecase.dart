import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/chat/domain/repositories/chat_repository.dart';

/// Opens or creates a direct chat with a given user.
///
/// If an existing chat ID is already known (from search results), pass it
/// directly via [knownChatId] to skip the network call entirely.
class OpenChatUseCase {
  OpenChatUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, String>> call({
    required String otherUserId,
    String? knownChatId,
  }) {
    if (knownChatId != null && knownChatId.isNotEmpty) {
      return Future.value(Right(knownChatId));
    }
    return _repository.openChat(otherUserId);
  }
}
