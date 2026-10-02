import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _MatchOverlayState extends ConsumerState<MatchOverlay> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                color: Colors.black.withAlpha(180),
              ),
            ),
          ),

          // Floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                size: size,
                painter: _ParticlePainter(progress: _particleController.value),
              );
            },
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Celebration Header
                  Text(
                    'You\'re connected! ✨',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 36,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You and ${matchedUser.name} both liked each other.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white.withAlpha(180),
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Interlocking Circle Avatars
                  SizedBox(
                    height: 160,
                    width: size.width,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Left Avatar (Current User)
                        Positioned(
                          left: size.width * 0.16,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withAlpha(
                                        (40 * _pulseController.value).toInt(),
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: child,
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: CircleAvatar(
                                radius: 58,
                                backgroundImage: getUserImageProvider(currentUserImageUrl),
                              ),
                            ),
                          ),
                        ),

                        // Right Avatar (Matched User)
                        Positioned(
                          right: size.width * 0.16,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withAlpha(
                                        (40 * (1 - _pulseController.value)).toInt(),
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: child,
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: CircleAvatar(
                                radius: 58,
                                backgroundImage: getUserImageProvider(matchedUserImageUrl),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 56),

                  // Action Button 1: Send Message
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onSendMessage();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                    label: Text(
                      'Send a Message',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Action Button 2: Keep Looking
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onKeepLooking();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withAlpha(120), width: 1.2),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Keep Looking',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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

/// Floating particle painter for the match celebration
class _ParticlePainter extends CustomPainter {
  final double progress;
  static final Random _random = Random(42);
  static final List<_Particle> _particles = List.generate(20, (i) => _Particle(
    x: _random.nextDouble(),
    y: _random.nextDouble(),
    size: _random.nextDouble() * 3 + 1,
    speed: _random.nextDouble() * 0.5 + 0.3,
    opacity: _random.nextDouble() * 0.4 + 0.1,
  ));

  _ParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = ((p.y + progress * p.speed) % 1.0) * size.height;
      final x = p.x * size.width + sin(progress * 2 * pi + p.x * 10) * 20;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  final double x, y, size, speed, opacity;
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}
