import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/discovery_providers.dart';
import '../widgets/nearby_user_card.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _pulseController;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGhostMode = ref.watch(ghostModeControllerProvider);
    final nearbyUsers = ref.watch(mockDiscoveryUsersControllerProvider);

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
            leading: const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
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

          // Main Content
          nearbyUsers.isEmpty
              ? _buildEmptyRadarState(theme)
              : _buildDiscoveryGrid(nearbyUsers),

          // Developer Control Panel (Floating action buttons to test both states)
          Positioned(
            bottom: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
              ],
            ),
          ),
        ],
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
