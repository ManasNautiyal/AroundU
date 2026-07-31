import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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

  // Local Mock Message Store: Map of matchId -> list of messages
  final Map<String, List<MessageModel>> _mockChats = {};
  
  // StreamControllers to push updates for mock streams
  final Map<String, StreamController<List<MessageModel>>> _controllers = {};

  // Mock Proximity Room Stores
  final Map<String, ProximityRoomModel> _mockProximityRooms = {};
  final Map<String, List<MessageModel>> _mockProximityMessages = {};
  final Map<String, StreamController<List<MessageModel>>> _proximityMessageControllers = {};

  // Mock Typing status store: matchId -> Map of userId -> bool
  final Map<String, Map<String, bool>> _mockTypingStatus = {};
  final Map<String, StreamController<Map<String, bool>>> _typingControllers = {};

  ChatRepository(this._firestore) {
    // Seed a mock proximity room near Lalit's mocked location (Dehradun, India)
    const mockRoomId = 'mock_room_1';
    final mockRoomGeopoint = GeoPoint(30.3004027, 78.0347056);
    _mockProximityRooms[mockRoomId] = ProximityRoomModel(
      id: mockRoomId,
      name: 'Library Zone',
      creatorId: 'system',
      location: {
        'geopoint': mockRoomGeopoint,
        'geohash': 'tts7',
      },
      radiusInMeters: 100.0,
      createdAt: DateTime.now(),
    );
  }

  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

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

    if (_isFirebaseInitialized) {
      await _firestore
          .collection('chats')
          .doc(matchId)
          .collection('messages')
          .add(messageData);
    } else {
      final newMessage = MessageModel(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
        type: type,
        mediaUrl: mediaUrl,
        durationSeconds: durationSeconds,
        replyTo: replyTo,
      );

      final list = _mockChats[matchId] ?? [];
      list.add(newMessage);
      _mockChats[matchId] = list;

      if (_controllers.containsKey(matchId)) {
        _controllers[matchId]!.add(List.from(list.reversed));
      }
    }
  }

  /// Mark all unread messages from the other user as read.
  Future<void> markMessagesAsRead({
    required String matchId,
    required String currentUserId,
  }) async {
    if (_isFirebaseInitialized) {
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
    } else {
      final list = _mockChats[matchId];
      if (list != null) {
        bool changed = false;
        for (int i = 0; i < list.length; i++) {
          if (list[i].senderId != currentUserId && !list[i].isRead) {
            list[i] = list[i].copyWith(isRead: true);
            changed = true;
          }
        }
        if (changed && _controllers.containsKey(matchId)) {
          _controllers[matchId]!.add(List.from(list.reversed));
        }
      }
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
    if (_isFirebaseInitialized) {
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
    } else {
      final list = isProximityRoom ? _mockProximityMessages[matchId] : _mockChats[matchId];
      if (list != null) {
        final index = list.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          final msg = list[index];
          final updatedReactions = Map<String, String>.from(msg.reactions);
          if (updatedReactions[userId] == emoji) {
            updatedReactions.remove(userId);
          } else {
            updatedReactions[userId] = emoji;
          }
          list[index] = msg.copyWith(reactions: updatedReactions);

          final controller = isProximityRoom ? _proximityMessageControllers[matchId] : _controllers[matchId];
          if (controller != null) {
            controller.add(List.from(list.reversed));
          }
        }
      }
    }
  }

  /// Delete a message (mark as deleted).
  Future<void> deleteMessage({
    required String matchId,
    required String messageId,
    bool isProximityRoom = false,
  }) async {
    if (_isFirebaseInitialized) {
      final docRef = isProximityRoom
          ? _firestore.collection('proximity_rooms').doc(matchId).collection('messages').doc(messageId)
          : _firestore.collection('chats').doc(matchId).collection('messages').doc(messageId);

      await docRef.update({
        'text': 'This message was deleted',
        'isDeleted': true,
        'mediaUrl': null,
      });
    } else {
      final list = isProximityRoom ? _mockProximityMessages[matchId] : _mockChats[matchId];
      if (list != null) {
        final index = list.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          list[index] = list[index].copyWith(
            text: 'This message was deleted',
            isDeleted: true,
            mediaUrl: null,
          );
          final controller = isProximityRoom ? _proximityMessageControllers[matchId] : _controllers[matchId];
          if (controller != null) {
            controller.add(List.from(list.reversed));
          }
        }
      }
    }
  }

  /// Set typing status for a user in a match chat.
  Future<void> setTypingStatus({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {
    if (_isFirebaseInitialized) {
      await _firestore.collection('chats').doc(matchId).collection('typing').doc(userId).set({
        'isTyping': isTyping,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      _mockTypingStatus[matchId] ??= {};
      _mockTypingStatus[matchId]![userId] = isTyping;

      if (_typingControllers.containsKey(matchId)) {
        _typingControllers[matchId]!.add(Map.from(_mockTypingStatus[matchId]!));
      }
    }
  }

  /// Get live typing status stream for a match chat.
  Stream<Map<String, bool>> getTypingStatusStream(String matchId) {
    if (_isFirebaseInitialized) {
      return _firestore.collection('chats').doc(matchId).collection('typing').snapshots().map((snap) {
        Map<String, bool> map = {};
        for (var doc in snap.docs) {
          map[doc.id] = doc.data()['isTyping'] ?? false;
        }
        return map;
      });
    } else {
      if (!_typingControllers.containsKey(matchId)) {
        _typingControllers[matchId] = StreamController<Map<String, bool>>.broadcast();
      }
      Timer.run(() => _typingControllers[matchId]!.add(_mockTypingStatus[matchId] ?? {}));
      return _typingControllers[matchId]!.stream;
    }
  }

  /// Streams messages for a given match, ordered by timestamp descending.
  Stream<List<MessageModel>> getMessagesStream(String matchId) {
    if (_isFirebaseInitialized) {
      return _firestore
          .collection('chats')
          .doc(matchId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map((doc) => MessageModel.fromMap(doc.data(), doc.id)).toList());
    } else {
      if (!_controllers.containsKey(matchId)) {
        _controllers[matchId] = StreamController<List<MessageModel>>.broadcast();
      }
      
      final list = _mockChats[matchId] ?? [];
      Timer.run(() => _controllers[matchId]!.add(List.from(list.reversed)));
      return _controllers[matchId]!.stream;
    }
  }

  /// Streams messages for a given proximity room.
  Stream<List<MessageModel>> getProximityRoomMessagesStream(String roomId) {
    if (_isFirebaseInitialized) {
      return _firestore
          .collection('proximity_rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map((doc) => MessageModel.fromMap(doc.data(), doc.id)).toList());
    } else {
      if (!_proximityMessageControllers.containsKey(roomId)) {
        _proximityMessageControllers[roomId] = StreamController<List<MessageModel>>.broadcast();
      }
      final list = _mockProximityMessages[roomId] ?? [];
      Timer.run(() => _proximityMessageControllers[roomId]!.add(List.from(list.reversed)));
      return _proximityMessageControllers[roomId]!.stream;
    }
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

    if (_isFirebaseInitialized) {
      await _firestore
          .collection('proximity_rooms')
          .doc(roomId)
          .collection('messages')
          .add(messageData);
    } else {
      final newMessage = MessageModel(
        id: 'pmsg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
        type: type,
        mediaUrl: mediaUrl,
        durationSeconds: durationSeconds,
        replyTo: replyTo,
      );

      final list = _mockProximityMessages[roomId] ?? [];
      list.add(newMessage);
      _mockProximityMessages[roomId] = list;

      if (_proximityMessageControllers.containsKey(roomId)) {
        _proximityMessageControllers[roomId]!.add(List.from(list.reversed));
      }
    }
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

    if (_isFirebaseInitialized) {
      await _firestore.collection('proximity_rooms').add(roomData);
    } else {
      final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';
      final newRoom = ProximityRoomModel(
        id: roomId,
        name: name,
        creatorId: creatorId,
        location: {
          'geopoint': GeoPoint(latitude, longitude),
          'geohash': geoFirePoint.geohash,
        },
        radiusInMeters: radiusInMeters,
        createdAt: DateTime.now(),
      );
      _mockProximityRooms[roomId] = newRoom;
    }
  }

  /// Streams dynamic proximity rooms within 10km.
  Stream<List<ProximityRoomModel>> getNearbyProximityRooms({
    required double latitude,
    required double longitude,
  }) {
    if (_isFirebaseInitialized) {
      _seedProximityRoomIfEmpty(latitude, longitude);

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

          if (distance <= room.radiusInMeters) {
            rooms.add(room);
          }
        }
        return rooms;
      });
    } else {
      final mockList = _mockProximityRooms.values.where((room) {
        final geopoint = room.location['geopoint'] as GeoPoint?;
        if (geopoint == null) return false;
        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          geopoint.latitude,
          geopoint.longitude,
        );
        return distance <= room.radiusInMeters;
      }).toList();
      
      final controller = StreamController<List<ProximityRoomModel>>.broadcast();
      Timer.run(() => controller.add(mockList));
      return controller.stream;
    }
  }

  Future<void> _seedProximityRoomIfEmpty(double latitude, double longitude) async {
    try {
      final snap = await _firestore.collection('proximity_rooms').limit(5).get();
      if (snap.docs.isEmpty) {
        final geoFirePoint = GeoFirePoint(GeoPoint(latitude, longitude));
        await _firestore.collection('proximity_rooms').add({
          'name': 'Library Zone',
          'creatorId': 'system',
          'location': {
            'geohash': geoFirePoint.geohash,
            'geopoint': geoFirePoint.geopoint,
          },
          'radiusInMeters': 100.0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG: Failed to seed proximity room: $e');
    }
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
    final isFirebaseInitialized = Firebase.apps.isNotEmpty;
    if (!isFirebaseInitialized) {
      return userId == 'mock_2';
    }

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
