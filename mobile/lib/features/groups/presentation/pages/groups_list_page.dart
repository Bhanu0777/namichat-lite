import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:namichat_lite/app/router/route_paths.dart';
import 'package:namichat_lite/core/theme/app_gradients.dart';
import 'package:namichat_lite/core/theme/app_radius.dart';
import 'package:namichat_lite/design_system/app_shadows.dart';
import 'package:namichat_lite/design_system/app_spacing.dart';
import 'package:namichat_lite/design_system/flow.dart';
import 'package:namichat_lite/features/groups/domain/entities/group.dart';
import 'package:namichat_lite/features/groups/presentation/providers/groups_provider.dart';

class GroupsListPage extends ConsumerWidget {
  const GroupsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(groupsListProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Join by invite code',
            onPressed: () => context.push(RoutePaths.joinGroup),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RoutePaths.createGroup),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.brand,
            boxShadow: AppShadows.elevation2,
          ),
          child: InkWell(
            onTap: () => context.push(RoutePaths.createGroup),
            borderRadius: AppRadius.fab,
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),
      ),
      body: _Body(state: state, scheme: scheme, ref: ref),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.scheme,
    required this.ref,
  });

  final GroupsListState state;
  final ColorScheme scheme;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.groups.isEmpty) {
      return const Center(child: FlowPageLoader(label: 'Loading groups…'));
    }

    if (state.error != null && state.groups.isEmpty) {
      return FlowErrorState(
        message: state.error!,
        onRetry: () => ref.read(groupsListProvider.notifier).load(),
      );
    }

    if (state.groups.isEmpty) {
      return FlowEmptyState(
        icon: Icons.group_outlined,
        title: 'No groups yet',
        description:
            'Create a group or join one with an invite code.',
        actionLabel: 'Create group',
        onAction: () => context.push(RoutePaths.createGroup),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(groupsListProvider.notifier).load(),
      child: ListView.separated(
        padding: AppSpacing.listPadding,
        itemCount: state.groups.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) =>
            _GroupCard(group: state.groups[i]),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final scheme   = Theme.of(context).colorScheme;
    final hue      = (group.name.codeUnitAt(0) * 137.508) % 360;
    final accent   = HSLColor.fromAHSL(1, hue, 0.55, 0.45).toColor();
    final initials = group.name.isNotEmpty
        ? group.name[0].toUpperCase()
        : '?';

    return FlowCard(
      onTap: () => context.push(RoutePaths.groupDetail(group.id)),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundImage: group.avatarUrl != null
                ? NetworkImage(group.avatarUrl!)
                : null,
            backgroundColor: accent.withValues(alpha: 0.15),
            child: group.avatarUrl == null
                ? Text(
                    initials,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.people_outline,
                        size: 13, color: scheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.tinyDot),
                    Text(
                      '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    if (group.description != null &&
                        group.description!.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: AppSpacing.tinyDot,
                        height: AppSpacing.tinyDot,
                        decoration: BoxDecoration(
                          color: scheme.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          group.description!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: scheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Open chat shortcut
          if (group.chatId != null)
            IconButton(
              icon: Icon(Icons.chat_bubble_outline,
                  color: scheme.primary, size: 20),
              tooltip: 'Open chat',
              onPressed: () =>
                  context.push(RoutePaths.chatWithId(group.chatId!)),
            )
          else
            Icon(Icons.chevron_right,
                color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
