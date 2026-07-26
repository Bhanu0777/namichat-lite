import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:namichat_lite/app/router/route_paths.dart';
import 'package:namichat_lite/core/theme/app_spacing.dart';
import 'package:namichat_lite/design_system/flow.dart';
import 'package:namichat_lite/features/profile/presentation/providers/profile_provider.dart';
import 'package:namichat_lite/features/profile/presentation/providers/profile_state.dart';
import 'package:namichat_lite/features/profile/presentation/validators/profile_validators.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _usernameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _namiIdController;
  late final TextEditingController _bioController;
  late final TextEditingController _avatarUrlController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _usernameController = TextEditingController();
    _displayNameController = TextEditingController();
    _namiIdController = TextEditingController();
    _bioController = TextEditingController();
    _avatarUrlController = TextEditingController();
    Future.microtask(() => ref.read(profileNotifierProvider.notifier).load());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _namiIdController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _bind(ProfileState state) {
    final user = state.user;
    if (user == null) return;
    if (_emailController.text != user.email) _emailController.text = user.email;
    if (_usernameController.text != user.username) _usernameController.text = user.username;
    if (_displayNameController.text != (user.displayName ?? '')) {
      _displayNameController.text = user.displayName ?? '';
    }
    if (_namiIdController.text != (user.namiId ?? '')) {
      _namiIdController.text = user.namiId ?? '';
    }
    if (_bioController.text != (user.bio ?? '')) {
      _bioController.text = user.bio ?? '';
    }
    if (_avatarUrlController.text != (user.avatarUrl ?? '')) {
      _avatarUrlController.text = user.avatarUrl ?? '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(profileNotifierProvider.notifier).update(
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      displayName: _displayNameController.text.trim().isEmpty
          ? null
          : _displayNameController.text.trim(),
      namiId: _namiIdController.text.trim().isEmpty
          ? null
          : _namiIdController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      avatarUrl: _avatarUrlController.text.trim().isEmpty
          ? null
          : _avatarUrlController.text.trim(),
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileNotifierProvider);
    _bind(state);
    final isLoading = state.status == ProfileStatus.loading || state.status == ProfileStatus.updating;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.go(RoutePaths.home),
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: state.status == ProfileStatus.loading && state.user == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: FlowErrorBanner(message: state.errorMessage!),
                          ),
                        Center(
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(Icons.person_outline, size: AppSpacing.tileIcon),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FlowTextField(
                          controller: _avatarUrlController,
                          label: 'Avatar URL',
                          hint: 'https://example.com/avatar.png',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FlowTextField(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: ProfileValidators.email,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FlowTextField(
                          controller: _usernameController,
                          label: 'Username',
                          validator: ProfileValidators.username,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FlowTextField(
                          controller: _displayNameController,
                          label: 'Display name',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FlowTextField(
                          controller: _namiIdController,
                          label: 'Nami ID',
                          hint: 'e.g. nami-hero',
                          validator: ProfileValidators.namiId,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FlowTextField(
                          controller: _bioController,
                          label: 'Bio',
                          maxLines: 3,
                          validator: ProfileValidators.bio,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const SizedBox(height: AppSpacing.md),
                        FlowButton(
                          onPressed: isLoading ? null : _submit,
                          label: 'Save profile',
                          loading: isLoading,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FlowButton(
                          onPressed: () => context.go(RoutePaths.editProfile),
                          label: 'Edit profile',
                          variant: FlowButtonVariant.outline,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
