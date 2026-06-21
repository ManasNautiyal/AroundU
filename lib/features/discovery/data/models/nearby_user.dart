import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user profile in AroundU.
class UserModel {
  final String uid;
  final String name;
  final String bio;
  final List<String> profilePictures;
  final List<String> vibeTags;
  final bool isGhostMode;
  final DateTime lastActive;
  final Map<String, dynamic>? location; // Contains 'geopoint' and 'geohash'
  final String? beaconEmoji;
  final String? beaconMessage;
  final int likesCount;

  UserModel({
    required this.uid,
    required this.name,
    required this.bio,
    required this.profilePictures,
    required this.vibeTags,
    required this.isGhostMode,
    required this.lastActive,
    this.location,
    this.beaconEmoji,
    this.beaconMessage,
    this.likesCount = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      bio: map['bio'] ?? '',
      profilePictures: List<String>.from(map['profilePictures'] ?? []),
      vibeTags: List<String>.from(map['vibeTags'] ?? []),
      isGhostMode: map['isGhostMode'] ?? false,
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: map['location'] as Map<String, dynamic>?,
      beaconEmoji: map['beaconEmoji'] as String?,
      beaconMessage: map['beaconMessage'] as String?,
      likesCount: map['likesCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bio': bio,
      'profilePictures': profilePictures,
      'vibeTags': vibeTags,
      'isGhostMode': isGhostMode,
      'lastActive': Timestamp.fromDate(lastActive),
      if (location != null) 'location': location,
      if (beaconEmoji != null) 'beaconEmoji': beaconEmoji,
      if (beaconMessage != null) 'beaconMessage': beaconMessage,
      'likesCount': likesCount,
    };
  }
}

/// Represents a discovered nearby user with distance calculation.
class NearbyUser {
  final UserModel user;
  final double distanceInMeters;

  NearbyUser({
    required this.user,
    required this.distanceInMeters,
  });

  /// Fuzzed distance string for privacy and safety to prevent stalking.
  /// Strictly shows "Nearby (Within 100m)" or "Nearby" to fuzz exact location.
  String get fuzzedDistance {
    if (distanceInMeters <= 100) {
      return "Nearby (Within 100m)";
    }
    return "Nearby";
  }
}
