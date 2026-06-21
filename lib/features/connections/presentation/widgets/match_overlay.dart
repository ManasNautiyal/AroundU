import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../discovery/data/models/nearby_user.dart';
import '../../../discovery/data/repositories/user_repository.dart';
import '../../../../core/widgets/image_helper.dart';

class MatchOverlay extends ConsumerStatefulWidget {
  final UserModel matchedUser;
  final VoidCallback onSendMessage;
  final VoidCallback onKeepLooking;

  const MatchOverlay({
    super.key,
    required this.matchedUser,
    required this.onSendMessage,
    required this.onKeepLooking,
  });

  /// Static helper to launch the celebration dialog
  static void show({
    required BuildContext context,
    required UserModel matchedUser,
    required VoidCallback onSendMessage,
    required VoidCallback onKeepLooking,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(200),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return MatchOverlay(
          matchedUser: matchedUser,
          onSendMessage: onSendMessage,
          onKeepLooking: onKeepLooking,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final scale = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
        );
        final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: anim1, curve: Curves.easeOut),
        );
        return Opacity(
          opacity: opacity.value,
          child: Transform.scale(
            scale: scale.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<MatchOverlay> createState() => _MatchOverlayState();
}

class _MatchOverlayState extends ConsumerState<MatchOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final matchedUser = widget.matchedUser;

    final currentUserAsync = ref.watch(currentUserModelProvider);
    final currentUser = currentUserAsync.valueOrNull;
    final currentUserImageUrl = currentUser?.profilePictures.isNotEmpty == true
        ? currentUser!.profilePictures[0]
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300';

    final matchedUserImageUrl = matchedUser.profilePictures.isNotEmpty
        ? matchedUser.profilePictures[0]
        : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=300';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Glassmorphic Backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.black.withAlpha(150),
              ),
            ),
          ),

          // Central Celebratory Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Celebration Header
                  Text(
                    'It\'s a Match!',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.primaryContainer,
                      fontWeight: FontWeight.w900,
                      fontSize: 40,
                      letterSpacing: -1.0,
                      shadows: [
                        Shadow(
                          color: theme.colorScheme.primary.withAlpha(150),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You and ${matchedUser.name} both liked each other.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withAlpha(200),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Interlocking Circle Avatars
                  SizedBox(
                    height: 180,
                    width: size.width,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Left Avatar (Current User)
                        Positioned(
                          left: size.width * 0.18,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withAlpha(
                                        (80 * _pulseController.value).toInt(),
                                      ),
                                      blurRadius: 25,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: child,
                              );
                            },
                            child: CircleAvatar(
                              radius: 65,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 60,
                                backgroundImage: getUserImageProvider(currentUserImageUrl),
                              ),
                            ),
                          ),
                        ),

                        // Right Avatar (Matched User)
                        Positioned(
                          right: size.width * 0.18,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.secondary.withAlpha(
                                        (80 * (1 - _pulseController.value)).toInt(),
                                      ),
                                      blurRadius: 25,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: child,
                              );
                            },
                            child: CircleAvatar(
                              radius: 65,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 60,
                                backgroundImage: getUserImageProvider(matchedUserImageUrl),
                              ),
                            ),
                          ),
                        ),

                        // Sparkles / Heart badge in middle
                        Positioned(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(30),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.black,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 64),

                  // Action Button 1: Send Message (Filled)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close Overlay
                      widget.onSendMessage();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_rounded),
                    label: const Text(
                      'Send a Message',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Button 2: Keep Looking (Outlined text)
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close Overlay
                      widget.onKeepLooking();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Keep Looking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
}
