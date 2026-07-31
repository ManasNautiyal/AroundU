import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, voiceNote, location }

class ReplyToModel {
  final String messageId;
  final String senderName;
  final String text;

  ReplyToModel({
    required this.messageId,
    required this.senderName,
    required this.text,
  });

  factory ReplyToModel.fromMap(Map<String, dynamic> map) {
    return ReplyToModel(
      messageId: map['messageId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderName': senderName,
      'text': text,
    };
  }
}

/// Represents a single message in a chat room.
class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? mediaUrl;
  final int? durationSeconds;
  final ReplyToModel? replyTo;
  final Map<String, String> reactions; // userId -> emoji
  final bool isDeleted;
  final bool isStarred;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.mediaUrl,
    this.durationSeconds,
    this.replyTo,
    this.reactions = const {},
    this.isDeleted = false,
    this.isStarred = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    MessageType parsedType = MessageType.text;
    final typeStr = map['type'] as String?;
    if (typeStr != null) {
      if (typeStr == 'image') parsedType = MessageType.image;
      if (typeStr == 'voiceNote') parsedType = MessageType.voiceNote;
      if (typeStr == 'location') parsedType = MessageType.location;
    }

    ReplyToModel? replyToData;
    if (map['replyTo'] != null && map['replyTo'] is Map<String, dynamic>) {
      replyToData = ReplyToModel.fromMap(Map<String, dynamic>.from(map['replyTo']));
    }

    Map<String, String> reactionsMap = {};
    if (map['reactions'] != null && map['reactions'] is Map) {
      reactionsMap = Map<String, String>.from(map['reactions']);
    }

    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      type: parsedType,
      mediaUrl: map['mediaUrl'],
      durationSeconds: map['durationSeconds'] as int?,
      replyTo: replyToData,
      reactions: reactionsMap,
      isDeleted: map['isDeleted'] ?? false,
      isStarred: map['isStarred'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type.name,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (replyTo != null) 'replyTo': replyTo!.toMap(),
      'reactions': reactions,
      'isDeleted': isDeleted,
      'isStarred': isStarred,
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    String? mediaUrl,
    int? durationSeconds,
    ReplyToModel? replyTo,
    Map<String, String>? reactions,
    bool? isDeleted,
    bool? isStarred,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      isDeleted: isDeleted ?? this.isDeleted,
      isStarred: isStarred ?? this.isStarred,
    );
  }
}
