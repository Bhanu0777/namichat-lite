import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namichat_lite/design_system/flow.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_provider.dart';

/// Application bootstrap screen.
///
/// Triggers [AuthNotifier.bootstrap] to restore or validate the session.
/// Navigation is then handled by the router's auth redirect.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authNotifierProvider.notifier).bootstrap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: FlowSpacing.lg),
            Text('NamiChat Lite'),
          ],
        ),
      ),
    );
  }
}
