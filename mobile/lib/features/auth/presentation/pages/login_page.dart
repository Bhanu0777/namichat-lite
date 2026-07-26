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

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
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
    _identifierController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
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
                        // Logo
                        Semantics(
                          label: 'NamiChat logo',
                          child: _AuthLogo(size: isSmallScreen ? 48 : 56),
                        ),
                        SizedBox(
                          height: isSmallScreen ? AppSpacing.lg : AppSpacing.xl,
                        ),

                        // App name and tagline
                        Semantics(
                          label: 'App name: NamiChat Lite',
                          child: Text(
                            'NamiChat Lite',
                            style: AppTypography.heading().copyWith(
                              color: AppColors.primaryText,
                              fontSize: isSmallScreen ? 22 : 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Semantics(
                          label: 'Tagline: Every Wave Connects',
                          child: Text(
                            'Every Wave Connects',
                            style: AppTypography.subtitle().copyWith(
                              color: AppColors.primaryText.withValues(alpha: 0.85),
                              fontSize: isSmallScreen ? 13 : 15,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: isSmallScreen ? AppSpacing.xl : AppSpacing.xxl,
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
                              Semantics(
                                label: 'Welcome heading',
                                child: Text(
                                  'Welcome back',
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
                                'Sign in to continue',
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

                              // Identifier field
                              FlowTextField(
                                controller: _identifierController,
                                label: 'Email or username',
                                prefixIcon: Semantics(
                                  label: 'Email or username icon',
                                  child: const Icon(Icons.person_outline),
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (v) => AuthValidators.required(
                                  v,
                                  label: 'Email or username',
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Password field
                              FlowTextField(
                                controller: _passwordController,
                                label: 'Password',
                                prefixIcon: Semantics(
                                  label: 'Password icon',
                                  child: const Icon(Icons.lock_outline),
                                ),
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
                                  minLength: 1,
                                ),
                              ),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // Placeholder — no functionality
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: Text(
                                    'Forgot password?',
                                    style: AppTypography.caption().copyWith(
                                      color: AppColors.primary.withValues(alpha: 0.9),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Sign in button
                              FlowButton(
                                onPressed: isLoading ? null : _submit,
                                label: 'Sign in',
                                loading: isLoading,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: isSmallScreen ? AppSpacing.md : AppSpacing.lg,
                        ),

                        // Create account link
                        Semantics(
                          label: 'Navigate to register page',
                          child: TextButton(
                            onPressed: () => context.go(RoutePaths.register),
                            child: RichText(
                              text: TextSpan(
                                style: AppTypography.subtitle().copyWith(
                                  fontSize: 14,
                                  color: AppColors.primaryText.withValues(alpha: 0.9),
                                ),
                                children: const [
                                  TextSpan(text: "Don't have an account? "),
                                  TextSpan(
                                    text: 'Create one',
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
  const _AuthLogo({this.size = 56});

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
