import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:namichat_lite/core/di/injection_container.dart';
import 'package:namichat_lite/core/theme/app_colors.dart';
import 'package:namichat_lite/core/theme/app_gradients.dart';
import 'package:namichat_lite/core/theme/app_radius.dart';
import 'package:namichat_lite/core/theme/app_shadows.dart';
import 'package:namichat_lite/core/theme/app_spacing.dart';
import 'package:namichat_lite/core/theme/app_typography.dart';
import 'package:namichat_lite/design_system/app_animation.dart';
import 'package:namichat_lite/design_system/flow.dart';
import 'package:namichat_lite/app/router/route_paths.dart';

class HomeChatPreview {
  const HomeChatPreview({
    required this.title,
    required this.preview,
    required this.timestamp,
    required this.unreadCount,
    required this.avatarLabel,
    required this.accentColor,
    this.online = false,
    required this.chatId,
  });

  final String title;
  final String preview;
  final String timestamp;
  final int unreadCount;
  final String avatarLabel;
  final Color accentColor;
  final bool online;
  final String chatId;
}

final homeChatsProvider = FutureProvider<List<HomeChatPreview>>((ref) async {
  final result = await ref.read(listChatsUseCaseProvider)();
  return result.fold(
    (failure) => throw failure,
    (chats) => chats
        .map(
          (c) => HomeChatPreview(
            title: c.title,
            preview: c.lastMessage?.content ?? 'No messages yet',
            timestamp: _formatTime(c.lastMessage?.createdAt ?? c.updatedAt),
            unreadCount: c.unreadCount,
            avatarLabel: c.title.isEmpty ? '?' : c.title[0].toUpperCase(),
            accentColor: AppColors.primary,
            online: false,
            chatId: c.id,
          ),
        )
        .toList(),
  );
});

String _formatTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inDays == 0 && diff.inHours == 0 && diff.inMinutes < 1) return 'Now';
  if (diff.inDays == 0) return DateFormat('HH:mm').format(dt);
  if (diff.inDays == 1) return 'Yesterday';
  return DateFormat('MMM d').format(dt);
}

final homeNavigationProvider = StateProvider<int>((ref) => 0);

