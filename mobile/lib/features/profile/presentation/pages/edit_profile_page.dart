import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namichat_lite/design_system/flow.dart';
import 'package:namichat_lite/features/profile/presentation/providers/profile_provider.dart';
import 'package:namichat_lite/features/profile/presentation/providers/profile_state.dart';
import 'package:namichat_lite/features/profile/presentation/validators/profile_validators.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
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
    final user = ref.read(profileNotifierProvider).user;
    _emailController = TextEditingController(text: user?.email ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _displayNameController = TextEditingController(text: user?.displayName ?? '');
    _namiIdController = TextEditingController(text: user?.namiId ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _avatarUrlController = TextEditingController(text: user?.avatarUrl ?? '');
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
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileNotifierProvider);
    final isLoading = state.status == ProfileStatus.updating;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FlowSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: FlowSpacing.md),
                    child: FlowErrorBanner(message: state.errorMessage!),
                  ),
                FlowTextField(
                  controller: _avatarUrlController,
                  label: 'Avatar URL',
                  hint: 'https://example.com/avatar.png',
                ),
                const SizedBox(height: FlowSpacing.md),
                FlowTextField(
                  controller: _emailController,
                  label: 'Email',
                  validator: ProfileValidators.email,
                ),
                const SizedBox(height: FlowSpacing.md),
                FlowTextField(
                  controller: _usernameController,
                  label: 'Username',
                  validator: ProfileValidators.username,
                ),
                const SizedBox(height: FlowSpacing.md),
                FlowTextField(
                  controller: _displayNameController,
                  label: 'Display name',
                ),
                const SizedBox(height: FlowSpacing.md),
                FlowTextField(
                  controller: _namiIdController,
                  label: 'Nami ID',
                  validator: ProfileValidators.namiId,
                ),
                const SizedBox(height: FlowSpacing.md),
                FlowTextField(
                  controller: _bioController,
                  label: 'Bio',
                  maxLines: 4,
                  validator: ProfileValidators.bio,
                ),
                const SizedBox(height: FlowSpacing.xl),
                FlowButton(
                  onPressed: isLoading ? null : _submit,
                  label: 'Save changes',
                  loading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
