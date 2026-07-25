import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:namichat_lite/app/router/feature_routes.dart';
import 'package:namichat_lite/app/router/route_paths.dart';
import 'package:namichat_lite/app/router/splash_page.dart';
import 'package:namichat_lite/app/shell/main_shell.dart';
import 'package:namichat_lite/features/chat/presentation/pages/chats_page.dart';
import 'package:namichat_lite/features/chat/presentation/pages/user_search_page.dart';
import 'package:namichat_lite/features/groups/presentation/pages/groups_list_page.dart';
import 'package:namichat_lite/features/profile/presentation/pages/profile_page.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_provider.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_state.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;

  AuthState get _authState => _ref.read(authNotifierProvider);

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _authState;
    final location = state.matchedLocation;

    if (auth.status == AuthStatus.initial) return RoutePaths.splash;

    final isAuthRoute = location == RoutePaths.login || location == RoutePaths.register;

    if (!auth.isAuthenticated) {
      return isAuthRoute ? null : RoutePaths.login;
    }

    if (isAuthRoute || location == RoutePaths.splash) {
      return RoutePaths.chats;
    }

    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            redirect: (_, __) => RoutePaths.chats,
          ),
          GoRoute(
            path: RoutePaths.chats,
            builder: (context, state) => const ChatsPage(),
          ),
          GoRoute(
            path: RoutePaths.userSearch,
            builder: (context, state) => const UserSearchPage(),
          ),
          GoRoute(
            path: RoutePaths.groups,
            builder: (context, state) => const GroupsListPage(),
          ),
          GoRoute(
            path: RoutePaths.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      ...registerFeatureRoutes(),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Route not found: ${state.uri.path}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ),
  );
});
