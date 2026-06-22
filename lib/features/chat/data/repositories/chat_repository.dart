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

  /// Sends a chat message.
  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
  }) async {
    final messageData = {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    if (_isFirebaseInitialized) {
      await _firestore
          .collection('chats')
          .doc(matchId)
          .collection('messages')
          .add(messageData);
    } else {
      // Mock local message write
      final newMessage = MessageModel(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
      );

      final list = _mockChats[matchId] ?? [];
      list.add(newMessage);
      _mockChats[matchId] = list;

      // Notify the active stream controller
      if (_controllers.containsKey(matchId)) {
        _controllers[matchId]!.add(List.from(list.reversed));
      }
    }
  }

  /// Streams messages for a given match, ordered by timestamp descending (for inverted list view).
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
      // Mock stream implementation
      if (!_controllers.containsKey(matchId)) {
        _controllers[matchId] = StreamController<List<MessageModel>>.broadcast();
      }
      
      final list = _mockChats[matchId] ?? [];
      // Emit the inverted list (descending order for inverted ListView)
      Timer.run(() => _controllers[matchId]!.add(List.from(list.reversed)));
      return _controllers[matchId]!.stream;
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

  /// Streams dynamic proximity rooms within 10km, and filters them client-side based on room's custom radius.
  Stream<List<ProximityRoomModel>> getNearbyProximityRooms({
    required double latitude,
    required double longitude,
  }) {
    if (_isFirebaseInitialized) {
      final collectionRef = _firestore.collection('proximity_rooms');
      final geoRef = GeoCollectionReference(collectionRef);
      final center = GeoFirePoint(GeoPoint(latitude, longitude));

      return geoRef.subscribeWithin(
        center: center,
        radiusInKm: 10.0, // search within 10 km
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
      // Mock local fallback
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
  }) async {
    final messageData = {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
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
      );

      final list = _mockProximityMessages[roomId] ?? [];
      list.add(newMessage);
      _mockProximityMessages[roomId] = list;

      if (_proximityMessageControllers.containsKey(roomId)) {
        _proximityMessageControllers[roomId]!.add(List.from(list.reversed));
      }
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

// Proximity status provider (Mocked state for each matched user, real distance check on Firebase)
@riverpod
class ProximityStatus extends _$ProximityStatus {
  @override
  bool build(String userId) {
    // 1. If Firebase is not initialized, fall back to mock logic
    final isFirebaseInitialized = Firebase.apps.isNotEmpty;
    if (!isFirebaseInitialized) {
      // By default, let's say Marcus is nearby, others are away for testing variety
      return userId == 'mock_2';
    }

    // 2. Real Firebase proximity calculation:
    // Watch current user's position and target's profile
    final positionAsync = ref.watch(userPositionProvider);
    final targetProfileAsync = ref.watch(userProfileProvider(userId));

    final position = positionAsync.valueOrNull;
    final targetProfile = targetProfileAsync.valueOrNull;

    if (position == null || targetProfile == null) {
      return false;
    }

    // If target has ghost mode enabled or no location, they are not nearby
    if (targetProfile.isGhostMode || targetProfile.location == null) {
      return false;
    }

    final targetLocation = targetProfile.location!['geopoint'] as GeoPoint?;
    if (targetLocation == null) {
      return false;
    }

    // Calculate distance
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      targetLocation.latitude,
      targetLocation.longitude,
    );

    // Nearby if within 100 meters
    return distance <= 100.0;
  }

  void toggleProximity() {
    state = !state;
  }
}
