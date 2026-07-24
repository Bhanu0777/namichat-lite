import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:namichat_lite/app/router/route_paths.dart';
import 'package:namichat_lite/design_system/flow.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_provider.dart';
import 'package:namichat_lite/features/groups/domain/entities/group.dart';
import 'package:namichat_lite/features/groups/presentation/providers/groups_provider.dart';

class GroupDetailPage extends ConsumerWidget {
  const GroupDetailPage({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupDetailProvider(groupId));

    // Show action errors as snackbars.
    ref.listen<GroupDetailState>(groupDetailProvider(groupId), (prev, next) {
      if (next.actionError != null &&
          prev?.actionError != next.actionError) {
        FlowSnackBar.error(context, next.actionError!);
        ref.read(groupDetailProvider(groupId).notifier).clearActionError();
      }
    });

    if (state.isLoading && state.group == null) {
      return const Scaffold(
        body: Center(child: FlowPageLoader(label: 'Loading group…')),
      );
    }

    if (state.error != null && state.group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: FlowErrorState(
          message: state.error!,
          onRetry: () =>
              ref.read(groupDetailProvider(groupId).notifier).load(),
        ),
      );
    }

    final group = state.group!;
    return _GroupDetailScaffold(group: group, groupId: groupId);
  }
}

// ── Main scaffold ─────────────────────────────────────────────────────────

class _GroupDetailScaffold extends ConsumerWidget {
  const _GroupDetailScaffold({required this.group, required this.groupId});

  final Group group;
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId =
        ref.watch(authNotifierProvider).user?.id ?? '';
    final isOwner = group.isOwner(currentUserId);
    final isAdmin = group.isAdmin(currentUserId);
    final state   = ref.watch(groupDetailProvider(groupId));
    final scheme  = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar with group avatar ──────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              if (isOwner || isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit group',
                  onPressed: () =>
                      _showEditDialog(context, ref, group),
                ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete group',
                  onPressed: () =>
                      _confirmDelete(context, ref),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                group.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: FlowColors.waveGradient(
                    Theme.of(context).brightness,
                  ),
                ),
                child: group.avatarUrl != null
                    ? Image.network(group.avatarUrl!, fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          Icons.group,
                          size: 72,
                          color:
                              scheme.onPrimaryContainer.withValues(alpha: 0.6),
                        ),
                      ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: FlowSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Description ──────────────────────────────────────
                  if (group.description != null &&
                      group.description!.isNotEmpty) ...[
                    Text(
                      group.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: FlowSpacing.lg),
                  ],

                  // ── Open chat button ──────────────────────────────────
                  if (group.chatId != null)
                    FlowButton(
                      onPressed: () =>
                          context.push(RoutePaths.chatWithId(group.chatId!)),
                      label: 'Open group chat',
                      icon: const Icon(Icons.chat_bubble_outline),
                    ),

                  const SizedBox(height: FlowSpacing.lg),

                  // ── Invite code card ──────────────────────────────────
                  _InviteCodeCard(
                    group: group,
                    isOwner: isOwner,
                    isLoading: state.isLoading,
                    onRegenerate: () => ref
                        .read(groupDetailProvider(groupId).notifier)
                        .regenerateInviteCode(),
                  ),

                  const SizedBox(height: FlowSpacing.xl),

                  // ── Members section header ───────────────────────────
                  Row(
                    children: [
                      Text(
                        'Members',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: FlowSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(
                              FlowSpacing.radiusFull),
                        ),
                        child: Text(
                          '${group.memberCount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Members list ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              FlowSpacing.lg, 0, FlowSpacing.lg, FlowSpacing.xxl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final member = group.members[i];
                  return _MemberTile(
                    member: member,
                    ownerId: group.ownerId,
                    currentUserId: currentUserId,
                    isAdminOrOwner: isAdmin || isOwner,
                    isOwner: isOwner,
                    onRemove: () => _confirmRemoveMember(
                        context, ref, member),
                    onPromote: () => ref
                        .read(groupDetailProvider(groupId).notifier)
                        .promoteMember(member.userId),
                  );
                },
                childCount: group.members.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Group group,
  ) {
    final nameCtrl = TextEditingController(text: group.name);
    final descCtrl =
        TextEditingController(text: group.description ?? '');
    final formKey  = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit group'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Group name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration:
                    const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              await ref
                  .read(groupDetailProvider(groupId).notifier)
                  .updateGroup(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim(),
                  );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete group?'),
        content: const Text(
          'This will permanently delete the group and all its messages. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await ref
          .read(groupDetailProvider(groupId).notifier)
          .deleteGroup();
      if (ok && context.mounted) {
        ref.invalidate(groupDetailProvider(groupId));
        // Sync the list so the deleted group disappears immediately.
        ref.read(groupsListProvider.notifier).deleteGroup(groupId);
        context.go(RoutePaths.home);
      }
    }
  }

  Future<void> _confirmRemoveMember(
    BuildContext context,
    WidgetRef ref,
    GroupMember member,
  ) async {
    final currentUserId =
        ref.read(authNotifierProvider).user?.id ?? '';
    final isSelf = member.userId == currentUserId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isSelf ? 'Leave group?' : 'Remove member?'),
        content: Text(
          isSelf
              ? 'You will no longer have access to this group.'
              : 'Remove ${member.displayLabel} from the group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isSelf ? 'Leave' : 'Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await ref
          .read(groupDetailProvider(groupId).notifier)
          .removeMember(member.userId);
      if (ok && isSelf && context.mounted) {
        // Remove from list so it disappears immediately.
        ref.read(groupsListProvider.notifier).deleteGroup(groupId);
        context.go(RoutePaths.home);
      }
    }
  }
}

