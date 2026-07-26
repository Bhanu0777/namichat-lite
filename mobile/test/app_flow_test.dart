import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:namichat_lite/app/app.dart';
import 'package:namichat_lite/core/di/injection_container.dart';
import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/auth/domain/entities/user.dart';
import 'package:namichat_lite/features/auth/domain/repositories/auth_repository.dart';
import 'package:namichat_lite/features/chat/presentation/pages/chats_page.dart';
import 'helpers/fake_box.dart';

// Fake User
final _fakeUser = User(
  id: 'u1',
  email: 'test@example.com',
  username: 'testuser',
  fullName: 'Test User',
  createdAt: DateTime(2025, 1, 1),
);

// Stateful Fake AuthRepository
class _FakeAuthRepo implements AuthRepository {
  bool _loggedIn = false;

  @override
  Future<Either<Failure, User>> login(String i, String p) async {
    _loggedIn = true;
    return Right(_fakeUser);
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    _loggedIn = true;
    return Right(_fakeUser);
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    if (_loggedIn) return Right(_fakeUser);
    return Left(ServerFailure('No user'));
  }

  @override
  Future<Either<Failure, void>> logout() async {
    _loggedIn = false;
    return const Right(null);
  }
}

void main() {
  testWidgets('App Flow: Login -> Home -> Profile -> Settings -> Logout', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWith((_) => makeFakeLocalStorage()),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          homeChatsProvider.overrideWith((ref) => Future.value([
                const HomeChatPreview(
                  title: 'Mina',
                  preview: 'Hello',
                  timestamp: 'Now',
                  unreadCount: 2,
                  avatarLabel: 'M',
                  accentColor: Colors.blue,
                  chatId: '1',
                ),
              ])),
        ],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 3));

    // We should be on the login screen
    expect(find.text('Sign in to continue to NamiChat Lite'), findsOneWidget);

    // 1. LOGIN FLOW
    await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    // 2. CHATS PAGE (Home)
    debugDumpApp();
    expect(find.text('Mina'), findsOneWidget);

    // 3. NAVIGATE TO PROFILE VIA BOTTOM NAV
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Verify Profile Page
    expect(find.text('Test User'), findsWidgets); // Can appear in multiple places

    // 4. NAVIGATE TO SETTINGS VIA APP BAR ICON
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // Verify Settings Screen
    expect(find.text('APPEARANCE'), findsOneWidget);

    // 5. LOGOUT FLOW
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    // Back to Login
    expect(find.text('Sign in to continue to NamiChat Lite'), findsOneWidget);
  });
}

