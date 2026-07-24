import 'package:dio/dio.dart';

import 'package:namichat_lite/core/network/api_endpoints.dart';
import 'package:namichat_lite/core/network/dio_client.dart';
import 'package:namichat_lite/features/chat/data/models/message_model.dart';
import 'package:namichat_lite/features/chat/data/models/user_search_result_model.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  // ---- User search ----

  Future<List<UserSearchResultModel>> searchUsers(String query) async {
    final response = await _dioClient.client.get(
      ApiEndpoints.userSearch,
      queryParameters: {'query': query},
    );
    if (response.data is! List) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Unexpected response payload',
      );
    }
    return (response.data as List)
        .map((i) => UserSearchResultModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  // ---- Chat management ----

  /// Opens (or creates) a direct chat. Returns the chat ID.
  Future<String> openChat(String otherUserId) async {
    final response =
        await _dioClient.client.post(ApiEndpoints.openChat(otherUserId));
    return (response.data as Map<String, dynamic>)['id'] as String;
  }

  // ---- Message history ----

  /// Returns [limit] messages starting at [skip], newest-first.
  /// The caller reverses them to display oldest-at-top.
  Future<List<MessageModel>> fetchMessages(
    String chatId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final response = await _dioClient.client.get(
      ApiEndpoints.chatMessages(chatId),
      queryParameters: {'skip': skip, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List;
    return items
        .map((i) => MessageModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }
}
