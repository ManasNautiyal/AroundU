import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/message_model.dart';

part 'chat_repository.g.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  // Local Mock Message Store: Map of matchId -> list of messages
  final Map<String, List<MessageModel>> _mockChats = {};
  
  // StreamControllers to push updates for mock streams
  final Map<String, StreamController<List<MessageModel>>> _controllers = {};

  ChatRepository(this._firestore) {
    // Seed initial mock messages for matches to make the UI immediately interactive
    final initialMsgs = [
      MessageModel(
        id: 'msg_seed_1',
        senderId: 'mock_2', // Marcus
        text: 'Hey there! I saw we matched. Are you nearby?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      MessageModel(
        id: 'msg_seed_2',
        senderId: 'me',
        text: 'Hey Marcus! Yes, I am grabbing a coffee nearby. You?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      MessageModel(
        id: 'msg_seed_3',
        senderId: 'mock_2',
        text: 'Awesome, I just finished a workout at the gym here! 🏋️',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];

    // Seed mock chats bi-directionally
    _mockChats['match_me_mock_2'] = List.from(initialMsgs);
    _mockChats['match_mock_2_me'] = List.from(initialMsgs);
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

// Proximity status provider (Mocked state for each matched user)
@riverpod
class ProximityStatus extends _$ProximityStatus {
  @override
  bool build(String userId) {
    // By default, let's say Marcus is nearby, others are away for testing variety
    return userId == 'mock_2';
  }

  void toggleProximity() {
    state = !state;
  }
}
