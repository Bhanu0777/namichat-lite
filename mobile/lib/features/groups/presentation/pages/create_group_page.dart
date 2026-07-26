import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:namichat_lite/app/router/route_paths.dart';
import 'package:namichat_lite/design_system/app_spacing.dart';
import 'package:namichat_lite/design_system/flow.dart';
import 'package:namichat_lite/features/groups/presentation/providers/groups_provider.dart';

class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _isLoading  = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final group = await ref.read(groupsListProvider.notifier).createGroup(
          name:        _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (group != null) {
      // Navigate straight into the group detail / chat.
      context.go(RoutePaths.groupDetail(group.id));
    } else {
      final err = ref.read(groupsListProvider).error;
      FlowSnackBar.error(context, err ?? 'Could not create group');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Avatar placeholder ----
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(
                          Icons.group,
                           size: AppSpacing.groupAvatar,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: scheme.surface, width: 2),
                          ),
                          child: Icon(Icons.camera_alt,
                              size: AppSpacing.cameraIcon, color: scheme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ---- Group name ----
                Text('Group name',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                FlowTextField(
                  controller: _nameCtrl,
                  hint: 'e.g. Design Crew, Study Group…',
                  prefixIcon: const Icon(Icons.group_outlined),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Group name is required';
                    }
                    if (v.trim().length > 128) {
                      return 'Name must be 128 characters or fewer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ---- Description ----
                Text('Description (optional)',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                FlowTextField(
                  controller: _descCtrl,
                  hint: "What's this group about?",
                  prefixIcon: const Icon(Icons.notes_outlined),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v != null && v.trim().length > 500) {
                      return 'Description must be 500 characters or fewer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // ---- Info box ----
                FlowCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                                                     size: AppSpacing.infoIcon, color: scheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'An invite code is generated automatically. '
                          'Share it so others can join.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ---- Submit ----
                FlowButton(
                  onPressed: _isLoading ? null : _submit,
                  label: 'Create group',
                  loading: _isLoading,
                  icon: const Icon(Icons.check),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
