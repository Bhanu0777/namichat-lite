import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:namichat_lite/app/router/feature_routes.dart';
import 'package:namichat_lite/app/router/route_paths.dart';
import 'package:namichat_lite/app/router/splash_page.dart';
import 'package:namichat_lite/app/screens/home_screen.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_provider.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_state.dart';

/// A [ChangeNotifier] bridge that makes Riverpod auth state listenable by
/// GoRouter's [GoRouter.refreshListenable].
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    // Listen to the auth state and notify GoRouter whenever it changes.
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
    final onAuthRoute =
        location == RoutePaths.login || location == RoutePaths.register;

    if (auth.status == AuthStatus.initial) return RoutePaths.splash;
    if (!auth.isAuthenticated) {
      return onAuthRoute ? null : RoutePaths.login;
    }
    if (onAuthRoute || location == RoutePaths.splash) {
      return RoutePaths.home;
    }
    return null;
  }
}

/// Composition root for application routing.
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
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeScreen(),
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
