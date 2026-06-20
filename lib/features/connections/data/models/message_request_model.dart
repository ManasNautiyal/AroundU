import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a pending social connection request with an intro message note.
class MessageRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String introMessage;
  final DateTime timestamp;

  MessageRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.introMessage,
    required this.timestamp,
  });

  factory MessageRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageRequestModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      introMessage: map['introMessage'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'introMessage': introMessage,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
