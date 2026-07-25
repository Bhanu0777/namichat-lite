import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:namichat_lite/core/di/injection_container.dart';
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
            accentColor: const Color(0xFF6C63FF),
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

class ChatsPage extends ConsumerWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(homeChatsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NamiChat Lite'),
            actions: [
              IconButton(
                onPressed: () => GoRouter.of(context).push(RoutePaths.userSearch),
                icon: const Icon(Icons.search),
                tooltip: 'Search',
              ),
              IconButton(
                onPressed: () => GoRouter.of(context).push(RoutePaths.createGroup),
                icon: const Icon(Icons.group_add),
                tooltip: 'Create group',
              ),
            ],
      ),
      body: SafeArea(
        child: ListView(
          padding: FlowSpacing.screenPadding,
          children: [
            if (chatsAsync.isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: FlowSpacing.xl),
                child: CircularProgressIndicator(),
              ))
            else if (chatsAsync.hasError)
              FlowErrorState(
                message: chatsAsync.error.toString(),
                title: 'Could not load chats',
                retryLabel: 'Retry',
                onRetry: () => ref.invalidate(homeChatsProvider),
              )
            else if (chatsAsync.valueOrNull == null || chatsAsync.valueOrNull!.isEmpty)
              FlowEmptyState(
                icon: Icons.forum_outlined,
                title: 'No conversations yet',
                description: 'Start a chat or create a group to bring your people together.',
                actionLabel: 'Create group',
                onAction: () => GoRouter.of(context).push(RoutePaths.createGroup),
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
                    onTap: () => GoRouter.of(context).push(RoutePaths.chatWithId(chat.chatId)),
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
                                  width: 12,
                                  height: 12,
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
                                      style: Theme.of(context).textTheme.titleSmall,
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
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
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
    );
  }
}
