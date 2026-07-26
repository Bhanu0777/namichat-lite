import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namichat_lite/core/theme/app_colors.dart';
import 'package:namichat_lite/core/theme/app_gradients.dart';
import 'package:namichat_lite/core/theme/app_shadows.dart';
import 'package:namichat_lite/core/theme/app_spacing.dart';
import 'package:namichat_lite/core/theme/app_typography.dart';
import 'package:namichat_lite/design_system/app_animation.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_provider.dart';

/// Application bootstrap screen.
///
/// Triggers [AuthNotifier.bootstrap] to restore or validate the session.
/// Navigation is then handled by the router's auth redirect.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _dotController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: AppAnimation.splash,
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: AppAnimation.splash,
    );
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppAnimation.gentle,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: AppAnimation.gentle,
    );

    _fadeController.forward();
    _scaleController.forward();
    _dotController.repeat(reverse: true);

    Future.microtask(
      () => ref.read(authNotifierProvider.notifier).bootstrap(),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 360;
        final heroScale = isSmallScreen ? 0.75 : 1.0;

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: AppGradients.brand,
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? AppSpacing.lg : AppSpacing.xxl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            label: 'NamiChat logo',
                            child: _LogoGlow(
                              scale: heroScale,
                            ),
                          ),
                          SizedBox(
                            height: isSmallScreen ? AppSpacing.xl : AppSpacing.xxl,
                          ),
                          Semantics(
                            label: 'App name: NamiChat Lite',
                            child: Text(
                              'NamiChat Lite',
                              style: AppTypography.heading().copyWith(
                                fontSize: isSmallScreen ? 20 : 24,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: isSmallScreen ? AppSpacing.xs : AppSpacing.sm,
                          ),
                          Semantics(
                            label: 'Tagline: Every Wave Connects',
                            child: Text(
                              'Every Wave Connects',
                              style: AppTypography.subtitle().copyWith(
                                color: AppColors.primaryText.withValues(alpha: 0.85),
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: isSmallScreen ? AppSpacing.xl : AppSpacing.xxxl,
                          ),
                          Semantics(
                            label: 'Loading indicator',
                            child: const _AnimatedDots(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LogoGlow extends StatelessWidget {
  const _LogoGlow({
    this.scale = 1.0,
  });

  final double scale;

  @override
  Widget build(BuildContext context) {
    final heroSize = AppSpacing.heroSize * scale;

    return Container(
      width: heroSize * 2,
      height: heroSize * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.primary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: heroSize,
          height: heroSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: AppShadows.glow(AppColors.primary),
          ),
          child: Icon(
            Icons.chat_bubble_rounded,
            color: Colors.white,
            size: heroSize * 0.55,
          ),
        ),
      ),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  const _AnimatedDots();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: AppAnimation.gentle,
              builder: (context, value, child) {
                return Container(
                  width: AppSpacing.tinyDot +
                      (AppSpacing.microDot - AppSpacing.tinyDot) * value,
                  height: AppSpacing.tinyDot +
                      (AppSpacing.microDot - AppSpacing.tinyDot) * value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryText.withValues(alpha: value),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
