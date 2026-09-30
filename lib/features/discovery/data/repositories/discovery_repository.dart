import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/location_service.dart';
import '../../../safety/data/repositories/block_service.dart';
import '../models/nearby_user.dart';
import '../../presentation/controllers/discovery_providers.dart';

part 'discovery_repository.g.dart';

class DiscoveryRepository {
  final FirebaseFirestore _firestore;

  DiscoveryRepository(this._firestore);

  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Updates the user's location in Firestore as a GeoPoint with GeoHash.
  Future<void> updateUserLocation({
    required String uid,
    required double latitude,
    required double longitude,
  }) async {
    if (!_isFirebaseInitialized) return;
    try {
      final geoFirePoint = GeoFirePoint(GeoPoint(latitude, longitude));
      await _firestore.collection('users').doc(uid).set({
        'location': geoFirePoint.data,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Location updated successfully
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG: Failed to update user location: $e');
    }
  }

  /// Streams all users within 10 km of [currentPosition] with their distances.
  /// This is a stable stream — only the position affects the Firestore query.
  /// Further filtering (range, ghost mode, blocked) is done client-side in
  /// a separate provider to avoid tearing down this stream on every filter change.
  Stream<List<NearbyUser>> getRawNearbyUsersStream({
    required String currentUserId,
    required Position currentPosition,
  }) {
    if (!_isFirebaseInitialized) {
      return Stream.value([]);
    }

    try {
      final collectionRef = _firestore.collection('users');
      final geoRef = GeoCollectionReference(collectionRef);
      
      final center = GeoFirePoint(GeoPoint(currentPosition.latitude, currentPosition.longitude));
      
      // Subscribe to users within 10 km; finer filtering is done client-side
      // in the nearbyUsersProvider to avoid re-subscribing on every filter change.
      return geoRef.subscribeWithin(
        center: center,
        radiusInKm: 10.0,
        field: 'location',
        geopointFrom: (data) {
          final locationMap = data['location'] as Map<String, dynamic>?;
          return locationMap?['geopoint'] as GeoPoint? ?? const GeoPoint(0, 0);
        },
        strictMode: true,
      ).map((snapshots) {
        final List<NearbyUser> nearbyList = [];
        for (final doc in snapshots) {
          // Exclude current user
          if (doc.id == currentUserId) continue;
          
          final data = doc.data();
          if (data == null) continue;
          
          final user = UserModel.fromMap(data, doc.id);
          
          final locationMap = data['location'] as Map<String, dynamic>?;
          final geopoint = locationMap?['geopoint'] as GeoPoint?;
          if (geopoint == null) continue;
          
          // Calculate distance in meters for client-side filtering
          final distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            geopoint.latitude,
            geopoint.longitude,
          );
          
          nearbyList.add(NearbyUser(
            user: user,
            distanceInMeters: distance,
          ));
        }
        
        // Sort by distance (closest first)
        nearbyList.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
        return nearbyList;
      });
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG: Failed to query users: $e');
      return Stream.value([]);
    }
  }
}

@riverpod
DiscoveryRepository discoveryRepository(DiscoveryRepositoryRef ref) {
  return DiscoveryRepository(FirebaseFirestore.instance);
}

/// Stable raw geo-stream that only depends on the user's position.
/// This avoids tearing down and re-subscribing the Firestore listener
/// every time a client-side filter (range, ghost mode, blocked) changes.
@riverpod
Stream<List<NearbyUser>> rawNearbyUsers(RawNearbyUsersRef ref, {required String currentUserId}) {
  final repository = ref.watch(discoveryRepositoryProvider);
  final positionAsync = ref.watch(userPositionProvider);
  final isGhostMode = ref.watch(ghostModeControllerProvider);
  
  return positionAsync.when(
    data: (position) {
      // ignore: avoid_print
      print('DEBUG MY CURRENT POSITION: lat=${position.latitude}, lng=${position.longitude}');
      if (!isGhostMode) {
        // Update own location in Firestore only when NOT in Ghost Mode
        repository.updateUserLocation(
          uid: currentUserId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
      
      return repository.getRawNearbyUsersStream(
        currentUserId: currentUserId,
        currentPosition: position,
      );
    },
    error: (err, stack) {
      // ignore: avoid_print
      print('DEBUG POSITION ERROR: $err');
      return Stream.value([]);
    },
    loading: () {
      // ignore: avoid_print
      print('DEBUG POSITION LOADING');
      return Stream.value([]);
    },
  );
}

/// Filtered provider that applies range, ghost mode, and blocked user filters
/// on top of the stable raw geo-stream. Changing these filters does NOT
/// re-subscribe to Firestore — only the client-side list is re-filtered.
@riverpod
AsyncValue<List<NearbyUser>> nearbyUsers(NearbyUsersRef ref, {required String currentUserId}) {
  final rawAsync = ref.watch(rawNearbyUsersProvider(currentUserId: currentUserId));
  final blockedUsersAsync = ref.watch(blockedUsersStreamProvider(currentUserId: currentUserId));
  final rangeInMeters = ref.watch(discoveryRangeFilterProvider);
  
  if (rawAsync.isLoading || blockedUsersAsync.isLoading) {
    // Preserve old data while refreshing if available
    if (rawAsync.hasValue) {
       // will just fall through to the filter below
    } else {
       return const AsyncLoading();
    }
  }
  
  if (rawAsync.hasError) {
    return AsyncError(rawAsync.error!, rawAsync.stackTrace!);
  }
  
  final blockedUserIds = blockedUsersAsync.valueOrNull ?? const [];
  final rawList = rawAsync.valueOrNull ?? const [];
  
  final filteredList = rawList.where((nearby) {
    // Exclude users in Ghost Mode
    if (nearby.user.isGhostMode) return false;
    // Exclude blocked users
    if (blockedUserIds.contains(nearby.user.uid)) return false;
    // Enforce the user's chosen discovery range
    if (nearby.distanceInMeters > rangeInMeters) return false;
    return true;
  }).toList()
    ..sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
    
  return AsyncData(filteredList);
}

