import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:namichat_lite/core/di/injection_container.dart';
import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/auth/domain/entities/user.dart';
import 'package:namichat_lite/features/auth/domain/repositories/auth_repository.dart';
import 'package:namichat_lite/features/auth/domain/usecases/auth_usecases.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_provider.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_state.dart';
import 'package:namichat_lite/features/settings/presentation/pages/settings_page.dart';

import '../../../helpers/fake_box.dart';

// ---------------------------------------------------------------------------
// Fake user + auth repo
// ---------------------------------------------------------------------------

final _fakeUser = User(
  id: 'u1',
  email: 'alice@example.com',
  username: 'alice',
  fullName: 'Alice',
  createdAt: DateTime(2025, 1, 1),
);

class _StubAuthRepo implements AuthRepository {
  @override
  Future<Either<Failure, User>> login(String i, String p) async =>
      Right(_fakeUser);
  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async =>
      Right(_fakeUser);
  @override
  Future<Either<Failure, User>> getCurrentUser() async => Right(_fakeUser);
  @override
  Future<Either<Failure, void>> logout() async => const Right(null);
}

class _AuthenticatedNotifier extends AuthNotifier {
  _AuthenticatedNotifier()
      : super(
          LoginUseCase(_StubAuthRepo()),
          RegisterUseCase(_StubAuthRepo()),
          GetCurrentUserUseCase(_StubAuthRepo()),
          LogoutUseCase(_StubAuthRepo()),
        ) {
    state = AuthState(status: AuthStatus.authenticated, user: _fakeUser);
  }
}

// ---------------------------------------------------------------------------
// Test scaffold — overrides localStorageProvider with a map-backed fake.
// ThemeNotifier and CacheNotifier then work through the real code path.
// ---------------------------------------------------------------------------

Widget _buildSettingsPage() {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/login', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
    ],
  );

  return ProviderScope(
    overrides: [
      // Use a map-backed LocalStorage so ThemeNotifier & CacheNotifier
      // work without a real Hive box.
      localStorageProvider.overrideWith((_) => makeFakeLocalStorage()),
      // Pre-authenticated user.
      authNotifierProvider.overrideWith((_) => _AuthenticatedNotifier()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('SettingsPage', () {
    testWidgets('renders all five section headers', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('STORAGE'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('SESSION'), findsOneWidget);
    });

    testWidgets('shows logged-in user name and email', (tester) async {
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);
    });

    testWidgets('shows three theme option tiles', (tester) async {
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      expect(find.text('System default'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('System default is selected initially', (tester) async {
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping Dark changes selection', (tester) async {
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping Light changes selection', (tester) async {
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Local cache (Hive) label is present', (tester) async {
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      expect(find.text('Local cache (Hive)'), findsOneWidget);
    });

    testWidgets('tapping Clear cache opens confirmation dialog', (tester) async {
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear cache'));
      await tester.pumpAndSettle();

      expect(find.text('Clear cache?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancelling cache clear closes dialog', (tester) async {
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear cache'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Clear cache?'), findsNothing);
    });

    testWidgets('tapping Sign out opens confirmation dialog', (tester) async {
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Sign out?'), findsOneWidget);
    });

    testWidgets('cancelling Sign out keeps settings visible', (tester) async {
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('APPEARANCE'), findsOneWidget);
    });

    testWidgets('About section shows version 1.0.0', (tester) async {
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      expect(find.text('Version'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('About section shows app name', (tester) async {
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      expect(find.text('App name'), findsOneWidget);
      expect(find.text('NamiChat Lite'), findsOneWidget);
    });

    testWidgets('Edit profile tile is present', (tester) async {
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      expect(find.text('Edit profile'), findsOneWidget);
    });

    testWidgets('MIT license is shown', (tester) async {
      await tester.pumpWidget(_buildSettingsPage());
      await tester.pumpAndSettle();

      expect(find.text('License'), findsOneWidget);
      expect(find.text('MIT'), findsOneWidget);
    });
  });
}
