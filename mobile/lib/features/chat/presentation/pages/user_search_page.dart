import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:namichat_lite/app/router/route_paths.dart';
import 'package:namichat_lite/design_system/flow.dart';
import 'package:namichat_lite/features/chat/domain/entities/user_search_result.dart';
import 'package:namichat_lite/features/chat/presentation/providers/chat_search_provider.dart';

class UserSearchPage extends ConsumerStatefulWidget {
  const UserSearchPage({super.key});

  @override
  ConsumerState<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends ConsumerState<UserSearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    ref.read(chatSearchProvider.notifier).updateQuery(value);
    _debounce?.cancel();
    if (value.trim().isNotEmpty) {
      _debounce = Timer(const Duration(milliseconds: 400), () {
        ref.read(chatSearchProvider.notifier).search(value);
      });
    }
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(chatSearchProvider.notifier).updateQuery('');
  }

  Future<void> _onUserTapped(UserSearchResult user) async {
    // If chat already known, navigate immediately — no network call.
    if (user.hasChatAlready) {
      if (mounted) unawaited(context.push(RoutePaths.chatWithId(user.existingChatId!)));
      return;
    }

    final chatId =
        await ref.read(chatSearchProvider.notifier).openChat(user);
    if (!mounted) return;

    if (chatId != null) {
      unawaited(context.push(RoutePaths.chatWithId(chatId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatSearchProvider);
    final scheme = Theme.of(context).colorScheme;

    // Show open-chat error as a snackbar.
    ref.listen<ChatSearchState>(chatSearchProvider, (prev, next) {
      if (next.openChatError != null &&
          prev?.openChatError != next.openChatError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.openChatError!),
            backgroundColor: scheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(chatSearchProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find people'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FlowSpacing.lg,
              0,
              FlowSpacing.lg,
              FlowSpacing.md,
            ),
            child: Column(
              children: [
                // ---- Search field ----
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Username, Nami ID or display name…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: state.hasQuery
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: _clearSearch,
                            tooltip: 'Clear',
                          )
                        : null,
                  ),
                  onChanged: _onQueryChanged,
                  onSubmitted: (v) {
                    _debounce?.cancel();
                    ref.read(chatSearchProvider.notifier).search(v);
                  },
                ),
                const SizedBox(height: FlowSpacing.sm),
                // ---- Filter chips ----
                _FilterChips(
                  selected: state.filter,
                  onChanged: (f) =>
                      ref.read(chatSearchProvider.notifier).setFilter(f),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _Body(
        state: state,
        onUserTapped: _onUserTapped,
        onRetry: () =>
            ref.read(chatSearchProvider.notifier).search(state.query),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chips row
// ---------------------------------------------------------------------------

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onChanged,
  });

  final SearchFilter selected;
  final ValueChanged<SearchFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(context, SearchFilter.all, 'All'),
          const SizedBox(width: FlowSpacing.sm),
          _chip(context, SearchFilter.username, 'Username'),
          const SizedBox(width: FlowSpacing.sm),
          _chip(context, SearchFilter.namiId, 'Nami ID'),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, SearchFilter filter, String label) {
    final isSelected = selected == filter;
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onChanged(filter),
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FlowSpacing.radiusFull),
        side: BorderSide(
          color: isSelected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: FlowSpacing.sm),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ---------------------------------------------------------------------------
// Body — delegates between loading / error / empty / results
// ---------------------------------------------------------------------------

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.onUserTapped,
    required this.onRetry,
  });

  final ChatSearchState state;
  final Future<void> Function(UserSearchResult) onUserTapped;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isSearching) {
      return _SearchSkeleton();
    }

    if (state.searchError != null) {
      return FlowErrorState(
        message: state.searchError!,
        onRetry: onRetry,
      );
    }

    if (!state.hasQuery) {
      return const FlowEmptyState(
        icon: Icons.person_search_outlined,
        title: 'Find someone to chat with',
        description:
            'Search by username, Nami ID or display name to start a private conversation.',
      );
    }

    if (!state.hasResults) {
      return FlowEmptyState(
        icon: Icons.search_off_outlined,
        title: 'No results for "${state.query}"',
        description: 'Try a different username or Nami ID.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: FlowSpacing.lg,
        vertical: FlowSpacing.md,
      ),
      itemCount: state.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: FlowSpacing.sm),
      itemBuilder: (context, index) {
        final user = state.results[index];
        return _UserTile(
          user: user,
          isOpening: state.openingChatForUserId == user.id,
          onTap: () => onUserTapped(user),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Individual user tile
// ---------------------------------------------------------------------------

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.isOpening,
    required this.onTap,
  });

  final UserSearchResult user;
  final bool isOpening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasChat = user.hasChatAlready;

    return FlowCard(
      onTap: isOpening ? null : onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: FlowSpacing.lg,
        vertical: FlowSpacing.md,
      ),
      child: Row(
        children: [
          // ---- Avatar ----
          _UserAvatar(user: user),
          const SizedBox(width: FlowSpacing.md),

          // ---- Name / username / nami id ----
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayLabel,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: FlowSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.alternate_email, size: 12),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        user.username,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.namiId != null) ...[
                      const SizedBox(width: FlowSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(
                            FlowSpacing.radiusFull,
                          ),
                        ),
                        child: Text(
                          user.namiId!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (user.bio != null && user.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: FlowSpacing.xs),
                    child: Text(
                      user.bio!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: FlowSpacing.md),

          // ---- Action button / loader ----
          isOpening
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                )
              : _ActionBadge(hasChat: hasChat, scheme: scheme),
        ],
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.hasChat, required this.scheme});

  final bool hasChat;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (hasChat) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FlowSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(FlowSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 13, color: scheme.onPrimaryContainer),
            const SizedBox(width: 4),
            Text(
              'Open',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlowSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(FlowSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_comment_outlined, size: 13, color: scheme.onPrimary),
          const SizedBox(width: 4),
          Text(
            'Chat',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final UserSearchResult user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials =
        (user.displayLabel.isNotEmpty ? user.displayLabel[0] : '?')
            .toUpperCase();

    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(user.avatarUrl!),
        backgroundColor: scheme.primaryContainer,
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    // Derive a stable accent color from the first char of the username.
    final hue = (user.username.codeUnitAt(0) * 137.508) % 360;
    final accent = HSLColor.fromAHSL(1, hue, 0.55, 0.45).toColor();

    return CircleAvatar(
      radius: 24,
      backgroundColor: accent.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loader shown while searching
// ---------------------------------------------------------------------------

class _SearchSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: FlowSpacing.lg,
        vertical: FlowSpacing.md,
      ),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: FlowSpacing.sm),
      itemBuilder: (_, __) => const _SkeletonTile(),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    return FlowCard(
      padding: const EdgeInsets.symmetric(
        horizontal: FlowSpacing.lg,
        vertical: FlowSpacing.md,
      ),
      child: const Row(
        children: [
          FlowSkeleton(
            width: 48,
            height: 48,
            radius: FlowSpacing.radiusFull,
          ),
          SizedBox(width: FlowSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FlowSkeleton(width: 120, height: 14),
                SizedBox(height: FlowSpacing.xs),
                FlowSkeleton(width: 80, height: 12),
              ],
            ),
          ),
          SizedBox(width: FlowSpacing.md),
          FlowSkeleton(width: 52, height: 26, radius: FlowSpacing.radiusFull),
        ],
      ),
    );
  }
}
