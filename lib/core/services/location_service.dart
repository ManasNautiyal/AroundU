import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';


part 'location_service.g.dart';

class LocationService {
  /// Check if location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check the current permission status.
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request permission to access location.
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get the current position of the user once.
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedForeverException();
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Get a stream of position updates.
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: _getLocationSettings(),
    );
  }

  /// Configure platform-specific location settings for battery efficiency and background tracking.
  LocationSettings _getLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.medium, // Battery-efficient accuracy
        distanceFilter: 30, // Update location only if moved more than 30 meters
        intervalDuration: const Duration(minutes: 3), // Check interval (3 minutes)
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "AroundU is running in the background to discover nearby connections.",
          notificationTitle: "AroundU active nearby",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 30,
        activityType: ActivityType.fitness, // Highly battery optimized
        pauseLocationUpdatesAutomatically: true, // Automatically pause when stationary
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 30,
    );
  }
}

class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();
  @override
  String toString() => 'Location services are disabled.';
}

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();
  @override
  String toString() => 'Location permission was denied.';
}

class LocationPermissionDeniedForeverException implements Exception {
  const LocationPermissionDeniedForeverException();
  @override
  String toString() => 'Location permissions are permanently denied.';
}

@riverpod
LocationService locationService(LocationServiceRef ref) {
  return LocationService();
}

@riverpod
Stream<Position> userPosition(UserPositionRef ref) async* {
  final locService = ref.watch(locationServiceProvider);
  Position? currentPos;
  try {
    currentPos = await locService.getCurrentPosition();
  } catch (e) {
    try {
      currentPos = await Geolocator.getLastKnownPosition();
    } catch (_) {}
  }

  if (currentPos != null) {
    yield currentPos;
  }

  try {
    final stream = locService.getPositionStream();
    await for (final pos in stream) {
      yield pos;
    }
  } catch (e) {
    // Stream ended or permission lost
  }
}

final locationPermissionAndServiceStatusProvider = FutureProvider<bool>((ref) async {
  final locService = ref.watch(locationServiceProvider);
  final serviceEnabled = await locService.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return false;
  }
  final permission = await locService.checkPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    return false;
  }
  return true;
});

