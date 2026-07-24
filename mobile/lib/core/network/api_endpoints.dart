/// Centralized REST endpoint definitions (API contract).
///
/// All paths are relative to the Dio client's baseUrl, which already includes
/// the API version prefix (e.g. `http://host:8000/api/v1`). Do NOT add the
/// version prefix again here.
class ApiEndpoints {
  const ApiEndpoints._();

  // ---- Auth ----
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // ---- Users ----
  static const String me = '/users/me';
  static const String userSearch = '/users/search';

  // ---- Conversations ----
  static const String conversations = '/conversations';

  /// Opens or creates a direct chat with the given user.
  static String openChat(String userId) => '/chats/open/$userId';

  /// Lists all chats for the current user.
  static const String chats = '/chats';

  // ---- Messages ----
  static const String messages = '/messages';

  /// Returns the message history path for a chat.
  static String chatMessages(String chatId) => '/chats/$chatId/messages';

  /// Returns the WebSocket upgrade path for a chat.
  static String chatWs(String chatId) => '/ws/$chatId';

  // ---- Groups ----
  static const String groups     = '/groups';
  static const String groupsJoin = '/groups/join';

  static String group(String groupId)                         => '/groups/$groupId';
  static String groupRegenerateInvite(String groupId)         => '/groups/$groupId/invite/regenerate';
  static String groupMember(String groupId, String userId)    => '/groups/$groupId/members/$userId';
  static String groupPromoteMember(String groupId, String userId) => '/groups/$groupId/members/$userId/promote';
}
