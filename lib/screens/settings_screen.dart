import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/app_state.dart';
import '../widgets/glass_card.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final user = context.watch<AppState>().currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Settings'),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: kGradient),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account header card
                  if (user != null)
                    GlassCard(
                      onTap: () => _navigateToEdit(context),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: kGradientPurplePink,
                              border: Border.all(
                                  color: theme.colorScheme.surface, width: 2),
                            ),
                            child: ClipOval(
                              child: user.profilePicture != null
                                  ? Image.network(user.profilePicture!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _avatarSmall())
                                  : _avatarSmall(),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(user.email,
                                    style: TextStyle(
                                        fontSize: 13, color: muted)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: muted),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Appearance
                  _SectionTitle(title: 'Appearance'),
                  const SizedBox(height: 8),
                  _ThemeSelector(),

                  const SizedBox(height: 24),

                  // Notifications & Privacy
                  _SectionTitle(title: 'Preferences'),
                  const SizedBox(height: 8),
                  _PreferenceToggles(),

                  const SizedBox(height: 24),

                  // About
                  _SectionTitle(title: 'About'),
                  const SizedBox(height: 8),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.info_outline,
                          title: 'App Version',
                          trailing: Text('1.0.0',
                              style: TextStyle(fontSize: 13, color: muted)),
                        ),
                        Divider(
                            height: 1,
                            indent: 56,
                            color: theme.colorScheme.outline),
                        _SettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          onTap: () => _showPlaceholder(context, 'Privacy Policy'),
                        ),
                        Divider(
                            height: 1,
                            indent: 56,
                            color: theme.colorScheme.outline),
                        _SettingsTile(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          onTap: () =>
                              _showPlaceholder(context, 'Terms of Service'),
                        ),
                        Divider(
                            height: 1,
                            indent: 56,
                            color: theme.colorScheme.outline),
                        _SettingsTile(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          onTap: () =>
                              _showPlaceholder(context, 'Help & Support'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Danger zone
                  _SectionTitle(title: 'Account'),
                  const SizedBox(height: 8),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.logout,
                          title: 'Logout',
                          iconColor: Colors.red,
                          titleColor: Colors.red,
                          onTap: () => _confirmLogout(context),
                        ),
                        Divider(
                            height: 1,
                            indent: 56,
                            color: theme.colorScheme.outline),
                        _SettingsTile(
                          icon: Icons.delete_forever,
                          title: 'Delete Account',
                          iconColor: Colors.red,
                          titleColor: Colors.red,
                          onTap: () => _showDeleteWarning(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarSmall() {
    return Container(
      decoration: const BoxDecoration(gradient: kGradientPurplePink),
      child: const Icon(Icons.person, size: 28, color: Colors.white),
    );
  }

  void _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (result == true && context.mounted) {
      await context.read<AppState>().refreshUser();
    }
  }

  void _showPlaceholder(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action is permanent and cannot be undone. '
          'All your data including events will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion coming soon')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final current = appState.themeMode;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined,
                  color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 12),
              Text('Theme',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _ThemeOption(
                  label: 'Dark',
                  icon: Icons.dark_mode,
                  selected: current == ThemeMode.dark,
                  onTap: () => appState.setThemeMode(ThemeMode.dark),
                ),
                _ThemeOption(
                  label: 'Light',
                  icon: Icons.light_mode,
                  selected: current == ThemeMode.light,
                  onTap: () => appState.setThemeMode(ThemeMode.light),
                ),
                _ThemeOption(
                  label: 'System',
                  icon: Icons.settings_brightness,
                  selected: current == ThemeMode.system,
                  onTap: () => appState.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: selected ? kGradientPurplePink : null,
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceToggles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ToggleTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Event reminders and updates',
            value: appState.notificationsEnabled,
            onChanged: (v) => appState.setNotificationsEnabled(v),
          ),
          Divider(
              height: 1,
              indent: 56,
              color: theme.colorScheme.outline),
          _ToggleTile(
            icon: Icons.location_on_outlined,
            title: 'Location Sharing',
            subtitle: 'Show nearby events based on your location',
            value: appState.locationSharingEnabled,
            onChanged: (v) => appState.setLocationSharingEnabled(v),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: kGradientPurple,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.iconColor,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: titleColor,
        ),
      ),
      trailing: trailing ??
          Icon(Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
