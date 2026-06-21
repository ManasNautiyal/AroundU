import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/discovery_providers.dart';
import '../widgets/nearby_user_card.dart';
import '../widgets/beacon_sheet.dart';
import '../../../chat/presentation/screens/local_room_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../data/repositories/user_repository.dart';
import '../../../../core/widgets/image_helper.dart';
import '../../../../core/services/location_service.dart';
import '../../data/repositories/discovery_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import 'package:geolocator/geolocator.dart';
import '../../../connections/data/repositories/interaction_repository.dart';
import '../../data/models/nearby_user.dart';
import '../widgets/profile_detail_sheet.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _pulseController;
  UserModel? _selectedUser;



  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _selectedUser = null;
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Offset _getUserOffset(String uid, double radius) {
    // Deterministic visual offsets matching mockup layout
    switch (uid) {
      case 'mock_2': // Liam P. (top-center/right)
        return Offset(radius * 0.18, -radius * 0.58);
      case 'mock_daina': // Daina K. (middle-right)
        return Offset(radius * 0.42, -radius * 0.22);
      case 'mock_sarah': // Sarah W. (middle-right, selected)
        return Offset(radius * 0.65, radius * 0.15);
      case 'mock_3': // Ava C. (middle-left)
        return Offset(-radius * 0.48, -radius * 0.16);
      case 'mock_david': // David L. (bottom-left)
        return Offset(-radius * 0.68, radius * 0.42);
      case 'mock_chloe': // Chloe K. (bottom-center)
        return Offset(-radius * 0.18, radius * 0.62);
      case 'mock_chloe_2': // Chloe K. (bottom-right)
        return Offset(radius * 0.38, radius * 0.62);
      default:
        final angle = uid.hashCode * 0.123;
        final distRatio = 0.3 + (uid.hashCode % 5) * 0.12;
        return Offset(
          radius * distRatio * math.cos(angle),
          radius * distRatio * math.sin(angle),
        );
    }
  }



  void _handleWave(String targetUserId, String targetName) async {
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    try {
      await ref.read(interactionRepositoryProvider).sendWave(
            currentUserId: currentUserId,
            targetUserId: targetUserId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You waved to $targetName! 👋'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleEndorse(String targetUserId, String targetName) async {
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    try {
      final isMatch = await ref.read(interactionRepositoryProvider).sendLike(
            currentUserId: currentUserId,
            targetUserId: targetUserId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isMatch
                ? 'Mutual match! You are now connected with $targetName! 🎉'
                : 'Vibe endorsed! ❤️'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to endorse: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleConnect(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileDetailSheet(userModel: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
    final positionAsync = ref.watch(userPositionProvider);
    final selectedVibe = ref.watch(selectedVibeFilterProvider);
    final isInLocalRoom = ref.watch(inLocalRoomProvider);
    final isGhostMode = ref.watch(ghostModeControllerProvider);

    final currentUserAsync = ref.watch(currentUserModelProvider);
    final currentUser = currentUserAsync.valueOrNull;
    final currentUserImageUrl = currentUser?.profilePictures.isNotEmpty == true
        ? currentUser!.profilePictures[0]
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Plain Sonar Radar Canvas
          Positioned.fill(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = math.min(constraints.maxWidth, constraints.maxHeight);
                  final radius = size * 0.42;
                  final centerX = constraints.maxWidth / 2;
                  final centerY = constraints.maxHeight / 2 - 20;

                  // Retrieve live users
                  final liveUsersAsync = ref.watch(nearbyUsersProvider(currentUserId: currentUserId));
                  final displayedUsers = liveUsersAsync.valueOrNull ?? const [];

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Sonar Sweep background
                      Center(
                        child: SizedBox(
                          height: radius * 2,
                          width: radius * 2,
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_sweepController, _pulseController]),
                            builder: (context, child) {
                              return CustomPaint(
                                painter: RadarSweepPainter(
                                  angle: _sweepController.value * 2 * math.pi,
                                  pulseValue: _pulseController.value,
                                  color: theme.colorScheme.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Center 'YOU' indicator
                      Positioned(
                        left: centerX - 30,
                        top: centerY - 30,
                        child: _buildCenterYouMarker(theme),
                      ),

                      // Plotted User Avatars and speech bubbles
                      ...displayedUsers.map((nearby) {
                        final user = nearby.user;
                        final offset = _getUserOffset(user.uid, radius);
                        final x = centerX + offset.dx;
                        final y = centerY + offset.dy;

                        final isSelected = _selectedUser?.uid == user.uid;
                        final isVibeMatch = selectedVibe == null ||
                            user.vibeTags.any((t) => t
                                .toLowerCase()
                                .contains(selectedVibe.split(' ').last.toLowerCase()));

                        final primaryPhoto = user.profilePictures.isNotEmpty ? user.profilePictures[0] : '';

                        return Positioned(
                          left: x - 40,
                          top: y - 55,
                          child: Opacity(
                            opacity: isVibeMatch ? 1.0 : 0.35,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Speech bubble if user has a beacon
                                if (user.beaconEmoji != null && user.beaconMessage != null)
                                  _buildBeaconBubble(user, theme, isSelected),

                                // Glowing Ring Avatar
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedUser = user;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.primary.withAlpha(80),
                                        width: isSelected ? 3 : 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: theme.colorScheme.primary.withAlpha(100),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundImage: getUserImageProvider(primaryPhoto),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Name label
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.light
                                        ? Colors.white.withAlpha(220)
                                        : theme.colorScheme.surface.withAlpha(220),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    user.name.split(' ').first,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),

          // 2. Safe Area Controls (Header & Overlays)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search & Filter Header
                  _buildHeader(theme),

                  const SizedBox(height: 16),

                  // Floating Proximity Chat Zone Banner
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    offset: isInLocalRoom ? Offset.zero : const Offset(0, -2.0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isInLocalRoom ? 1.0 : 0.0,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(20),
                        color: theme.colorScheme.tertiaryContainer,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LocalRoomScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.pin_drop_rounded,
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Downtown Coffee Shop Zone",
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onTertiaryContainer.withAlpha(200),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "📍 You are in the zone. Join Chat ➔",
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onTertiaryContainer,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Recenter / Compass & Drop Beacon Action Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Drop Beacon Button
                      FloatingActionButton.small(
                        heroTag: 'drop_beacon_fab',
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const BeaconSheet(),
                          );
                        },
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        child: const Icon(Icons.add_location_alt_rounded),
                      ),
                      const SizedBox(width: 8),
                      // Recenter Compass Button
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.dividerColor.withAlpha(50)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(30),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.near_me_rounded, color: theme.colorScheme.primary, size: 20),
                          onPressed: () {
                            ref.invalidate(userPositionProvider);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),


                ],
              ),
            ),
          ),

          // 3. Selection Profile Detail Panel (Sticky at bottom)
          if (_selectedUser != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSelectedUserCard(_selectedUser!, theme),
            ),
        ],
      ),
    );
  }

  Widget _buildCenterYouMarker(ThemeData theme) {
    return Container(
      height: 60,
      width: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withAlpha(25),
      ),
      child: Container(
        height: 24,
        width: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        alignment: Alignment.center,
        child: Container(
          height: 14,
          width: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildBeaconBubble(UserModel user, ThemeData theme, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 140),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withAlpha(80),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            user.beaconEmoji!,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              user.beaconMessage!,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 9,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFFF0F4F9)
                      : const Color(0xFF232931),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Find people...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light
                    ? const Color(0xFFF0F4F9)
                    : const Color(0xFF232931),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_list, size: 20),
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ghost Mode',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Switch(
              value: ref.watch(ghostModeControllerProvider),
              onChanged: (val) {
                ref.read(ghostModeControllerProvider.notifier).toggle();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedUserCard(UserModel user, ThemeData theme) {
    final primaryPhoto = user.profilePictures.isNotEmpty ? user.profilePictures[0] : '';
    return Card(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      elevation: 6,
      shadowColor: Colors.black.withAlpha(30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: theme.brightness == Brightness.light
              ? const Color(0xFFE2E8F0)
              : const Color(0xFF334155),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 36,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: getUserImageProvider(primaryPhoto),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            user.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _selectedUser = null;
                              });
                            },
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Interaction Options',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Wave Button
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF25C5C),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextButton.icon(
                      onPressed: () => _handleWave(user.uid, user.name),
                      icon: const Icon(Icons.back_hand_rounded, color: Colors.white, size: 16),
                      label: const Text(
                        'Wave',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Message Request Button
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextButton.icon(
                      onPressed: () => _handleConnect(user),
                      icon: const Icon(Icons.mail_rounded, color: Colors.white, size: 16),
                      label: const Text(
                        'Message',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Canvas Painter to render professional Sonar Radar Sweeping and Ring Pulsing animation
class RadarSweepPainter extends CustomPainter {
  final double angle; // 0.0 to 2*pi
  final double pulseValue; // 0.0 to 1.0
  final Color color;

  RadarSweepPainter({
    required this.angle,
    required this.pulseValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final ringPaint = Paint()
      ..color = color.withAlpha(30)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw concentric radar lines
    canvas.drawCircle(center, radius * 0.25, ringPaint);
    canvas.drawCircle(center, radius * 0.50, ringPaint);
    canvas.drawCircle(center, radius * 0.75, ringPaint);
    canvas.drawCircle(center, radius, ringPaint);

    // Draw concentric pulse ring
    final pulsePaint = Paint()
      ..color = color.withAlpha((100 * (1 - pulseValue)).toInt())
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * pulseValue, pulsePaint);

    // Draw scanning sector gradient sweep
    final sweepPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withAlpha(100),
          color.withAlpha(30),
          color.withAlpha(0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    final sweepPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        angle - 0.7,
        0.7,
        false,
      )
      ..close();
    canvas.drawPath(sweepPath, sweepPaint);

    // Draw sweep line
    final linePaint = Paint()
      ..color = color.withAlpha(180)
      ..strokeWidth = 2.0;
    final endX = center.dx + radius * math.cos(angle);
    final endY = center.dy + radius * math.sin(angle);
    canvas.drawLine(center, Offset(endX, endY), linePaint);
  }

  @override
  bool shouldRepaint(covariant RadarSweepPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.color != color;
  }
}
