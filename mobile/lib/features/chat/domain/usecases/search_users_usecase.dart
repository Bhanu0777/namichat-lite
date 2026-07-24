import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/chat/domain/entities/user_search_result.dart';
import 'package:namichat_lite/features/chat/domain/repositories/chat_repository.dart';

class SearchUsersUseCase {
  SearchUsersUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, List<UserSearchResult>>> call(String query) {
    if (query.trim().isEmpty) {
      return Future.value(const Right([]));
    }
    return _repository.searchUsers(query.trim());
  }
}
