import 'package:cloud_firestore/cloud_firestore.dart';

enum InteractionType { like, wave }

/// Represents an interaction (Like or Wave) between two users.
class InteractionModel {
  final String id;
  final String senderId;
  final String receiverId;
  final InteractionType type;
  final DateTime timestamp;

  InteractionModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.timestamp,
  });

  factory InteractionModel.fromMap(Map<String, dynamic> map, String id) {
    return InteractionModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      type: map['type'] == 'wave' ? InteractionType.wave : InteractionType.like,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type == InteractionType.wave ? 'wave' : 'like',
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// Represents a mutual match between two users.
class MatchModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final List<String> userIds;
  final DateTime timestamp;

  MatchModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.userIds,
    required this.timestamp,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map, String id) {
    return MatchModel(
      id: id,
      user1Id: map['user1Id'] ?? '',
      user2Id: map['user2Id'] ?? '',
      userIds: List<String>.from(map['userIds'] ?? []),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'userIds': userIds,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
