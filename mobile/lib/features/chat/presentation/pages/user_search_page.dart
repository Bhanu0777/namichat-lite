import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:namichat_lite/app/router/route_paths.dart';
import 'package:namichat_lite/core/theme/app_radius.dart';
import 'package:namichat_lite/core/theme/app_spacing.dart';
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
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Username, Nami ID or display name…',
                    hintStyle: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(Icons.search, size: AppSpacing.inputIcon),
                    prefixIconColor: scheme.onSurfaceVariant,
                    suffixIcon: state.hasQuery
                        ? IconButton(
                            icon: const Icon(Icons.close, size: AppSpacing.cameraIcon),
                            onPressed: _clearSearch,
                            tooltip: 'Clear',
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: scheme.primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: scheme.error, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: scheme.error, width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onQueryChanged,
                  onSubmitted: (v) {
                    _debounce?.cancel();
                    ref.read(chatSearchProvider.notifier).search(v);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
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
          const SizedBox(width: AppSpacing.sm),
          _chip(context, SearchFilter.username, 'Username'),
          const SizedBox(width: AppSpacing.sm),
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
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: isSelected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        side: BorderSide(
          color: isSelected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

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
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      itemCount: state.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
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
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          _UserAvatar(user: user),
          const SizedBox(width: AppSpacing.md),

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
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.alternate_email, size: AppSpacing.xs + 8),
                    const SizedBox(width: AppSpacing.tinyDot),
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
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.tinyDot,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(
                            AppRadius.full,
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
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
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

          const SizedBox(width: AppSpacing.md),

          isOpening
              ? SizedBox(
                  width: AppSpacing.iconSize,
                  height: AppSpacing.iconSize,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
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
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: AppSpacing.xs + 5, color: scheme.onPrimaryContainer),
            const SizedBox(width: AppSpacing.tinyDot),
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
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_comment_outlined, size: AppSpacing.xs + 5, color: scheme.onPrimary),
          const SizedBox(width: AppSpacing.tinyDot),
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

class _SearchSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
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
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: const Row(
        children: [
          FlowSkeleton(
            width: AppSpacing.xxxl,
            height: AppSpacing.xxxl,
            radius: AppRadius.full,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FlowSkeleton(width: 120, height: 14),
                SizedBox(height: AppSpacing.xs),
                FlowSkeleton(width: 80, height: 12),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          FlowSkeleton(width: 52, height: 26, radius: AppRadius.full),
        ],
      ),
    );
  }
}
