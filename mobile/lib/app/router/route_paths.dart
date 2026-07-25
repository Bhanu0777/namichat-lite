/// Centralized route path definitions for GoRouter.
///
/// Defines the full navigation surface. Feature routes are added here as the
/// corresponding screens are implemented.
class RoutePaths {
  const RoutePaths._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String chats = '/home/chats';
  static const String userSearch = '/home/search';
  static const String groups = '/home/groups';
  static const String profile = '/home/profile';
  static const String editProfile = '/profile/edit';
  static const String chat = '/chat';
  static const String createGroup = '/groups/create';
  static const String joinGroup = '/groups/join';
  static const String settings = '/settings';

  static String chatWithId(String id)  => '$chat/$id';
  static String groupDetail(String id) => '$groups/$id';
}
