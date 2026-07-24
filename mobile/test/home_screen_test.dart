import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namichat_lite/app/screens/home_screen.dart';

void main() {
  testWidgets('home screen shows recent chats and primary actions', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
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
