import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:namichat_lite/core/theme/app_radius.dart';
import 'package:namichat_lite/core/theme/app_spacing.dart';
import 'package:namichat_lite/design_system/flow.dart';
import 'package:namichat_lite/features/chat/domain/entities/message.dart';
import 'package:namichat_lite/features/chat/presentation/providers/chat_provider.dart';
import 'package:namichat_lite/features/chat/presentation/providers/chat_state.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();

  bool _atBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    _atBottom = pos.pixels >= pos.maxScrollExtent - 80;

    // Load older messages when the user reaches the very top.
    if (pos.pixels <= 120) {
      ref.read(chatNotifierProvider(widget.chatId).notifier).loadMoreHistory();
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    ref.read(chatNotifierProvider(widget.chatId).notifier).sendMessage(text);
    // Scroll after the frame so the optimistic message is rendered first.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatNotifierProvider(widget.chatId));
    final scheme = Theme.of(context).colorScheme;

    // Auto-scroll to bottom when a new message arrives and user is near bottom.
    ref.listen<ChatState>(chatNotifierProvider(widget.chatId), (prev, next) {
      if (next.messages.length != prev?.messages.length && _atBottom) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: _ChatAppBar(
        state: state,
        onReconnect: () =>
            ref.read(chatNotifierProvider(widget.chatId).notifier).reconnect(),
      ),
      body: Column(
        children: [
          // ---- Connection banner ----
          if (state.socketStatus == SocketStatus.disconnected ||
              state.socketStatus == SocketStatus.reconnecting ||
              state.socketStatus == SocketStatus.authError)
            _ConnectionBanner(
              status: state.socketStatus,
              onRetry: () =>
                  ref.read(chatNotifierProvider(widget.chatId).notifier).reconnect(),
            ),

          // ---- Message list ----
          Expanded(
            child: _MessageList(
              state: state,
              scrollController: _scrollController,
            ),
          ),

          // ---- Typing indicator ----
          if (state.typingUsernames.isNotEmpty)
            _TypingIndicator(usernames: state.typingUsernames),

          // ---- Input bar ----
          _InputBar(
            controller: _inputController,
            focusNode: _inputFocus,
            enabled: state.isConnected,
            onChanged: (_) =>
                ref.read(chatNotifierProvider(widget.chatId).notifier).notifyTyping(),
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar with online status
// ---------------------------------------------------------------------------

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({required this.state, required this.onReconnect});

  final ChatState state;
  final VoidCallback onReconnect;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOnline = state.isPeerOnline;

    final statusColor =
        isOnline ? FlowColors.success : scheme.onSurfaceVariant;
    final statusLabel = isOnline ? 'Online' : 'Offline';

    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          // Avatar placeholder
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              state.chatId.isNotEmpty
                  ? state.chatId[0].toUpperCase()
                  : '?',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chat',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Container(
                    width: AppSpacing.microDot,
                    height: AppSpacing.microDot,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
                         color: statusColor,
                         fontSize: AppSpacing.xs + 3,
                       ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (state.socketStatus == SocketStatus.disconnected ||
            state.socketStatus == SocketStatus.reconnecting ||
            state.socketStatus == SocketStatus.authError)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reconnect',
            onPressed: onReconnect,
          ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Connection status banner
// ---------------------------------------------------------------------------

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.status, required this.onRetry});

  final SocketStatus status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isError = status == SocketStatus.authError;
    final isReconnecting = status == SocketStatus.reconnecting;
    final label = isReconnecting
        ? 'Reconnecting…'
        : isError
            ? 'Auth error — please restart the app'
            : 'Disconnected — tap to retry';
    return Material(
      color: isError ? scheme.errorContainer : scheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onRetry,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isReconnecting
                    ? Icons.sync
                    : isError
                        ? Icons.lock_outline
                        : Icons.wifi_off,
                size: AppSpacing.cameraIcon,
                color: isError
                    ? scheme.onErrorContainer
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
                         color: scheme.onErrorContainer,
                         fontSize: AppSpacing.xs + 4,
                       ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message list
// ---------------------------------------------------------------------------

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.state,
    required this.scrollController,
  });

  final ChatState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingHistory && state.messages.isEmpty) {
      return const Center(child: FlowPageLoader(label: 'Loading messages…'));
    }

    if (state.historyError != null && state.messages.isEmpty) {
      return FlowErrorState(
        message: state.historyError!,
        title: 'Could not load messages',
      );
    }

    if (state.messages.isEmpty) {
      return const FlowEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        description: 'Send the first message to start the conversation.',
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: state.messages.length +
          (state.isLoadingHistory ? 1 : 0),
      itemBuilder: (context, index) {
        // Top-of-list spinner while loading older history.
        if (state.isLoadingHistory && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: FlowLoadingIndicator()),
          );
        }

        final msgIndex =
            state.isLoadingHistory ? index - 1 : index;
        final msg = state.messages[msgIndex];
        final isOwn = msg.senderId == state.currentUserId;

        // Date separator between messages from different days.
        final showDate = msgIndex == 0 ||
            !_sameDay(
              state.messages[msgIndex - 1].createdAt,
              msg.createdAt,
            );

        return Column(
          children: [
            if (showDate) _DateSeparator(date: msg.createdAt),
            _MessageBubble(message: msg, isOwn: isOwn),
          ],
        );
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ---------------------------------------------------------------------------
// Date separator
// ---------------------------------------------------------------------------

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    String label;
    if (_sameDay(date, now)) {
      label = 'Today';
    } else if (_sameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, y').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Divider(color: scheme.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
                 label,
                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
                       color: scheme.onSurfaceVariant,
                       fontWeight: FontWeight.w500,
                     ),
            ),
          ),
          Expanded(child: Divider(color: scheme.outlineVariant)),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isOwn});

  final Message message;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bgColor = isOwn ? scheme.primary : scheme.surfaceContainerHighest;
    final fgColor = isOwn ? scheme.onPrimary : scheme.onSurfaceVariant;
    final timeColor =
        isOwn ? scheme.onPrimary.withValues(alpha: 0.7) : scheme.onSurfaceVariant;

    const radius = Radius.circular(AppRadius.md);
    const tightRadius = Radius.circular(AppRadius.xs);

    final shape = BorderRadius.only(
      topLeft: radius,
      topRight: radius,
      bottomLeft: isOwn ? radius : tightRadius,
      bottomRight: isOwn ? tightRadius : radius,
    );

    return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: GestureDetector(
            onLongPress: () => _copyToClipboard(context, message.content),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: message.isPending
                    ? bgColor.withValues(alpha: 0.6)
                    : bgColor,
                borderRadius: shape,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Message text
                  Text(
                    message.content,
                    style: TextStyle(
                      color: fgColor,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Timestamp + delivery status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: TextStyle(fontSize: 10, color: timeColor),
                      ),
                      if (isOwn) ...[
                          const SizedBox(width: AppSpacing.tinyDot),
                        Icon(
                          message.isPending
                              ? Icons.access_time
                              : Icons.done,
                          size: 12,
                          color: timeColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Typing indicator
// ---------------------------------------------------------------------------

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.usernames});

  final Set<String> usernames;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _dot1;
  late Animation<double> _dot2;
  late Animation<double> _dot3;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dot1 = _bounce(0.0);
    _dot2 = _bounce(0.2);
    _dot3 = _bounce(0.4);
  }

  Animation<double> _bounce(double delay) => TweenSequence([
        TweenSequenceItem(
            tween: Tween(begin: 0.0, end: -6.0)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 30),
        TweenSequenceItem(
            tween: Tween(begin: -6.0, end: 0.0)
                .chain(CurveTween(curve: Curves.easeIn)),
            weight: 30),
        TweenSequenceItem(
            tween: ConstantTween(0.0),
            weight: 40),
      ]).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(delay, delay + 0.6, curve: Curves.linear),
        ),
      );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final names = widget.usernames.take(2).join(', ');
    final label = widget.usernames.length == 1
        ? '$names is typing…'
        : '$names are typing…';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Bouncing dots
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(
              children: [
                _dot(scheme, _dot1.value),
                const SizedBox(width: 3),
                _dot(scheme, _dot2.value),
                const SizedBox(width: 3),
                _dot(scheme, _dot3.value),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
                       color: scheme.onSurfaceVariant,
                       fontSize: AppSpacing.xs + 3,
                       fontStyle: FontStyle.italic,
                     ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(ColorScheme scheme, double dy) => Transform.translate(
        offset: Offset(0, dy),
        child: SizedBox(
          width: AppSpacing.microDot,
          height: AppSpacing.microDot,
          child: Container(
            width: AppSpacing.microDot,
            height: AppSpacing.microDot,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Input bar
// ---------------------------------------------------------------------------

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text field
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChanged: onChanged,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: enabled ? 'Type a message…' : 'Connecting…',
                    hintStyle: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.lg),
                      borderSide:
                          BorderSide(color: scheme.primary, width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Send button
            _SendButton(enabled: enabled, onSend: onSend),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onSend});

  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: AppSpacing.sendButton,
      height: AppSpacing.sendButton,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled ? scheme.primary : scheme.surfaceContainerHighest,
      ),
      child: IconButton(
        onPressed: enabled ? onSend : null,
        icon: Icon(
          Icons.send_rounded,
          size: AppSpacing.iconSize,
          color: enabled ? scheme.onPrimary : scheme.onSurfaceVariant,
        ),
        padding: EdgeInsets.zero,
        tooltip: 'Send',
      ),
    );
  }
}
