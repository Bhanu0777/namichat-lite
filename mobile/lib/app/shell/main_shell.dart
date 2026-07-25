import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:namichat_lite/app/router/route_paths.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _tabs = <_TabItem>[
    _TabItem(
      path: RoutePaths.chats,
      label: 'Chats',
      activeIcon: Icons.chat_bubble,
      inactiveIcon: Icons.chat_bubble_outline,
    ),
    _TabItem(
      path: RoutePaths.userSearch,
      label: 'Search',
      activeIcon: Icons.explore,
      inactiveIcon: Icons.explore_outlined,
    ),
    _TabItem(
      path: RoutePaths.groups,
      label: 'Groups',
      activeIcon: Icons.group,
      inactiveIcon: Icons.group_outlined,
    ),
    _TabItem(
      path: RoutePaths.profile,
      label: 'Profile',
      activeIcon: Icons.person,
      inactiveIcon: Icons.person_outline,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = GoRouterState.of(context).uri.path;
    final selectedIndex = _tabIndexForPath(uri);

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            final target = _tabs[index].path;
            if (uri == target) return;
            context.go(target);
          },
          destinations: _tabs
              .map(
                (t) => NavigationDestination(
                  icon: Icon(t.inactiveIcon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  int _tabIndexForPath(String path) {
    for (var i = 0; i < _tabs.length; i++) {
      if (path == _tabs[i].path || path.startsWith('${_tabs[i].path}/')) {
        return i;
      }
    }
    return 0;
  }
}

class _TabItem {
  const _TabItem({
    required this.path,
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });

  final String path;
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
}
