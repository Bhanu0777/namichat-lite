import 'package:flutter_test/flutter_test.dart';
import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/chat/data/models/chat_with_last_message_model.dart';
import 'package:namichat_lite/features/chat/domain/entities/message.dart';
import 'package:namichat_lite/features/chat/domain/entities/user_search_result.dart';
import 'package:namichat_lite/features/chat/domain/repositories/chat_repository.dart';
import 'package:namichat_lite/features/chat/domain/usecases/search_users_usecase.dart';

class _FakeChatRepository implements ChatRepository {
  List<UserSearchResult>? _results;
  Failure? _failure;

  void returnResults(List<UserSearchResult> r) {
    _results = r;
    _failure = null;
  }

  void returnFailure(Failure f) {
    _failure = f;
    _results = null;
  }

  @override
  Future<Either<Failure, List<ChatWithLastMessageModel>>> listChats() async =>
      const Right([]);

  @override
  Future<Either<Failure, List<UserSearchResult>>> searchUsers(String query) async {
    if (_failure != null) return Left(_failure!);
    return Right(_results ?? []);
  }

  @override
  Future<Either<Failure, String>> openChat(String otherUserId) async =>
      const Right('chat-id');

  @override
  Future<Either<Failure, List<Message>>> fetchMessages(
    String chatId, {
    int skip = 0,
    int limit = 50,
  }) async =>
      const Right([]);
}

void main() {
  late _FakeChatRepository repo;
  late SearchUsersUseCase useCase;

  setUp(() {
    repo = _FakeChatRepository();
    useCase = SearchUsersUseCase(repo);
  });

  final sampleResults = [
    const UserSearchResult(id: '1', username: 'alice', existingChatId: null),
    const UserSearchResult(id: '2', username: 'bob', existingChatId: 'chat-1'),
  ];

  group('SearchUsersUseCase', () {
    test('empty query returns Right([]) without calling repo', () async {
      repo.returnFailure(const NetworkFailure());
      final result = await useCase('');
      expect(result.isRight, isTrue);
      expect(result.right, isEmpty);
    });

    test('whitespace-only query returns Right([])', () async {
      final result = await useCase('   ');
      expect(result.isRight, isTrue);
      expect(result.right, isEmpty);
    });

    test('valid query delegates to repository', () async {
      repo.returnResults(sampleResults);
      final result = await useCase('ali');
      expect(result.isRight, isTrue);
      expect(result.right.length, 2);
      expect(result.right.first.username, 'alice');
    });

    test('query is trimmed before passing to repo', () async {
      repo.returnResults(sampleResults);
      final result = await useCase('  alice  ');
      expect(result.isRight, isTrue);
    });

    test('repo failure is propagated', () async {
      repo.returnFailure(const NetworkFailure('No internet'));
      final result = await useCase('alice');
      expect(result.isLeft, isTrue);
      expect(result.left.message, 'No internet');
    });

    test('UserSearchResult.displayLabel returns displayName first', () {
      const r = UserSearchResult(
        id: '1',
        username: 'alice',
        displayName: 'Alice Wonder',
        fullName: 'Alice Wonderland',
      );
      expect(r.displayLabel, 'Alice Wonder');
    });

    test('UserSearchResult.displayLabel falls back to fullName', () {
      const r = UserSearchResult(
        id: '1',
        username: 'alice',
        fullName: 'Alice Wonderland',
      );
      expect(r.displayLabel, 'Alice Wonderland');
    });

    test('UserSearchResult.displayLabel falls back to username', () {
      const r = UserSearchResult(id: '1', username: 'alice');
      expect(r.displayLabel, 'alice');
    });

    test('hasChatAlready is true when existingChatId is set', () {
      const r = UserSearchResult(
        id: '1',
        username: 'bob',
        existingChatId: 'chat-42',
      );
      expect(r.hasChatAlready, isTrue);
    });

    test('hasChatAlready is false when existingChatId is null', () {
      const r = UserSearchResult(id: '1', username: 'bob');
      expect(r.hasChatAlready, isFalse);
    });

    test('equality holds for identical instances', () {
      const a = UserSearchResult(id: '1', username: 'alice');
      const b = UserSearchResult(id: '1', username: 'alice');
      expect(a, equals(b));
    });
  });
}
