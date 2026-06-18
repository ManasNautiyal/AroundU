import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/location_service.dart';
import '../models/nearby_user.dart';

part 'discovery_repository.g.dart';

class DiscoveryRepository {
  final FirebaseFirestore _firestore;

  DiscoveryRepository(this._firestore);

  /// Updates the user's location in Firestore as a GeoPoint with GeoHash.
  Future<void> updateUserLocation({
    required String uid,
    required double latitude,
    required double longitude,
  }) async {
    final geoFirePoint = GeoFirePoint(GeoPoint(latitude, longitude));
    await _firestore.collection('users').doc(uid).set({
      'location': {
        'geohash': geoFirePoint.geohash,
        'geopoint': geoFirePoint.geopoint,
      },
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Streams nearby users within 100 meters (0.1 km) of the current user.
  /// Automatically filters out the current user, ghost mode users, and blocked users.
  Stream<List<NearbyUser>> getNearbyUsersStream({
    required String currentUserId,
    required Position currentPosition,
    List<String> blockedUserIds = const [],
  }) {
    final collectionRef = _firestore.collection('users');
    final geoRef = GeoCollectionReference(collectionRef);
    
    final center = GeoFirePoint(GeoPoint(currentPosition.latitude, currentPosition.longitude));
    
    // Subscribe to users within 0.1 km (100 meters)
    return geoRef.subscribeWithin(
      center: center,
      radiusInKm: 0.1,
      field: 'location',
      geopointFrom: (data) {
        final locationMap = data['location'] as Map<String, dynamic>?;
        if (locationMap == null) {
          throw Exception('Location field is missing');
        }
        return locationMap['geopoint'] as GeoPoint;
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
        
        // Exclude users in Ghost Mode
        if (user.isGhostMode) continue;
        
        // Exclude blocked users
        if (blockedUserIds.contains(user.uid)) continue;
        
        final locationMap = data['location'] as Map<String, dynamic>?;
        final geopoint = locationMap?['geopoint'] as GeoPoint?;
        if (geopoint == null) continue;
        
        // Fine-grained client-side distance calculation in meters
        final distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          geopoint.latitude,
          geopoint.longitude,
        );
        
        // Strictly filter to users within 100 meters
        if (distance <= 100.0) {
          nearbyList.add(NearbyUser(
            user: user,
            distanceInMeters: distance,
          ));
        }
      }
      
      // Sort by distance (closest first)
      nearbyList.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
      return nearbyList;
    });
  }
}

@riverpod
DiscoveryRepository discoveryRepository(DiscoveryRepositoryRef ref) {
  return DiscoveryRepository(FirebaseFirestore.instance);
}

@riverpod
Stream<List<NearbyUser>> nearbyUsers(NearbyUsersRef ref, {required String currentUserId}) {
  final repository = ref.watch(discoveryRepositoryProvider);
  final positionAsync = ref.watch(userPositionProvider);
  
  return positionAsync.when(
    data: (position) {
      // Periodic location update to Firestore when position changes
      repository.updateUserLocation(
        uid: currentUserId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      return repository.getNearbyUsersStream(
        currentUserId: currentUserId,
        currentPosition: position,
        // Blocked list could also be fetched from another provider in the future
        blockedUserIds: [],
      );
    },
    error: (err, stack) => Stream.value([]),
    loading: () => Stream.value([]),
  );
}
