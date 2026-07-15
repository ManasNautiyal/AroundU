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
        'location': {
          'geohash': geoFirePoint.geohash,
          'geopoint': geoFirePoint.geopoint,
        },
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Seeding: If there are no other users or only 1 user (ourselves), seed 3 nearby mock users dynamically.
      final usersSnap = await _firestore.collection('users').limit(5).get();
      if (usersSnap.docs.length <= 1) {
        final mockProfiles = [
          {
            'name': 'Sarah',
            'bio': 'Art student & photography lover. Always down for coffee and museum walks. ☕🎨',
            'profilePictures': ['https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500'],
            'isGhostMode': false,
            'likesCount': 4,
            'latOffset': 0.0015,
            'lngOffset': 0.0012,
          },
          {
            'name': 'Marcus',
            'bio': 'Software engineer by day, guitarist by night. Let\'s talk music and tech! 🎵🎸',
            'profilePictures': ['https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500'],
            'isGhostMode': false,
            'likesCount': 7,
            'latOffset': -0.0012,
            'lngOffset': -0.0018,
          },
          {
            'name': 'Elena',
            'bio': 'Fitness enthusiast & food lover. Looking for a workout buddy or pizza enthusiast! 🍕🏋️',
            'profilePictures': ['https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500'],
            'isGhostMode': false,
            'likesCount': 12,
            'latOffset': 0.0022,
            'lngOffset': -0.0011,
          },
        ];

        for (final profile in mockProfiles) {
          final mockUid = 'mock_${profile['name']!.toString().toLowerCase()}';
          if (mockUid == uid) continue; // Skip if somehow matching current user's uid
          
          final latOffset = profile['latOffset'] as double;
          final lngOffset = profile['lngOffset'] as double;
          final mockLat = latitude + latOffset;
          final mockLng = longitude + lngOffset;
          final mockGeoFirePoint = GeoFirePoint(GeoPoint(mockLat, mockLng));

          await _firestore.collection('users').doc(mockUid).set({
            'name': profile['name'],
            'bio': profile['bio'],
            'profilePictures': profile['profilePictures'],
            'isGhostMode': profile['isGhostMode'],
            'likesCount': profile['likesCount'],
            'lastActive': FieldValue.serverTimestamp(),
            'location': {
              'geohash': mockGeoFirePoint.geohash,
              'geopoint': mockGeoFirePoint.geopoint,
            },
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG: Failed to update user location or seed mock users: $e');
    }
  }

  /// Streams nearby users within [maxDistanceInMeters] of the current user.
  /// Automatically filters out the current user, ghost mode users, and blocked users.
  /// The Firestore geo-query always uses a 10 km radius for a warm cache;
  /// [maxDistanceInMeters] is enforced client-side for fine-grained filtering.
  Stream<List<NearbyUser>> getNearbyUsersStream({
    required String currentUserId,
    required Position currentPosition,
    List<String> blockedUserIds = const [],
    double maxDistanceInMeters = 500.0,
  }) {
    if (!_isFirebaseInitialized) {
      // Mock local fallback stream
      final mockProfiles = [
        UserModel(
          uid: 'mock_sarah',
          name: 'Sarah',
          bio: 'Art student & photography lover. Always down for coffee and museum walks. ☕🎨',
          profilePictures: const ['https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500'],
          isGhostMode: false,
          likesCount: 4,
          lastActive: DateTime.now(),
        ),
        UserModel(
          uid: 'mock_marcus',
          name: 'Marcus',
          bio: 'Software engineer by day, guitarist by night. Let\'s talk music and tech! 🎵🎸',
          profilePictures: const ['https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500'],
          isGhostMode: false,
          likesCount: 7,
          lastActive: DateTime.now(),
        ),
        UserModel(
          uid: 'mock_elena',
          name: 'Elena',
          bio: 'Fitness enthusiast & food lover. Looking for a workout buddy or pizza enthusiast! 🍕🏋️',
          profilePictures: const ['https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500'],
          isGhostMode: false,
          likesCount: 12,
          lastActive: DateTime.now(),
        ),
      ];

      final List<NearbyUser> nearbyList = [];
      final offsets = [
        [0.0015, 0.0012],
        [-0.0012, -0.0018],
        [0.0022, -0.0011],
      ];

      for (int i = 0; i < mockProfiles.length; i++) {
        final profile = mockProfiles[i];
        final lat = currentPosition.latitude + offsets[i][0];
        final lng = currentPosition.longitude + offsets[i][1];
        final distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          lat,
          lng,
        );

        nearbyList.add(NearbyUser(
          user: profile,
          distanceInMeters: distance,
        ));
      }

      nearbyList.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
      return Stream.value(nearbyList);
    }

    try {
      final collectionRef = _firestore.collection('users');
      final geoRef = GeoCollectionReference(collectionRef);
      
      final center = GeoFirePoint(GeoPoint(currentPosition.latitude, currentPosition.longitude));
      
      // Subscribe to users within 10.0 km (and filter to 100 meters client-side below)
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
          
          // Client-side filter to the user's chosen range
          if (distance <= maxDistanceInMeters) {
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

@riverpod
Stream<List<NearbyUser>> nearbyUsers(NearbyUsersRef ref, {required String currentUserId}) {
  final repository = ref.watch(discoveryRepositoryProvider);
  final positionAsync = ref.watch(userPositionProvider);
  final blockedUsersAsync = ref.watch(blockedUsersStreamProvider(currentUserId: currentUserId));
  final isGhostMode = ref.watch(ghostModeControllerProvider);
  final rangeInMeters = ref.watch(discoveryRangeFilterProvider);
  
  final blockedUserIds = blockedUsersAsync.valueOrNull ?? const [];
  
  return positionAsync.when(
    data: (position) {
      // ignore: avoid_print
      print('DEBUG MY CURRENT POSITION: lat=${position.latitude}, lng=${position.longitude}');
      if (!isGhostMode) {
        // Periodic location update to Firestore only when NOT in Ghost Mode
        repository.updateUserLocation(
          uid: currentUserId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
      
      return repository.getNearbyUsersStream(
        currentUserId: currentUserId,
        currentPosition: position,
        blockedUserIds: blockedUserIds,
        maxDistanceInMeters: rangeInMeters,
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

