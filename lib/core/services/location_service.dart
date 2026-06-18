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
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update location if moved more than 10 meters
        intervalDuration: const Duration(seconds: 15), // Stream update interval
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "AroundU is running in the background to discover nearby connections.",
          notificationTitle: "AroundU active nearby",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        activityType: ActivityType.otherNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
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
Stream<Position> userPosition(UserPositionRef ref) {
  final locService = ref.watch(locationServiceProvider);
  return locService.getPositionStream();
}
