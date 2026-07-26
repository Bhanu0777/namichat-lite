import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:namichat_lite/app/router/route_paths.dart';
import 'package:namichat_lite/design_system/app_spacing.dart';
import 'package:namichat_lite/design_system/flow.dart';
import 'package:namichat_lite/features/groups/presentation/providers/groups_provider.dart';

class JoinGroupPage extends ConsumerStatefulWidget {
  const JoinGroupPage({super.key});

  @override
  ConsumerState<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends ConsumerState<JoinGroupPage> {
  final _formKey  = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final group = await ref
        .read(groupsListProvider.notifier)
        .joinByCode(_codeCtrl.text.trim().toUpperCase());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (group != null) {
      context.go(RoutePaths.groupDetail(group.id));
    } else {
      final err = ref.read(groupsListProvider).error;
      FlowSnackBar.error(context, err ?? 'Invalid invite code');
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      _codeCtrl.text = data!.text!.trim().toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Join a group')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Hero illustration ----
                Center(
                  child: SizedBox(
                    width: AppSpacing.heroSize,
                    height: AppSpacing.heroSize,
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.group_add_outlined,
                        size: AppSpacing.heroSize,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  'Enter invite code',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Ask a group admin for their 8-character invite code.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ---- Code input ----
                FlowTextField(
                  controller: _codeCtrl,
                  hint: 'e.g. A3KP9XZW',
                  prefixIcon: const Icon(Icons.key_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.content_paste_outlined, size: AppSpacing.iconSize),
                    onPressed: _pasteFromClipboard,
                    tooltip: 'Paste',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _join(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter an invite code';
                    }
                    if (v.trim().length > 16) {
                      return 'Invite code is too long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),

                FlowButton(
                  onPressed: _isLoading ? null : _join,
                  label: 'Join group',
                  loading: _isLoading,
                  icon: const Icon(Icons.login),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
