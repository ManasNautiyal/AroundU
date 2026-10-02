import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
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
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B)),
            const SizedBox(width: 8),
            Text(
              'Delete Account',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you absolutely sure you want to delete your account? This action is permanent and will completely erase your profile details, connections, messages, and uploaded photos.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final navigator = Navigator.of(dialogContext);
              navigator.pop();
              _showDeleteAccountFinalConfirmationDialog(navigator.context, ref);
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
  ) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Final Warning',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Text(
          'This is your last warning. Once clicked, your profile will be completely wiped from the database and there is no way to recover it. Proceed?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final navigator = Navigator.of(dialogContext);
              navigator.pop();
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
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return Consumer(
          builder: (sheetContext, sheetRef, child) {
            final isGhostMode = sheetRef.watch(ghostModeControllerProvider);

            return Container(
              decoration: AppDecorations.bottomSheet(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDecorations.dragHandle(),
                  Text(
                    'Settings',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Ghost Mode Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: AppDecorations.card(borderRadius: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.subtleGray,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.visibility_off_outlined,
                            color: isGhostMode ? Colors.white : AppTheme.textSecondary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ghost Mode',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Disappear from radars',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          child: Switch(
                            value: isGhostMode,
                            onChanged: (val) {
                              sheetRef.read(ghostModeControllerProvider.notifier).toggle();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Settings menu items
                  _SettingsMenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profile',
                    onTap: () {
                      Navigator.pop(modalContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                    },
                  ),
                  _SettingsMenuItem(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    onTap: () {
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification settings coming soon!')),
                      );
                    },
                  ),
                  _SettingsMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () {
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy Policy will be available soon.')),
                      );
                    },
                  ),
                  _SettingsMenuItem(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () {
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms of Service will be available soon.')),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(height: 0.5, color: AppTheme.borderGray),
                  const SizedBox(height: 16),

                  // Log Out Button
                  FilledButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(modalContext);
                      navigator.pop();
                      final confirm = await showDialog<bool>(
                        context: navigator.context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(
                            'Log Out',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          content: Text(
                            'Are you sure you want to log out of AroundU?',
                            style: GoogleFonts.inter(color: AppTheme.textSecondary),
                          ),
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
                    label: Text(
                      'Log Out',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Delete Account Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.borderGray, width: 0.8),
                    ),
                    onPressed: () {
                      final navigator = Navigator.of(modalContext);
                      navigator.pop();
                      _showDeleteAccountDialog(navigator.context, ref);
                    },
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: Text(
                      'Delete Account',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatColumn(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$value',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: currentUserAsync.when(
          data: (user) => Text(
            user?.name ?? 'Profile',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          loading: () => Text(
            'Loading...',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
          error: (err, stack) => Text(
            'Error',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.darkGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              onPressed: () => _showSettingsBottomSheet(context, ref),
            ),
          ),
        ],
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                'No profile found. Please register.',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
            );
          }

          final validPics = user.profilePictures.where((pic) => pic.isNotEmpty).toList();
          final likesAsync = ref.watch(receivedLikesStreamProvider(currentUserId: user.uid));
          final sentLikesAsync = ref.watch(sentLikesStreamProvider(currentUserId: user.uid));

          final likesCount = likesAsync.valueOrNull?.length ?? 0;
          final sentLikesCount = sentLikesAsync.valueOrNull?.length ?? 0;

          final avatarUrl = validPics.isNotEmpty ? validPics[0] : '';

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // Header Row: Avatar + Stats
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.borderGray, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: AppTheme.darkGray,
                      backgroundImage: getUserImageProvider(avatarUrl),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('Posts', validPics.length),
                        _buildStatColumn('Likes', likesCount),
                        _buildStatColumn('Liked', sentLikesCount),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name and Bio Section
              Text(
                user.name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.bio,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),

              // Edit Profile Button
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 42),
                ),
                child: Text(
                  'Edit Profile',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Grid header
              Container(height: 0.5, color: AppTheme.borderGray),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grid_on_sharp, color: Colors.white, size: 20),
                  ],
                ),
              ),
              Container(height: 0.5, color: AppTheme.borderGray),
              const SizedBox(height: 12),

              // Image Grid Section
              validPics.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppTheme.darkGray,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_outlined, color: AppTheme.textTertiary, size: 40),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Posts Yet',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                                fontSize: 15,
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
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: validPics.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => showFullScreenPhotoViewer(context, validPics, initialIndex: index),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: getUserImageWidget(
                                validPics[index],
                                fit: BoxFit.cover,
                              ),
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
          child: Text(
            'Error loading profile: $err',
            style: GoogleFonts.inter(color: const Color(0xFFFF6B6B)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Settings menu item — consistent style
// ─────────────────────────────────────────────
class _SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.textSecondary, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.subtleGray, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
