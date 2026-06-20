import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../discovery/presentation/controllers/discovery_providers.dart';
import '../../../onboarding/presentation/controllers/onboarding_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Step 1: Initial deletion warning Dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            const Text('Delete Account'),
          ],
        ),
        content: const Text(
          'Are you absolutely sure you want to delete your account? This action is permanent and will completely erase your profile details, connections, messages, and uploaded photos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () {
              Navigator.pop(context); // Close step 1 dialog
              _showDeleteAccountFinalConfirmationDialog(context, ref, theme);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Step 2: Final deletion confirmation dialog
  void _showDeleteAccountFinalConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Warning'),
        content: const Text(
          'This is your last warning. Once clicked, your profile will be completely wiped from the database and there is no way to recover it. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.redAccent,
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _performDelete(context, ref);
            },
            child: const Text('PERMANENTLY DELETE'),
          ),
        ],
      ),
    );
  }

  void _performDelete(BuildContext context, WidgetRef ref) async {
    // Show loading spinner dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Mock deleting details
    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      Navigator.pop(context); // Close loading spinner
      
      // Reset onboarding step to step 0 (Auth screen) reactively
      ref.read(onboardingStepProvider.notifier).setStep(0);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account successfully deleted. All data has been wiped.'),
          backgroundColor: Colors.black,
        ),
      );
      
      // Close the settings screen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isGhostMode = ref.watch(ghostModeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primaryContainer.withAlpha(20),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          children: [
            // Ghost Mode Switch Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isGhostMode
                      ? theme.colorScheme.secondary.withAlpha(120)
                      : theme.colorScheme.outlineVariant.withAlpha(55),
                  width: isGhostMode ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SwitchListTile(
                  title: Row(
                    children: [
                      Icon(
                        isGhostMode ? Icons.visibility_off : Icons.visibility,
                        color: isGhostMode
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Ghost Mode',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text(
                      'When enabled, you instantly disappear from other users\' radars. Your location stops updating and you go offline.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                  value: isGhostMode,
                  onChanged: (val) {
                    ref.read(ghostModeControllerProvider.notifier).toggle();
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Settings Section
            _buildSectionHeader(theme, 'Account Settings'),
            const SizedBox(height: 8),
            _buildSettingsTile(
              theme: theme,
              icon: Icons.person_outline_rounded,
              title: 'Edit Profile',
              onTap: () {},
            ),
            _buildSettingsTile(
              theme: theme,
              icon: Icons.notifications_none_rounded,
              title: 'Notification Settings',
              onTap: () {},
            ),
            const SizedBox(height: 24),

            // Legal & Safety Section
            _buildSectionHeader(theme, 'Legal & Privacy'),
            const SizedBox(height: 8),
            _buildSettingsTile(
              theme: theme,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () {},
            ),
            _buildSettingsTile(
              theme: theme,
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () {},
            ),
            const SizedBox(height: 48),

            // Delete Account Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.error.withAlpha(100)),
                  ),
                ),
                onPressed: () => _showDeleteAccountDialog(context, ref),
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text(
                  'Delete Account',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      margin: EdgeInsets.zero,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }
}
