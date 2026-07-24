import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namichat_lite/app/router/app_router.dart';
import 'package:namichat_lite/app/theme/app_theme.dart';
import 'package:namichat_lite/core/constants/app_constants.dart';
import 'package:namichat_lite/features/settings/presentation/providers/settings_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title:      AppConstants.appName,
      theme:      AppTheme.light,
      darkTheme:  AppTheme.dark,
      themeMode:  themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
