import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:namichat_lite/app/router/route_paths.dart';
import 'package:namichat_lite/design_system/flow.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_provider.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_state.dart';
import 'package:namichat_lite/features/auth/presentation/validators/auth_validators.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).register(
          email: _emailController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authNotifierProvider);
    final isLoading = state.status == AuthStatus.authenticating;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(FlowSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
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
                      controller: _nameController,
                      label: 'Full name (optional)',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: FlowSpacing.md),
                    FlowTextField(
                      controller: _emailController,
                      label: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: AuthValidators.email,
                    ),
                    const SizedBox(height: FlowSpacing.md),
                    FlowTextField(
                      controller: _usernameController,
                      label: 'Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      textInputAction: TextInputAction.next,
                      validator: AuthValidators.username,
                    ),
                    const SizedBox(height: FlowSpacing.md),
                    FlowTextField(
                      controller: _passwordController,
                      label: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) => AuthValidators.password(v, minLength: 8),
                    ),
                    const SizedBox(height: FlowSpacing.xl),
                    FlowButton(
                      onPressed: isLoading ? null : _submit,
                      label: 'Create account',
                      loading: isLoading,
                    ),
                    const SizedBox(height: FlowSpacing.md),
                    TextButton(
                      onPressed: () => context.go(RoutePaths.login),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
