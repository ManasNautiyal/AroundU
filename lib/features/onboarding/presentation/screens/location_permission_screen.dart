import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/location_service.dart';
import '../controllers/onboarding_providers.dart';
import '../../../discovery/data/repositories/user_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends ConsumerState<LocationPermissionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  bool _isRequesting = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _checkLocationAndAutoAdvance();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      ref.invalidate(locationPermissionAndServiceStatusProvider);
      _checkLocationAndAutoAdvance();
    }
  }

  Future<void> _checkLocationAndAutoAdvance() async {
    if (!mounted) return;
    _isRequesting = false;
    try {
      final locService = ref.read(locationServiceProvider);
      final serviceEnabled = await locService.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final permission = await locService.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        _onPermissionGranted();
      }
    } catch (_) {}
  }

  void _onPermissionGranted() {
    _pollingTimer?.cancel();
    ref.invalidate(locationPermissionAndServiceStatusProvider);
    final userModel = ref.read(currentUserModelProvider).valueOrNull;
    final currentStep = ref.read(onboardingStepProvider);

    if (userModel == null && currentStep <= 1) {
      ref.read(onboardingStepProvider.notifier).setStep(2);
    } else {
      ref.read(onboardingStepProvider.notifier).setStep(3);
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isRequesting = true);

    try {
      final locService = ref.read(locationServiceProvider);
      
      final serviceEnabled = await locService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showLocationServiceDisabledDialog();
        }
        return;
      }

      var permission = await locService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await locService.requestPermission();
      }

      if (permission == LocationPermission.always) {
        _onPermissionGranted();
      } else if (permission == LocationPermission.whileInUse) {
        if (mounted) {
          _showAlwaysLocationDialog();
        }
      } else if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showPermissionDeniedForeverDialog();
        }
      } else {
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

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Location Services Disabled',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Text(
          'Your device GPS / Location Services are turned off. Please turn on Location in your device settings to continue.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Geolocator.openLocationSettings();
            },
            child: const Text('Turn On Location'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Permission Permanently Denied',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Text(
          'Location permission has been permanently denied for AroundU. Please enable Location in App Settings to proceed.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Geolocator.openAppSettings();
            },
            child: const Text('Open App Settings'),
          ),
        ],
      ),
    );
  }

  void _showAlwaysLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Always-On Location Recommended',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Text(
          'To ensure you never miss any nearby connections or local chat zones (even when the app runs in the background), please set location permission to "Always Allow" in your system settings.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _onPermissionGranted();
            },
            child: const Text('Keep "While Using"'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Geolocator.openAppSettings();
            },
            child: const Text('Change to "Always"'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    final hasProfile = ref.read(currentUserModelProvider).valueOrNull != null;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Location Access Required',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Text(
          'AroundU requires precise location permissions to calculate relative distances between you and other users. Please enable location services.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          if (!hasProfile)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _onPermissionGranted();
              },
              child: const Text('Proceed anyway'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Pulsing Radar Graphic
              Center(
                child: SizedBox(
                  height: 180,
                  width: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ring 1 (outer)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            height: 180 * _pulseController.value,
                            width: 180 * _pulseController.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white
                                  .withAlpha((30 * (1 - _pulseController.value)).toInt()),
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
                            height: 180 * val,
                            width: 180 * val,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white
                                  .withAlpha((50 * (1 - val)).toInt()),
                            ),
                          );
                        },
                      ),
                      // Center Icon
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withAlpha(40),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 40,
                          color: Colors.black,
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
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'To discover nearby connections and matching vibes in the background, AroundU needs your location permission set to Always Allow.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Primary Action Button
              FilledButton.icon(
                onPressed: _isRequesting ? null : _requestLocationPermission,
                icon: _isRequesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.black),
                        ),
                      )
                    : const Icon(Icons.share_location_rounded, size: 20),
                label: Text(
                  'Enable Location',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (ref.watch(currentUserModelProvider).valueOrNull == null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _onPermissionGranted,
                  child: Text(
                    'Maybe Later',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B), size: 18),
                label: Text(
                  'Sign Out / Go to Login',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w500,
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
