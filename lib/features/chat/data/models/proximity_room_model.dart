import 'package:cloud_firestore/cloud_firestore.dart';

class ProximityRoomModel {
  final String id;
  final String name;
  final String creatorId;
  final Map<String, dynamic> location; // Contains 'geopoint' and 'geohash'
  final double radiusInMeters;
  final DateTime createdAt;

  ProximityRoomModel({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.location,
    required this.radiusInMeters,
    required this.createdAt,
  });

  factory ProximityRoomModel.fromMap(Map<String, dynamic> map, String id) {
    return ProximityRoomModel(
      id: id,
      name: map['name'] ?? '',
      creatorId: map['creatorId'] ?? '',
      location: map['location'] as Map<String, dynamic>? ?? {},
      radiusInMeters: (map['radiusInMeters'] as num?)?.toDouble() ?? 100.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'creatorId': creatorId,
      'location': location,
      'radiusInMeters': radiusInMeters,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
