import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:namichat_lite/app/router/route_paths.dart';
import 'package:namichat_lite/core/constants/app_constants.dart';
import 'package:namichat_lite/core/di/injection_container.dart';
import 'package:namichat_lite/design_system/app_spacing.dart';
import 'package:namichat_lite/design_system/app_radius.dart';
import 'package:namichat_lite/design_system/flow.dart';
import 'package:namichat_lite/features/auth/domain/entities/user.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_provider.dart';
import 'package:namichat_lite/features/settings/presentation/providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final cacheInfo = ref.watch(cacheNotifierProvider);
    final scheme    = Theme.of(context).colorScheme;
    final authState = ref.watch(authNotifierProvider);
    final user      = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [

            // ── Account card ─────────────────────────────────────────
            if (user != null) ...[
              const _SectionHeader(label: 'Account'),
              FlowCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _AccountTile(user: user),
                    Divider(height: 1, color: scheme.outlineVariant),
                    _SettingsTile(
                      icon: Icons.person_outline,
                      label: 'Edit profile',
                      onTap: () => context.push(RoutePaths.editProfile),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // ── Appearance ───────────────────────────────────────────
            const _SectionHeader(label: 'Appearance'),
            FlowCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ThemeTile(
                    icon: Icons.brightness_auto_outlined,
                    label: 'System default',
                    mode: ThemeMode.system,
                    selected: themeMode,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(ThemeMode.system),
                  ),
                  Divider(height: 1, color: scheme.outlineVariant),
                  _ThemeTile(
                    icon: Icons.light_mode_outlined,
                    label: 'Light',
                    mode: ThemeMode.light,
                    selected: themeMode,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(ThemeMode.light),
                  ),
                  Divider(height: 1, color: scheme.outlineVariant),
                  _ThemeTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark',
                    mode: ThemeMode.dark,
                    selected: themeMode,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(ThemeMode.dark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Storage ──────────────────────────────────────────────
            const _SectionHeader(label: 'Storage'),
            FlowCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Cache info row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: AppSpacing.tileIcon,
                          height: AppSpacing.tileIcon,
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child:                           Icon(Icons.storage_outlined,
                              size: AppSpacing.iconSize, color: scheme.onSecondaryContainer),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Local cache (Hive)',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${cacheInfo.entryCount} cached entr${cacheInfo.entryCount == 1 ? 'y' : 'ies'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: scheme.outlineVariant),
                  // Clear cache action
                  _SettingsTile(
                    icon: Icons.delete_sweep_outlined,
                    label: 'Clear cache',
                    subtitle: 'Removes locally cached user data',
                    trailing: cacheInfo.isClearing
                        ? const SizedBox(
                            width: AppSpacing.xs + 2,
                            height: AppSpacing.xs + 2,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: cacheInfo.isClearing
                        ? null
                        : () => _confirmClearCache(context, ref),
                    destructive: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── About ────────────────────────────────────────────────
            const _SectionHeader(label: 'About'),
            FlowCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.waves_outlined,
                    label: 'App name',
                    value: AppConstants.appName,
                  ),
                  Divider(height: 1, color: scheme.outlineVariant),
                  const _InfoTile(
                    icon: Icons.tag_outlined,
                    label: 'Version',
                    value: '1.0.0',
                  ),
                  Divider(height: 1, color: scheme.outlineVariant),
                  const _InfoTile(
                    icon: Icons.code_outlined,
                    label: 'Built with',
                    value: 'Flutter · FastAPI · PostgreSQL',
                  ),
                  Divider(height: 1, color: scheme.outlineVariant),
                  const _InfoTile(
                    icon: Icons.shield_outlined,
                    label: 'License',
                    value: 'MIT',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Danger zone ──────────────────────────────────────────
            const _SectionHeader(label: 'Session'),
            FlowCard(
              padding: EdgeInsets.zero,
              child: _SettingsTile(
                icon: Icons.logout,
                label: 'Sign out',
                destructive: true,
                onTap: () => _confirmLogout(context, ref),
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────

  Future<void> _confirmClearCache(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear cache?'),
        content: const Text(
          'Locally cached user data will be removed. '
          'You will not be logged out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cacheNotifierProvider.notifier).clearCache();
      if (context.mounted) {
        FlowSnackBar.success(context, 'Cache cleared');
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to use NamiChat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      // Router's auth redirect will navigate to /login automatically.
    }
  }
}

// ── Section header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
        ),
      );
}

// ── Account tile ───────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final scheme   = Theme.of(context).colorScheme;
    final name     = user.fullName ?? user.username;
    final email    = user.email;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              initials,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Theme selection tile ───────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final ThemeMode mode;
  final ThemeMode selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == selected;
    final scheme     = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppSpacing.tileIcon,
              height: AppSpacing.tileIcon,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  size: AppSpacing.iconSize,
                  color: isSelected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: scheme.primary, size: 20)
            else
              Icon(Icons.circle_outlined,
                  color: scheme.outlineVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Generic settings tile ──────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme    = Theme.of(context).colorScheme;
    final fgColor   = destructive ? scheme.error : scheme.onSurface;
    final iconColor = destructive ? scheme.error : scheme.primary;
    final bgColor   = destructive
        ? scheme.errorContainer.withOpacity(0.5)
        : scheme.primaryContainer.withOpacity(0.6);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppSpacing.tileIcon,
              height: AppSpacing.tileIcon,
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: AppSpacing.iconSize, color: iconColor),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: fgColor),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right,
                    color: scheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Read-only info tile ────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.tileIcon,
            height: AppSpacing.tileIcon,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: AppSpacing.iconSize, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
