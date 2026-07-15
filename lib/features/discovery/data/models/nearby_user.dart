import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user profile in AroundU.
class UserModel {
  final String uid;
  final String name;
  final String bio;
  final List<String> profilePictures;
  final bool isGhostMode;
  final DateTime lastActive;
  final Map<String, dynamic>? location; // Contains 'geopoint' and 'geohash'
  final int likesCount;

  UserModel({
    required this.uid,
    required this.name,
    required this.bio,
    required this.profilePictures,
    required this.isGhostMode,
    required this.lastActive,
    this.location,
    this.likesCount = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      bio: map['bio'] ?? '',
      profilePictures: List<String>.from(map['profilePictures'] ?? []),
      isGhostMode: map['isGhostMode'] ?? false,
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: map['location'] as Map<String, dynamic>?,
      likesCount: map['likesCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bio': bio,
      'profilePictures': profilePictures,
      'isGhostMode': isGhostMode,
      'lastActive': Timestamp.fromDate(lastActive),
      if (location != null) 'location': location,
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
  String get fuzzedDistance {
    if (distanceInMeters <= 100) {
      return "Nearby (Within 100m)";
    }
    return "Nearby";
  }
}
