import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:namichat_lite/app/router/route_paths.dart';
import 'package:namichat_lite/core/theme/app_colors.dart';
import 'package:namichat_lite/core/theme/app_gradients.dart';
import 'package:namichat_lite/core/theme/app_shadows.dart';
import 'package:namichat_lite/core/theme/app_spacing.dart';
import 'package:namichat_lite/core/theme/app_typography.dart';
import 'package:namichat_lite/design_system/app_animation.dart';
import 'package:namichat_lite/design_system/flow.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_provider.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_state.dart';
import 'package:namichat_lite/features/auth/presentation/validators/auth_validators.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppAnimation.splash,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppAnimation.gentle,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppGradients.brand,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                isSmallScreen ? AppSpacing.lg : AppSpacing.xl,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Back button + App name
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              label: 'Go back',
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded),
                                color: AppColors.primaryText,
                                onPressed: () => context.go(RoutePaths.login),
                                tooltip: 'Back to login',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Semantics(
                              label: 'NamiChat Lite title',
                              child: Text(
                                'NamiChat Lite',
                                style: AppTypography.subtitle().copyWith(
                                  color: AppColors.primaryText,
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: isSmallScreen ? AppSpacing.md : AppSpacing.lg,
                        ),

                        // Logo
                        Semantics(
                          label: 'NamiChat logo',
                          child: _AuthLogo(size: isSmallScreen ? 40 : 48),
                        ),
                        SizedBox(
                          height: isSmallScreen ? AppSpacing.md : AppSpacing.sm,
                        ),
                        Semantics(
                          label: 'Tagline: Every Wave Connects',
                          child: Text(
                            'Every Wave Connects',
                            style: AppTypography.subtitle().copyWith(
                              color: AppColors.primaryText.withValues(alpha: 0.85),
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: isSmallScreen ? AppSpacing.lg : AppSpacing.xl,
                        ),

                        // Glass card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                            isSmallScreen ? AppSpacing.lg : AppSpacing.xl,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppShadows.elevation3,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Heading
                              Semantics(
                                label: 'Create account heading',
                                child: Text(
                                  'Create account',
                                  style: AppTypography.heading().copyWith(
                                    fontSize: isSmallScreen ? 18 : 22,
                                    color: AppColors.text,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                height: isSmallScreen ? AppSpacing.xs : AppSpacing.sm,
                              ),
                              Text(
                                'Join the conversation',
                                style: AppTypography.subtitle().copyWith(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  color: AppColors.secondaryText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                height: isSmallScreen ? AppSpacing.lg : AppSpacing.xl,
                              ),

                              // Error banner
                              if (state.errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: FlowErrorBanner(
                                    message: state.errorMessage!,
                                  ),
                                ),

                              // Full name field
                              Semantics(
                                label: 'Full name input',
                                child: FlowTextField(
                                  controller: _nameController,
                                  label: 'Full name (optional)',
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Email field
                              Semantics(
                                label: 'Email input',
                                child: FlowTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: AuthValidators.email,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Username field
                              Semantics(
                                label: 'Username input',
                                child: FlowTextField(
                                  controller: _usernameController,
                                  label: 'Username',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  textInputAction: TextInputAction.next,
                                  validator: AuthValidators.username,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Password field
                              Semantics(
                                label: 'Password input',
                                child: FlowTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  obscureText: _obscurePassword,
                                  suffixIcon: Semantics(
                                    label: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    child: IconButton(
                                      icon: AnimatedSwitcher(
                                        duration: AppAnimation.fast,
                                        child: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          key: ValueKey(_obscurePassword),
                                        ),
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submit(),
                                  validator: (v) => AuthValidators.password(
                                    v,
                                    minLength: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              // Create account button
                              FlowButton(
                                onPressed: isLoading ? null : _submit,
                                label: 'Create account',
                                loading: isLoading,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: isSmallScreen ? AppSpacing.md : AppSpacing.lg,
                        ),

                        // Sign in link
                        Semantics(
                          label: 'Navigate to login page',
                          child: TextButton(
                            onPressed: () => context.go(RoutePaths.login),
                            child: RichText(
                              text: TextSpan(
                                style: AppTypography.subtitle().copyWith(
                                  fontSize: 14,
                                  color: AppColors.primaryText.withValues(alpha: 0.9),
                                ),
                                children: const [
                                  TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Sign in',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo({this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 2,
      height: size * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.primary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: AppShadows.glow(AppColors.primary),
          ),
          child: Icon(
            Icons.chat_bubble_rounded,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}
