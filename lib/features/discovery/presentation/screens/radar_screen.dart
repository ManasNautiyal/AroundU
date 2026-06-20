import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/discovery_providers.dart';
import '../widgets/nearby_user_card.dart';
import '../widgets/beacon_sheet.dart';
import '../../../chat/presentation/screens/local_room_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../safety/data/repositories/block_service.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _pulseController;

  // Harmonious vibe list matching mock user interest tags
  final List<String> _vibeFilters = [
    '☕ Coffee',
    '🎵 Music',
    '🎨 Art',
    '🎮 Gaming',
    '🏋️ Gym',
    '🍕 Foodie',
  ];

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
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<Widget> _buildHeatmapCircles(String vibe, ThemeData theme) {
    Color primaryColor;
    Color secondaryColor;
    
    if (vibe.contains('Coffee')) {
      primaryColor = Colors.orangeAccent.withAlpha(140);
      secondaryColor = Colors.amber.withAlpha(0);
    } else if (vibe.contains('Music')) {
      primaryColor = Colors.purpleAccent.withAlpha(140);
      secondaryColor = Colors.pinkAccent.withAlpha(0);
    } else if (vibe.contains('Art')) {
      primaryColor = Colors.cyanAccent.withAlpha(140);
      secondaryColor = Colors.blueAccent.withAlpha(0);
    } else if (vibe.contains('Gaming')) {
      primaryColor = Colors.redAccent.withAlpha(140);
      secondaryColor = Colors.orangeAccent.withAlpha(0);
    } else if (vibe.contains('Gym')) {
      primaryColor = Colors.tealAccent.withAlpha(140);
      secondaryColor = Colors.greenAccent.withAlpha(0);
    } else {
      primaryColor = theme.colorScheme.primary.withAlpha(140);
      secondaryColor = theme.colorScheme.primaryContainer.withAlpha(0);
    }

    return [
      Positioned(
        top: 120,
        left: -40,
        child: _GlowingCircle(
          size: 260,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          pulseValue: _pulseController.value,
        ),
      ),
      Positioned(
        bottom: 180,
        right: -60,
        child: _GlowingCircle(
          size: 320,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          pulseValue: 1.0 - _pulseController.value,
        ),
      ),
      Positioned(
        top: 340,
        left: 100,
        child: _GlowingCircle(
          size: 180,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          pulseValue: _pulseController.value,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGhostMode = ref.watch(ghostModeControllerProvider);
    
    final nearbyUsersRaw = ref.watch(mockDiscoveryUsersControllerProvider);
    final blockedUsersAsync = ref.watch(blockedUsersStreamProvider(currentUserId: 'me'));
    final blockedUserIds = blockedUsersAsync.valueOrNull ?? const [];
    final nearbyUsers = nearbyUsersRaw.where((u) => !blockedUserIds.contains(u.user.uid)).toList();

    // Read new state providers
    final selectedVibe = ref.watch(selectedVibeFilterProvider);
    final isInLocalRoom = ref.watch(inLocalRoomProvider);

    return Scaffold(
      // Dynamic appbar gradient depending on Ghost Mode
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isGhostMode
                  ? [
                      theme.colorScheme.secondaryContainer.withAlpha(200),
                      theme.colorScheme.surfaceContainerHighest,
                    ]
                  : [
                      theme.colorScheme.primaryContainer.withAlpha(100),
                      theme.colorScheme.surface,
                    ],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                child: const CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.radar_rounded,
                  color: isGhostMode
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isGhostMode ? 'AroundU (Ghost)' : 'AroundU',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            actions: [
              // Ghost Mode Toggle
              IconButton(
                onPressed: () {
                  ref.read(ghostModeControllerProvider.notifier).toggle();
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isGhostMode
                            ? 'Ghost Mode disabled. You are now visible to others.'
                            : 'Ghost Mode enabled. You are now invisible to others.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(
                  isGhostMode ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: isGhostMode
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Toggle Ghost Mode',
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient decoration
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.primaryContainer.withAlpha(30),
                  ],
                ),
              ),
            ),
          ),

          // Glowing Vibe Heatmap Circles (Pulsing background)
          if (selectedVibe != null)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  children: _buildHeatmapCircles(selectedVibe, theme),
                );
              },
            ),

          // Main Discovery Grid (Dimmed when Vibe Heatmap mode is active)
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: selectedVibe != null ? 0.30 : 1.0,
              child: nearbyUsers.isEmpty
                  ? _buildEmptyRadarState(theme)
                  : _buildDiscoveryGrid(nearbyUsers),
            ),
          ),

          // Floating Proximity Chat Zone Banner at the very top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              offset: isInLocalRoom ? Offset.zero : const Offset(0, -2.0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isInLocalRoom ? 1.0 : 0.0,
                child: Material(
                  elevation: 8,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
          ),

          // Bottom Vibe Filter Chips Row
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface.withAlpha(0),
                    theme.colorScheme.surface.withAlpha(240),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Text(
                      selectedVibe != null ? 'Vibe Heatmap Active' : 'Filter by Vibe Heatmap',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: selectedVibe != null 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _vibeFilters.map((vibe) {
                        final isSelected = selectedVibe == vibe;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(vibe),
                            selected: isSelected,
                            onSelected: (selected) {
                              ref.read(selectedVibeFilterProvider.notifier).selectFilter(
                                    selected ? vibe : null,
                                  );
                            },
                            selectedColor: theme.colorScheme.primaryContainer,
                            checkmarkColor: theme.colorScheme.onPrimaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Developer Control Panel (Positioned higher to avoid overlapping filters/FAB)
          Positioned(
            bottom: 160,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reset Mock Users
                FloatingActionButton.small(
                  heroTag: 'dev_populate',
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  tooltip: 'Reset Mock Users',
                  onPressed: () {
                    ref.read(mockDiscoveryUsersControllerProvider.notifier).resetUsers();
                  },
                  child: const Icon(Icons.people_rounded),
                ),
                const SizedBox(height: 8),
                // Clear Mock Users
                FloatingActionButton.small(
                  heroTag: 'dev_clear',
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                  tooltip: 'Clear Mock Users',
                  onPressed: () {
                    ref.read(mockDiscoveryUsersControllerProvider.notifier).clearUsers();
                  },
                  child: const Icon(Icons.people_outline_rounded),
                ),
                const SizedBox(height: 8),
                // Toggle Proximity Chat Room Zone
                FloatingActionButton.small(
                  heroTag: 'dev_proximity',
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  foregroundColor: theme.colorScheme.onTertiaryContainer,
                  tooltip: 'Toggle Proximity Zone',
                  onPressed: () {
                    ref.read(inLocalRoomProvider.notifier).toggle();
                  },
                  child: const Icon(Icons.pin_drop_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84.0), // Elevate FAB above the bottom filter chips bar
        child: FloatingActionButton.extended(
          heroTag: 'drop_beacon_fab',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const BeaconSheet(),
            );
          },
          icon: const Icon(Icons.radar_rounded),
          label: const Text('Drop Beacon'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyRadarState(ThemeData theme) {

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom Canvas Pulsing Sonar Sweep Radar
            SizedBox(
              height: 240,
              width: 240,
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
            const SizedBox(height: 40),
            Text(
              'Scanning the area...',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No one is within 100 meters of your location yet. Try moving to a new spot!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryGrid(List<dynamic> users) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16.0,
              crossAxisSpacing: 16.0,
              childAspectRatio: 0.75, // Sleek card profile format
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return NearbyUserCard(nearbyUser: users[index]);
              },
              childCount: users.length,
            ),
          ),
        ),
      ],
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

class _GlowingCircle extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final double pulseValue;

  const _GlowingCircle({
    required this.size,
    required this.primaryColor,
    required this.secondaryColor,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    final scale = 0.92 + (0.16 * pulseValue);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              primaryColor,
              primaryColor.withValues(alpha: primaryColor.a * 0.35),
              secondaryColor,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}