/// Returns a time-based greeting string.
String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(homeChatsProvider);
    final selectedIndex = ref.watch(homeNavigationProvider);
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isTablet = size.width >= 600;
    final greeting = _greeting();

    return Theme(
      data: Theme.of(context).copyWith(
        navigationBarTheme: NavigationBarThemeData(
          height: 68,
          backgroundColor: scheme.surface.withValues(alpha: 0.92),
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.15),
          indicatorColor: scheme.primary.withValues(alpha: 0.15),
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTypography.caption().copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              );
            }
            return AppTypography.caption().copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(size: 26);
            }
            return const IconThemeData(size: 22);
          }),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
      ),
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = isSmallScreen
                  ? AppSpacing.md
                  : isTablet
                      ? AppSpacing.xxl
                      : AppSpacing.lg;

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isSmallScreen ? AppSpacing.sm : AppSpacing.md,
                  horizontalPadding,
                  horizontalPadding,
                ),
                children: [
                  // ---- Header Row ----
                  Semantics(
                    label: 'App header',
                    child: Row(
                      children: [
                        // Greeting + subtitle
                        Semantics(
                          label: 'Greeting: $greeting',
                          child: Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  greeting,
                                  style: AppTypography.caption().copyWith(
                                    fontSize: isSmallScreen ? 13 : 14,
                                    color: scheme.onSurfaceVariant,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'NamiChat Lite',
                                  style: AppTypography.heading().copyWith(
                                    fontSize: isSmallScreen ? 22 : 28,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Action icons
                        Semantics(
                          label: 'Settings',
                          child: IconButton(
                            onPressed: () => context.go(RoutePaths.settings),
                            icon: const Icon(Icons.settings_outlined),
                            tooltip: 'Settings',
                            style: IconButton.styleFrom(
                              backgroundColor: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.7),
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Semantics(
                          label: 'Profile',
                          child: IconButton(
                            onPressed: () => context.go(RoutePaths.profile),
                            icon: const Icon(Icons.person_outline),
                            tooltip: 'Profile',
                            style: IconButton.styleFrom(
                              backgroundColor: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.7),
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: isSmallScreen ? AppSpacing.lg : AppSpacing.xl,
                  ),

                  // ---- Greeting Card ----
                  Semantics(
                    label: 'Welcome card',
                    child: FlowCard(
                      elevation: 2,
                      borderRadius: AppRadius.xl,
                      clip: true,
                      padding: EdgeInsets.zero,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppGradients.brand,
                        ),
                        padding: EdgeInsets.all(
                          isSmallScreen ? AppSpacing.lg : AppSpacing.xl,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your conversations await',
                                    style: AppTypography.subtitle().copyWith(
                                      fontSize: isSmallScreen ? 15 : 18,
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(
                                    height: isSmallScreen ? AppSpacing.xs : AppSpacing.sm,
                                  ),
                                  Text(
                                    'Jump into the latest chats, search for people, or start a new group.',
                                    style: AppTypography.caption().copyWith(
                                      fontSize: isSmallScreen ? 12 : 13,
                                      color: AppColors.primaryText.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.primaryText.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppRadius.xl),
                              ),
                              child: Semantics(
                                label: 'Chat icon',
                                child: Icon(
                                  Icons.chat_bubble_rounded,
                                  size: isSmallScreen ? 24 : 28,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: isSmallScreen ? AppSpacing.lg : AppSpacing.xl,
                  ),

                  // ---- Action Buttons ----
                  Semantics(
                    label: 'Home actions',
                    child: Row(
                      children: [
                        Expanded(
                          child: FlowButton(
                            onPressed: () => context.go(RoutePaths.userSearch),
                            label: 'Search',
                            icon: Semantics(
                              label: 'Search icon',
                              child: const Icon(Icons.search),
                            ),
                            variant: FlowButtonVariant.outline,
                            fullWidth: true,
                            size: isSmallScreen
                                ? FlowButtonSize.small
                                : FlowButtonSize.medium,
                          ),
                        ),
                        SizedBox(
                          width: isSmallScreen ? AppSpacing.sm : AppSpacing.md,
                        ),
                        Expanded(
                          child: FlowButton(
                            onPressed: () => context.push(RoutePaths.createGroup),
                            label: 'Create group',
                            icon: Semantics(
                              label: 'Create group icon',
                              child: const Icon(Icons.group_add),
                            ),
                            variant: FlowButtonVariant.secondary,
                            fullWidth: true,
                            size: isSmallScreen
                                ? FlowButtonSize.small
                                : FlowButtonSize.medium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: isSmallScreen ? AppSpacing.lg : AppSpacing.xl,
                  ),

                  // ---- Section Header ----
                  Semantics(
                    label: 'Recent chats section',
                    child: Row(
                      children: [
                        Text(
                          'Recent chats',
                          style: AppTypography.subtitle().copyWith(
                            fontSize: isSmallScreen ? 15 : 18,
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${chatsAsync.valueOrNull?.where((chat) => chat.unreadCount > 0).length ?? 0} unread',
                          style: AppTypography.caption().copyWith(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: isSmallScreen ? AppSpacing.md : AppSpacing.lg,
                  ),

                  // ---- Chat List ----
                  if (chatsAsync.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                        child: FlowLoadingIndicator(size: 32),
                      ),
                    )
                  else if (chatsAsync.hasError)
                    FlowErrorState(
                      message: chatsAsync.error.toString(),
                      onRetry: () => ref.invalidate(homeChatsProvider),
                    )
                  else if (chatsAsync.valueOrNull == null ||
                      chatsAsync.valueOrNull!.isEmpty)
                    FlowEmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No conversations yet',
                      description:
                          'Start a chat or create a group to bring your people together.',
                      actionLabel: 'Create group',
                      onAction: () => context.push(RoutePaths.createGroup),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: chatsAsync.valueOrNull!.length,
                      separatorBuilder: (_, __) => const SizedBox(
                        height: AppSpacing.sm,
                      ),
                      itemBuilder: (context, index) {
                        final chat = chatsAsync.valueOrNull![index];
                        final hasUnread = chat.unreadCount > 0;

                        return Semantics(
                          label: 'Chat: ${chat.title}',
                          child: FlowCard(
                            onTap: () =>
                                context.push(RoutePaths.chatWithId(chat.chatId)),
                            elevation: hasUnread ? 2 : 1,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            borderRadius: AppRadius.lg,
                            child: Row(
                              children: [
                                // Avatar
                                Semantics(
                                  label: 'Avatar for ${chat.title}',
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: isSmallScreen ? 18 : 22,
                                        backgroundColor:
                                            chat.accentColor.withValues(alpha: 0.16),
                                        child: Text(
                                          chat.avatarLabel,
                                          style: TextStyle(
                                            color: chat.accentColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: isSmallScreen ? 13 : 15,
                                          ),
                                        ),
                                      ),
                                      if (chat.online)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: AppSpacing.xs + 4,
                                            height: AppSpacing.xs + 4,
                                            decoration: BoxDecoration(
                                              color: AppColors.online,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: scheme.surface,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),

                                // Chat content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              chat.title,
                                              style: AppTypography.subtitle()
                                                  .copyWith(
                                                fontSize: isSmallScreen ? 14 : 15,
                                                fontWeight: hasUnread
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                color: scheme.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Text(
                                            chat.timestamp,
                                            style: AppTypography.caption().copyWith(
                                              fontSize: isSmallScreen ? 10 : 11,
                                              color: hasUnread
                                                  ? scheme.primary
                                                  : scheme.onSurfaceVariant,
                                              fontWeight: hasUnread
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        chat.preview,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.caption().copyWith(
                                          fontSize: isSmallScreen ? 12 : 13,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),

                                // Unread badge
                                if (hasUnread)
                                  Semantics(
                                    label:
                                        '${chat.unreadCount} unread messages',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.full,
                                        ),
                                        boxShadow: AppShadows.glow(
                                          scheme.primary,
                                        ),
                                      ),
                                      child: Text(
                                        '${chat.unreadCount}',
                                        style: AppTypography.caption().copyWith(
                                          fontSize: isSmallScreen ? 10 : 11,
                                          color: scheme.onPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: Semantics(
          label: 'Bottom navigation',
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (value) {
              ref.read(homeNavigationProvider.notifier).state = value;
              if (value == 1) {
                context.push(RoutePaths.groups);
              } else if (value == 2) {
                context.go(RoutePaths.profile);
              }
            },
            animationDuration: AppAnimation.medium,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Chats',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
