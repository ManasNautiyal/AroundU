import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../discovery/presentation/controllers/discovery_providers.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../discovery/data/repositories/user_repository.dart';
import '../../../connections/data/repositories/interaction_repository.dart';
import '../../../../core/widgets/image_helper.dart';
import 'edit_profile_screen.dart';
import '../../../../main.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showDeleteAccountDialog(BuildContext parentContext, WidgetRef ref) {
    final theme = Theme.of(parentContext);

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () {
              final navigator = Navigator.of(dialogContext);
              navigator.pop(); // Close step 1 dialog
              _showDeleteAccountFinalConfirmationDialog(navigator.context, ref, theme);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountFinalConfirmationDialog(
    BuildContext parentContext,
    WidgetRef ref,
    ThemeData theme,
  ) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Final Warning'),
        content: const Text(
          'This is your last warning. Once clicked, your profile will be completely wiped from the database and there is no way to recover it. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () {
              final navigator = Navigator.of(dialogContext);
              navigator.pop(); // Close dialog
              _performDelete(navigator.context, ref);
            },
            child: const Text('PERMANENTLY DELETE'),
          ),
        ],
      ),
    );
  }

  void _performDelete(BuildContext parentContext, WidgetRef ref) async {
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = authRepo.currentUser;
      if (user != null) {
        // Scrub profile information in Firestore first (since delete is disallowed by rules)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': '[Deleted Account]',
          'bio': 'This account has been deleted.',
          'profilePictures': FieldValue.delete(),
          'location': FieldValue.delete(),
          'isGhostMode': true,
        });
        await user.delete();
      }
    } catch (_) {}

    await ref.read(authRepositoryProvider).signOut();

    if (!parentContext.mounted) return;

    Navigator.of(parentContext).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OnboardingRouter()),
      (route) => false,
    );
    ScaffoldMessenger.of(parentContext).showSnackBar(
      const SnackBar(
        content: Text('Account successfully deleted. All data has been wiped.'),
        backgroundColor: Colors.black,
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return Consumer(
          builder: (sheetContext, sheetRef, child) {
            final isGhostMode = sheetRef.watch(ghostModeControllerProvider);
            final colorScheme = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;

            final sheetBgColor = Color.alphaBlend(
              colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.05),
              colorScheme.surface,
            );
            final borderBgColor = colorScheme.outlineVariant;
            final textThemeColor = colorScheme.onSurface;
            final subtitleColor = colorScheme.onSurfaceVariant;
            final iconThemeColor = colorScheme.onSurfaceVariant;
            final chevronThemeColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.3);
            final dividerColor = colorScheme.outlineVariant;

            return Material(
              color: sheetBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: borderBgColor, width: 1.5),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        height: 4,
                        width: 40,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Settings',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textThemeColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Ghost Mode Toggle Switch Tile
                    SwitchListTile(
                      title: Row(
                        children: [
                          Icon(Icons.visibility_off_outlined, color: iconThemeColor),
                          const SizedBox(width: 12),
                          Text(
                            'Ghost Mode',
                            style: TextStyle(fontWeight: FontWeight.w600, color: textThemeColor),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Disappear from radars. Your location stops updating.',
                        style: TextStyle(fontSize: 12, color: subtitleColor),
                      ),
                      value: isGhostMode,
                      activeThumbColor: theme.colorScheme.primary,
                      activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                      onChanged: (val) {
                        sheetRef.read(ghostModeControllerProvider.notifier).toggle();
                      },
                    ),
                    const Divider(color: Colors.transparent, height: 4),

                    // Edit Profile
                    ListTile(
                      leading: Icon(Icons.person_outline_rounded, color: iconThemeColor),
                      title: Text('Edit Profile', style: TextStyle(color: textThemeColor)),
                      trailing: Icon(Icons.chevron_right_rounded, color: chevronThemeColor),
                      onTap: () {
                        Navigator.pop(modalContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    
                    // Notifications
                    ListTile(
                      leading: Icon(Icons.notifications_none_rounded, color: iconThemeColor),
                      title: Text('Notifications', style: TextStyle(color: textThemeColor)),
                      trailing: Icon(Icons.chevron_right_rounded, color: chevronThemeColor),
                      onTap: () {
                        Navigator.pop(modalContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification settings coming soon!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),

                     // Privacy
                    ListTile(
                      leading: Icon(Icons.privacy_tip_outlined, color: iconThemeColor),
                      title: Text('Privacy Policy', style: TextStyle(color: textThemeColor)),
                      trailing: Icon(Icons.chevron_right_rounded, color: chevronThemeColor),
                      onTap: () {
                        Navigator.pop(modalContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Privacy Policy will be available soon.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),

                    // Terms
                    ListTile(
                      leading: Icon(Icons.description_outlined, color: iconThemeColor),
                      title: Text('Terms of Service', style: TextStyle(color: textThemeColor)),
                      trailing: Icon(Icons.chevron_right_rounded, color: chevronThemeColor),
                      onTap: () {
                        Navigator.pop(modalContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Terms of Service will be available soon.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    Divider(color: dividerColor),
                    const SizedBox(height: 16),

                    // Log Out Button
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final navigator = Navigator.of(modalContext);
                        navigator.pop(); // Close sheet
                        final confirm = await showDialog<bool>(
                          context: navigator.context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Log Out'),
                            content: const Text('Are you sure you want to log out of AroundU?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(dialogContext, true),
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await ref.read(authRepositoryProvider).signOut();
                          final navContext = navigator.context;
                          if (navContext.mounted) {
                            Navigator.of(navContext).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const OnboardingRouter()),
                              (route) => false,
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),

                    // Delete Account Button
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: StadiumBorder(
                          side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.24), width: 1),
                        ),
                      ),
                      onPressed: () {
                        final navigator = Navigator.of(modalContext);
                        navigator.pop(); // Close sheet
                        _showDeleteAccountDialog(navigator.context, ref);
                      },
                      icon: Icon(Icons.delete_forever_rounded, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      label: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatColumn(String label, int value, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserAsync = ref.watch(currentUserModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: currentUserAsync.when(
          data: (user) => Text(
            user?.name ?? 'Profile',
            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 18),
          ),
          loading: () => Text('Loading...', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          error: (err, stack) => Text('Error', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface),
            onPressed: () => _showSettingsBottomSheet(context, ref),
          ),
        ],
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Text('No profile found. Please register.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            );
          }

          final validPics = user.profilePictures.where((pic) => pic.isNotEmpty).toList();
          final likesAsync = ref.watch(receivedLikesStreamProvider(currentUserId: user.uid));
          final matchesAsync = ref.watch(matchesStreamProvider(currentUserId: user.uid));

          final likesCount = likesAsync.valueOrNull?.length ?? 0;
          final matchesCount = matchesAsync.valueOrNull?.length ?? 0;

          final avatarUrl = validPics.isNotEmpty ? validPics[0] : '';

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // Header Row: Avatar + Stats
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.surface,
                    backgroundImage: getUserImageProvider(avatarUrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('Posts', validPics.length, theme),
                        _buildStatColumn('Likes', likesCount, theme),
                        _buildStatColumn('Connects', matchesCount, theme),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name and Bio Section
              Text(
                user.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.bio,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),

              // Wide Outlined "Edit Profile" Button
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tab Divider matching Instagram grid look
              Divider(color: theme.colorScheme.outlineVariant, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grid_on_sharp, color: theme.colorScheme.onSurface, size: 22),
                  ],
                ),
              ),
              Divider(color: theme.colorScheme.outlineVariant, height: 1),
              const SizedBox(height: 12),

              // Image Grid Section
              validPics.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, color: theme.colorScheme.onSurfaceVariant, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'No Posts Yet',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 3,
                        mainAxisSpacing: 3,
                      ),
                      itemCount: validPics.length,
                      itemBuilder: (context, index) {
                        return AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            child: getUserImageWidget(
                              validPics[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          child: Text('Error loading profile: $err', style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }
}
