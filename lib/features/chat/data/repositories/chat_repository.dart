import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import '../models/message_model.dart';
import '../models/proximity_room_model.dart';
import '../../../discovery/presentation/controllers/user_providers.dart';
import '../../../../core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

part 'chat_repository.g.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository(this._firestore);

  /// Sends a chat message with optional media, reply, or voice note parameters.
  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
    int? durationSeconds,
    ReplyToModel? replyTo,
  }) async {
    final messageData = {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': type.name,
      '?mediaUrl': mediaUrl,
      '?durationSeconds': durationSeconds,
      if (replyTo != null) 'replyTo': replyTo.toMap(),
      'reactions': {},
      'isDeleted': false,
      'isStarred': false,
    };

    await _firestore
        .collection('chats')
        .doc(matchId)
        .collection('messages')
        .add(messageData);
  }

  /// Mark all unread messages from the other user as read.
  Future<void> markMessagesAsRead({
    required String matchId,
    required String currentUserId,
  }) async {
    final snap = await _firestore
        .collection('chats')
        .doc(matchId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    bool hasUpdates = false;
    for (var doc in snap.docs) {
      if (doc.data()['senderId'] != currentUserId) {
        batch.update(doc.reference, {'isRead': true});
        hasUpdates = true;
      }
    }
    if (hasUpdates) {
      await batch.commit();
    }
  }

  /// Toggle an emoji reaction on a message.
  Future<void> toggleReaction({
    required String matchId,
    required String messageId,
    required String userId,
    required String emoji,
    bool isProximityRoom = false,
  }) async {
    final docRef = isProximityRoom
        ? _firestore.collection('proximity_rooms').doc(matchId).collection('messages').doc(messageId)
        : _firestore.collection('chats').doc(matchId).collection('messages').doc(messageId);

    final snap = await docRef.get();
    if (!snap.exists) return;

    Map<String, dynamic> reactions = Map<String, dynamic>.from(snap.data()?['reactions'] ?? {});
    if (reactions[userId] == emoji) {
      reactions.remove(userId);
    } else {
      reactions[userId] = emoji;
    }

    await docRef.update({'reactions': reactions});
  }

  /// Delete a message (mark as deleted).
  Future<void> deleteMessage({
    required String matchId,
    required String messageId,
    bool isProximityRoom = false,
  }) async {
    final docRef = isProximityRoom
        ? _firestore.collection('proximity_rooms').doc(matchId).collection('messages').doc(messageId)
        : _firestore.collection('chats').doc(matchId).collection('messages').doc(messageId);

    await docRef.update({
      'text': 'This message was deleted',
      'isDeleted': true,
      'mediaUrl': null,
    });
  }

  /// Set typing status for a user in a match chat.
  Future<void> setTypingStatus({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {
    await _firestore.collection('chats').doc(matchId).collection('typing').doc(userId).set({
      'isTyping': isTyping,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get live typing status stream for a match chat.
  Stream<Map<String, bool>> getTypingStatusStream(String matchId) {
    return _firestore.collection('chats').doc(matchId).collection('typing').snapshots().map((snap) {
      Map<String, bool> map = {};
      for (var doc in snap.docs) {
        map[doc.id] = doc.data()['isTyping'] ?? false;
      }
      return map;
    });
  }

  /// Streams messages for a given match, ordered by timestamp descending.
  Stream<List<MessageModel>> getMessagesStream(String matchId) {
    return _firestore
        .collection('chats')
        .doc(matchId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => MessageModel.fromMap(doc.data(), doc.id)).toList());
  }

  /// Streams messages for a given proximity room.
  Stream<List<MessageModel>> getProximityRoomMessagesStream(String roomId) {
    return _firestore
        .collection('proximity_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => MessageModel.fromMap(doc.data(), doc.id)).toList());
  }

  /// Sends a message to a proximity room.
  Future<void> sendProximityRoomMessage({
    required String roomId,
    required String senderId,
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
    int? durationSeconds,
    ReplyToModel? replyTo,
  }) async {
    final messageData = {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type.name,
      '?mediaUrl': mediaUrl,
      '?durationSeconds': durationSeconds,
      if (replyTo != null) 'replyTo': replyTo.toMap(),
      'reactions': {},
      'isDeleted': false,
    };

    await _firestore
        .collection('proximity_rooms')
        .doc(roomId)
        .collection('messages')
        .add(messageData);
  }

  /// Creates a dynamic proximity chat room.
  Future<void> createProximityRoom({
    required String name,
    required String creatorId,
    required double latitude,
    required double longitude,
    double radiusInMeters = 100.0,
  }) async {
    final geoFirePoint = GeoFirePoint(GeoPoint(latitude, longitude));
    final roomData = {
      'name': name,
      'creatorId': creatorId,
      'location': {
        'geohash': geoFirePoint.geohash,
        'geopoint': geoFirePoint.geopoint,
      },
      'radiusInMeters': radiusInMeters,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('proximity_rooms').add(roomData);
  }

  /// Deletes a proximity room (for the creator or auto-cleanup).
  Future<void> deleteProximityRoom(String roomId) async {
    try {
      await _firestore.collection('proximity_rooms').doc(roomId).delete();
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG: Error deleting proximity room: $e');
    }
  }

  /// Streams dynamic proximity rooms within 10km.
  /// Automatically deletes rooms if the creator moves out of the room's range.
  Stream<List<ProximityRoomModel>> getNearbyProximityRooms({
    required double latitude,
    required double longitude,
    String? currentUserId,
  }) {
    final collectionRef = _firestore.collection('proximity_rooms');
    final geoRef = GeoCollectionReference(collectionRef);
    final center = GeoFirePoint(GeoPoint(latitude, longitude));

    return geoRef.subscribeWithin(
      center: center,
      radiusInKm: 10.0,
      field: 'location',
      geopointFrom: (data) {
        final locationMap = data['location'] as Map<String, dynamic>?;
        return locationMap?['geopoint'] as GeoPoint;
      },
      strictMode: true,
    ).map((snapshots) {
      final List<ProximityRoomModel> rooms = [];
      for (final doc in snapshots) {
        final data = doc.data();
        if (data == null) continue;
        final room = ProximityRoomModel.fromMap(data, doc.id);
        
        final geopoint = room.location['geopoint'] as GeoPoint?;
        if (geopoint == null) continue;

        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          geopoint.latitude,
          geopoint.longitude,
        );

        // Auto-delete room if creator moved out of the room's range
        if (currentUserId != null && room.creatorId == currentUserId && distance > room.radiusInMeters) {
          deleteProximityRoom(doc.id);
          continue;
        }

        if (distance <= room.radiusInMeters) {
          rooms.add(room);
        }
      }
      return rooms;
    });
  }
}

@riverpod
ChatRepository chatRepository(ChatRepositoryRef ref) {
  return ChatRepository(FirebaseFirestore.instance);
}

@riverpod
Stream<List<MessageModel>> messagesStream(MessagesStreamRef ref, {required String matchId}) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getMessagesStream(matchId);
}

@riverpod
Stream<Map<String, bool>> typingStatusStream(TypingStatusStreamRef ref, {required String matchId}) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getTypingStatusStream(matchId);
}

// Proximity status provider
@riverpod
class ProximityStatus extends _$ProximityStatus {
  @override
  bool build(String userId) {
    final positionAsync = ref.watch(userPositionProvider);
    final targetProfileAsync = ref.watch(userProfileProvider(userId));

    final position = positionAsync.valueOrNull;
    final targetProfile = targetProfileAsync.valueOrNull;

    if (position == null || targetProfile == null) {
      return false;
    }

    if (targetProfile.isGhostMode || targetProfile.location == null) {
      return false;
    }

    final targetLocation = targetProfile.location!['geopoint'] as GeoPoint?;
    if (targetLocation == null) {
      return false;
    }

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      targetLocation.latitude,
      targetLocation.longitude,
    );

    return distance <= 100.0;
  }

  void toggleProximity() {
    state = !state;
  }
}
