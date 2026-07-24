import 'package:dio/dio.dart';
import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:namichat_lite/features/chat/domain/entities/message.dart';
import 'package:namichat_lite/features/chat/domain/entities/user_search_result.dart';
import 'package:namichat_lite/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._remote);

  final ChatRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<UserSearchResult>>> searchUsers(
      String query) async {
    try {
      final models = await _remote.searchUsers(query);
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(_map(e, fallback: 'Search failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> openChat(String otherUserId) async {
    try {
      return Right(await _remote.openChat(otherUserId));
    } on DioException catch (e) {
      return Left(_map(e, fallback: 'Could not open chat'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> fetchMessages(
    String chatId, {
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final models =
          await _remote.fetchMessages(chatId, skip: skip, limit: limit);
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(_map(e, fallback: 'Could not load messages'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _map(DioException e, {required String fallback}) {
    if (e.error is Failure) return e.error as Failure;
    final detail = e.response?.data is Map<String, dynamic>
        ? (e.response!.data as Map<String, dynamic>)['detail']?.toString()
        : null;
    return detail != null && detail.isNotEmpty
        ? ServerFailure(detail, e.response?.statusCode)
        : ServerFailure(fallback, e.response?.statusCode);
  }
}
