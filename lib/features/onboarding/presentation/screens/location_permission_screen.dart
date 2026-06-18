import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';
import '../controllers/onboarding_providers.dart';

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends ConsumerState<LocationPermissionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isRequesting = true);

    try {
      final locService = ref.read(locationServiceProvider);
      
      // Request permission using our LocationService
      final permission = await locService.requestPermission();
      
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _navigateToProfileSetup();
      } else {
        // If permission is denied, show a friendly explanation Dialog, but allow them to proceed for now in debug mode
        if (mounted) {
          _showPermissionDeniedDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _navigateToProfileSetup() {
    ref.read(onboardingStepProvider.notifier).setStep(2);
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Access Required'),
        content: const Text(
          'AroundU requires precise location permissions to calculate relative distances between you and other users within 100 meters. Without it, you cannot discover matching vibes nearby.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToProfileSetup(); // Let them proceed in debug/mock onboarding anyway
            },
            child: const Text('Proceed Anyway (Mock)'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _requestLocationPermission();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Pulsing Radar / Pin Graphic
              Center(
                child: SizedBox(
                  height: 200,
                  width: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ring 1 (outer)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            height: 200 * _pulseController.value,
                            width: 200 * _pulseController.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary
                                  .withAlpha((50 * (1 - _pulseController.value)).toInt()),
                            ),
                          );
                        },
                      ),
                      // Ring 2 (inner)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final val = (_pulseController.value + 0.5) % 1.0;
                          return Container(
                            height: 200 * val,
                            width: 200 * val,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary
                                  .withAlpha((80 * (1 - val)).toInt()),
                            ),
                          );
                        },
                      ),
                      // Center Icon
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withAlpha(80),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Headers
              Text(
                'Find Your Crowd',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'To show you people within 100 meters, AroundU needs access to your precise location. We never share your exact coordinates or track you on a map—only your relative distance to others.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Primary / Secondary Action Buttons
              FilledButton.icon(
                onPressed: _isRequesting ? null : _requestLocationPermission,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isRequesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.share_location_rounded),
                label: const Text(
                  'Enable Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _navigateToProfileSetup,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
