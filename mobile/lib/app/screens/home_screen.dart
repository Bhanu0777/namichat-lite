import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:namichat_lite/core/di/injection_container.dart';
import 'package:namichat_lite/core/theme/app_colors.dart';
import 'package:namichat_lite/core/theme/app_spacing.dart';
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(homeChatsProvider);
    final selectedIndex = ref.watch(homeNavigationProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NamiChat Lite'),
        actions: [
          IconButton(
            onPressed: () => context.go(RoutePaths.settings),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
          IconButton(
            onPressed: () => context.go(RoutePaths.profile),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: FlowSpacing.screenPadding,
          children: [
            FlowCard(
              padding: const EdgeInsets.all(FlowSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                           'Welcome back',
                           style: Theme.of(context).textTheme.titleMedium,
                         ),
                         const SizedBox(height: AppSpacing.xs),
                         Text(
                           'Your conversations are ready to continue.',
                           style: Theme.of(context).textTheme.headlineSmall,
                         ),
                         const SizedBox(height: AppSpacing.md),
                         Text(
                           'Jump into the latest chats, search for people, or start a new group.',
                           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                 color: scheme.onSurfaceVariant,
                               ),
                         ),
                      ],
                    ),
                  ),
                  const SizedBox(width: FlowSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(FlowSpacing.lg),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(FlowSpacing.radiusXl),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 32,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FlowSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: FlowButton(
                    onPressed: () => context.go(RoutePaths.userSearch),
                    label: 'Search',
                    icon: const Icon(Icons.search),
                    variant: FlowButtonVariant.outline,
                    fullWidth: false,
                  ),
                ),
                const SizedBox(width: FlowSpacing.md),
                Expanded(
                  child: FlowButton(
                    onPressed: () => context.push(RoutePaths.createGroup),
                    label: 'Create group',
                    icon: const Icon(Icons.group_add),
                    variant: FlowButtonVariant.secondary,
                    fullWidth: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FlowSpacing.xl),
            Row(
              children: [
                Text(
                  'Recent chats',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${chatsAsync.valueOrNull?.where((chat) => chat.unreadCount > 0).length ?? 0} unread',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: FlowSpacing.md),
            if (chatsAsync.isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: FlowSpacing.xl),
                child: CircularProgressIndicator(),
              ))
            else if (chatsAsync.hasError)
              FlowErrorState(
                message: chatsAsync.error.toString(),
                onRetry: () => ref.invalidate(homeChatsProvider),
              )
            else if (chatsAsync.valueOrNull == null || chatsAsync.valueOrNull!.isEmpty)
              FlowEmptyState(
                icon: Icons.forum_outlined,
                title: 'No conversations yet',
                description: 'Start a chat or create a group to bring your people together.',
                actionLabel: 'Create group',
                onAction: () => context.push(RoutePaths.createGroup),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chatsAsync.valueOrNull!.length,
                separatorBuilder: (_, __) => const SizedBox(height: FlowSpacing.md),
                itemBuilder: (context, index) {
                  final chat = chatsAsync.valueOrNull![index];
                  final hasUnread = chat.unreadCount > 0;
                  return FlowCard(
                    onTap: () => context.push(RoutePaths.chatWithId(chat.chatId)),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: chat.accentColor.withValues(alpha: 0.16),
                              child: Text(
                                chat.avatarLabel,
                                style: TextStyle(
                                  color: chat.accentColor,
                                  fontWeight: FontWeight.w700,
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
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: scheme.surface, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: FlowSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      chat.title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    chat.timestamp,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: FlowSpacing.xs),
                              Text(
                                chat.preview,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: FlowSpacing.md),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: FlowSpacing.sm,
                              vertical: FlowSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(FlowSpacing.radiusFull),
                            ),
                            child: Text(
                              '${chat.unreadCount}',
                               style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                     color: scheme.onPrimary,
                                     fontWeight: FontWeight.w700,
                                   ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (value) {
          ref.read(homeNavigationProvider.notifier).state = value;
          if (value == 1) {
            context.push(RoutePaths.groups);
          } else if (value == 2) {
            context.go(RoutePaths.profile);
          }
        },
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
    );
  }
}
