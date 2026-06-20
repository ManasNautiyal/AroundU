import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a block relationship between two users.
class BlockModel {
  final String id;
  final String blockerId;
  final String blockedId;
  final DateTime timestamp;

  BlockModel({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    required this.timestamp,
  });

  factory BlockModel.fromMap(Map<String, dynamic> map, String id) {
    return BlockModel(
      id: id,
      blockerId: map['blockerId'] ?? '',
      blockedId: map['blockedId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blockerId': blockerId,
      'blockedId': blockedId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
