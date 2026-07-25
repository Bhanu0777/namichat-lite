import 'package:go_router/go_router.dart';

import 'package:namichat_lite/app/router/route_paths.dart';
import 'package:namichat_lite/features/auth/presentation/pages/login_page.dart';
import 'package:namichat_lite/features/auth/presentation/pages/register_page.dart';
import 'package:namichat_lite/features/chat/presentation/pages/chat_page.dart';
import 'package:namichat_lite/features/groups/presentation/pages/create_group_page.dart';
import 'package:namichat_lite/features/groups/presentation/pages/group_detail_page.dart';
import 'package:namichat_lite/features/groups/presentation/pages/join_group_page.dart';
import 'package:namichat_lite/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:namichat_lite/features/settings/presentation/pages/settings_page.dart';

/// Auth and full-screen destinations that sit outside the bottom nav shell.
List<RouteBase> registerFeatureRoutes() {
  return [
    GoRoute(
      path: RoutePaths.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: RoutePaths.register,
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: RoutePaths.editProfile,
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: RoutePaths.settings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '${RoutePaths.chat}/:chatId',
      builder: (context, state) =>
          ChatPage(chatId: state.pathParameters['chatId'] ?? ''),
    ),
    GoRoute(
      path: RoutePaths.createGroup,
      builder: (context, state) => const CreateGroupPage(),
    ),
    GoRoute(
      path: RoutePaths.joinGroup,
      builder: (context, state) => const JoinGroupPage(),
    ),
    GoRoute(
      path: '${RoutePaths.groups}/:groupId',
      builder: (context, state) =>
          GroupDetailPage(groupId: state.pathParameters['groupId'] ?? ''),
    ),
  ];
}
