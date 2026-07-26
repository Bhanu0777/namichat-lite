import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:namichat_lite/app/router/route_paths.dart';
import 'package:namichat_lite/core/theme/app_spacing.dart';
import 'package:namichat_lite/design_system/flow.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_provider.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_state.dart';
import 'package:namichat_lite/features/auth/presentation/validators/auth_validators.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).login(
          _identifierController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authNotifierProvider);
    final isLoading = state.status == AuthStatus.authenticating;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AppLogo(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Sign in to continue to NamiChat Lite',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: FlowErrorBanner(message: state.errorMessage!),
                      ),
                    FlowTextField(
                      controller: _identifierController,
                      label: 'Email or username',
                      prefixIcon: const Icon(Icons.person_outline),
                      textInputAction: TextInputAction.next,
                      validator: (v) => AuthValidators.required(v, label: 'Email or username'),
                    ),
                    const SizedBox(height: AppSpacing.md),
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
                      validator: (v) => AuthValidators.password(v, minLength: 1),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FlowButton(
                      onPressed: isLoading ? null : _submit,
                      label: 'Sign in',
                      loading: isLoading,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => context.go(RoutePaths.register),
                      child: const Text('Create an account'),
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

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 36,
      backgroundColor: scheme.primaryContainer,
      child: Icon(
        Icons.chat_bubble_outline,
         size: AppSpacing.logoSize,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}
