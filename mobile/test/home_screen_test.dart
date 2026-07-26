import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namichat_lite/app/screens/home_screen.dart';
import 'package:namichat_lite/core/di/injection_container.dart';

void main() {
  testWidgets('home screen shows recent chats and primary actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeChatsProvider.overrideWith((_) => Future.value([
                const HomeChatPreview(
                  title: 'Mina',
                  preview: 'Hello',
                  timestamp: 'Now',
                  unreadCount: 2,
                  avatarLabel: 'M',
                  accentColor: Colors.blue,
                  chatId: '1',
                ),
                const HomeChatPreview(
                  title: 'Group Chat',
                  preview: 'Hey everyone',
                  timestamp: 'Yesterday',
                  unreadCount: 0,
                  avatarLabel: 'G',
                  accentColor: Colors.green,
                  chatId: '2',
                ),
              ])),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('NamiChat Lite'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Recent chats'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Create group'), findsOneWidget);
    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('2 unread'), findsOneWidget);
  });
}