// ── Invite code card ──────────────────────────────────────────────────────

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({
    required this.group,
    required this.isOwner,
    required this.isLoading,
    required this.onRegenerate,
  });

  final Group group;
  final bool isOwner;
  final bool isLoading;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FlowCard(
      padding: const EdgeInsets.all(FlowSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: FlowSpacing.sm),
              Text(
                'Invite code',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: FlowSpacing.md),

          // Code display
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FlowSpacing.lg,
              vertical: FlowSpacing.md,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius:
                  BorderRadius.circular(FlowSpacing.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  group.inviteCode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: scheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  tooltip: 'Copy code',
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: group.inviteCode));
                    FlowSnackBar.success(context, 'Invite code copied');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: FlowSpacing.sm),

          Text(
            'Share this code to invite people to the group.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),

          if (isOwner) ...[
            const SizedBox(height: FlowSpacing.md),
            FlowButton(
              onPressed: isLoading ? null : onRegenerate,
              label: 'Regenerate code',
              variant: FlowButtonVariant.outline,
              size: FlowButtonSize.small,
              loading: isLoading,
              icon: const Icon(Icons.refresh, size: 16),
              fullWidth: false,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Member tile ───────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.ownerId,
    required this.currentUserId,
    required this.isAdminOrOwner,
    required this.isOwner,
    required this.onRemove,
    required this.onPromote,
  });

  final GroupMember member;
  final String ownerId;
  final String currentUserId;
  final bool isAdminOrOwner;
  final bool isOwner;
  final VoidCallback onRemove;
  final VoidCallback onPromote;

  @override
  Widget build(BuildContext context) {
    final scheme   = Theme.of(context).colorScheme;
    final isSelf   = member.userId == currentUserId;
    final isGroupOwner = member.userId == ownerId;

    // Derive initials + stable avatar color.
    final label   = member.displayLabel;
    final initials = label.isNotEmpty ? label[0].toUpperCase() : '?';
    final hue     = (member.username.codeUnitAt(0) * 137.508) % 360;
    final accent  = HSLColor.fromAHSL(1, hue, 0.55, 0.45).toColor();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FlowSpacing.xs),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundImage: member.avatarUrl != null
                ? NetworkImage(member.avatarUrl!)
                : null,
            backgroundColor: accent.withValues(alpha: 0.15),
            child: member.avatarUrl == null
                ? Text(
                    initials,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: FlowSpacing.md),

          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isSelf ? '$label (you)' : label,
                        style:
                            Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isGroupOwner) ...[
                      const SizedBox(width: FlowSpacing.xs),
                      _RoleBadge(
                          label: 'Owner', color: scheme.primary),
                    ] else if (member.isAdmin) ...[
                      const SizedBox(width: FlowSpacing.xs),
                      _RoleBadge(
                          label: 'Admin',
                          color: scheme.secondary),
                    ],
                  ],
                ),
                Text(
                  '@${member.username}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),

          // Actions — shown when current user is admin/owner and
          // target is not the owner themselves.
          if (!isGroupOwner && (isAdminOrOwner || isSelf))
            PopupMenuButton<_MemberAction>(
              icon: Icon(Icons.more_vert,
                  color: scheme.onSurfaceVariant, size: 20),
              onSelected: (action) {
                switch (action) {
                  case _MemberAction.remove:
                    onRemove();
                  case _MemberAction.promote:
                    onPromote();
                }
              },
              itemBuilder: (_) => [
                if (isOwner && !member.isAdmin)
                  const PopupMenuItem(
                    value: _MemberAction.promote,
                    child: ListTile(
                      leading: Icon(Icons.admin_panel_settings_outlined),
                      title: Text('Make admin'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                PopupMenuItem(
                  value: _MemberAction.remove,
                  child: ListTile(
                    leading: Icon(
                      isSelf ? Icons.logout : Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    title: Text(
                      isSelf ? 'Leave group' : 'Remove',
                      style: const TextStyle(color: Colors.red),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

enum _MemberAction { remove, promote }

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius:
              BorderRadius.circular(FlowSpacing.radiusFull),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
}
