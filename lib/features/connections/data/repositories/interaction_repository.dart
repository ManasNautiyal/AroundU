import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/interaction_model.dart';
import '../models/message_request_model.dart';

part 'interaction_repository.g.dart';


class InteractionRepository {
  final FirebaseFirestore _firestore;

  // Local Mock Databases (used if Firebase isn't initialized)
  final List<InteractionModel> _mockLikes = [];
  final List<MatchModel> _mockMatches = [];
  
  // StreamControllers to notify changes in Mock Streams
  final _matchesController = StreamController<List<MatchModel>>.broadcast();
  final _incomingLikesController = StreamController<List<InteractionModel>>.broadcast();
  final _sentLikesController = StreamController<List<InteractionModel>>.broadcast();

  InteractionRepository(this._firestore);

  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Sends a Like. Returns true if a mutual match occurred.
  Future<bool> sendLike({required String currentUserId, required String targetUserId}) async {
    if (_isFirebaseInitialized) {
      // 1. Write Like
      final likeRef = _firestore.collection('likes').doc('${currentUserId}_$targetUserId');
      await likeRef.set({
        'senderId': currentUserId,
        'receiverId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Increment target user's likesCount
      await _firestore.collection('users').doc(targetUserId).update({
        'likesCount': FieldValue.increment(1),
      });

      // 2. Check if mutual like exists
      final mutualLikeDoc = await _firestore.collection('likes').doc('${targetUserId}_$currentUserId').get();
      if (mutualLikeDoc.exists) {
        // Create Match
        final matchId = currentUserId.compareTo(targetUserId) < 0
            ? '${currentUserId}_$targetUserId'
            : '${targetUserId}_$currentUserId';
            
        await _firestore.collection('matches').doc(matchId).set({
          'user1Id': currentUserId,
          'user2Id': targetUserId,
          'userIds': [currentUserId, targetUserId],
          'timestamp': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } else {
      // Mock local memory logic
      final alreadyLiked = _mockLikes.any((l) => l.senderId == currentUserId && l.receiverId == targetUserId);
      if (alreadyLiked) return false;

      // Check if already liked by target
      final hasLikedMe = _mockLikes.any((l) => l.senderId == targetUserId && l.receiverId == currentUserId);
      
      // Save current user's like
      _mockLikes.add(InteractionModel(
        id: 'like_${currentUserId}_$targetUserId',
        senderId: currentUserId,
        receiverId: targetUserId,
        type: InteractionType.like,
        timestamp: DateTime.now(),
      ));

      _sentLikesController.add(_mockLikes.where((l) => l.senderId == currentUserId).toList());
      _incomingLikesController.add(_mockLikes.where((l) => l.receiverId == targetUserId).toList());

      if (hasLikedMe) {
        final match = MatchModel(
          id: 'match_${currentUserId}_$targetUserId',
          user1Id: currentUserId,
          user2Id: targetUserId,
          userIds: [currentUserId, targetUserId],
          timestamp: DateTime.now(),
        );
        _mockMatches.add(match);
        _matchesController.add(List.from(_mockMatches));
        return true;
      }
      return false;
    }
  }


  /// Streams mutual matches for the user
  Stream<List<MatchModel>> getMatchesStream(String currentUserId) {
    if (_isFirebaseInitialized) {
      return _firestore
          .collection('matches')
          .where('userIds', arrayContains: currentUserId)
          .snapshots()
          .map((snap) => snap.docs.map((d) => MatchModel.fromMap(d.data(), d.id)).toList());
    } else {
      // Yield current state first
      Timer.run(() => _matchesController.add(_mockMatches));
      return _matchesController.stream;
    }
  }


  /// Sends a connection request with an intro message note.
  Future<void> sendConnectionRequest({
    required String currentUserId,
    required String targetUserId,
    required String introMessage,
  }) async {
    if (_isFirebaseInitialized) {
      await _firestore.collection('connection_requests').add({
        'senderId': currentUserId,
        'receiverId': targetUserId,
        'introMessage': introMessage,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      // Mock local write log
      // ignore: avoid_print
      print('Mock Connection Request: $currentUserId -> $targetUserId with msg: "$introMessage"');
    }
  }

  /// Streams incoming connection requests.
  Stream<List<MessageRequestModel>> getConnectionRequestsStream(String currentUserId) {
    if (_isFirebaseInitialized) {
      return _firestore
          .collection('connection_requests')
          .where('receiverId', isEqualTo: currentUserId)
          .snapshots()
          .map((snap) => snap.docs.map((d) => MessageRequestModel.fromMap(d.data(), d.id)).toList());
    } else {
      return const Stream.empty();
    }
  }

  /// Accepts a connection request: creates a match, writes the first chat message, and deletes the request.
  Future<void> acceptConnectionRequest(MessageRequestModel request) async {
    if (_isFirebaseInitialized) {
      final matchId = request.senderId.compareTo(request.receiverId) < 0
          ? '${request.senderId}_${request.receiverId}'
          : '${request.receiverId}_${request.senderId}';

      // 1. Create match first and await its completion so that it exists in the database
      // when the message write security rule checks for its existence.
      final matchRef = _firestore.collection('matches').doc(matchId);
      await matchRef.set({
        'user1Id': request.senderId,
        'user2Id': request.receiverId,
        'userIds': [request.senderId, request.receiverId],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Add intro message as first chat message and delete connection request
      final batch = _firestore.batch();
      
      final messageRef = _firestore
          .collection('chats')
          .doc(matchId)
          .collection('messages')
          .doc();
      batch.set(messageRef, {
        'senderId': request.senderId,
        'text': request.introMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 3. Delete connection request
      final requestRef = _firestore.collection('connection_requests').doc(request.id);
      batch.delete(requestRef);

      await batch.commit();
    }
  }

  /// Declines a connection request: deletes the request.
  Future<void> declineConnectionRequest(String requestId) async {
    if (_isFirebaseInitialized) {
      await _firestore.collection('connection_requests').doc(requestId).delete();
    }
  }

  /// Unlikes a user.
  Future<void> unlikeUser({required String currentUserId, required String targetUserId}) async {
    if (_isFirebaseInitialized) {
      final likeRef = _firestore.collection('likes').doc('${currentUserId}_$targetUserId');
      await likeRef.delete();

      // Decrement target user's likesCount
      await _firestore.collection('users').doc(targetUserId).update({
        'likesCount': FieldValue.increment(-1),
      });

      // Also delete the match if it exists
      final matchId = currentUserId.compareTo(targetUserId) < 0
          ? '${currentUserId}_$targetUserId'
          : '${targetUserId}_$currentUserId';
      await _firestore.collection('matches').doc(matchId).delete();
    } else {
      _mockLikes.removeWhere((l) => l.senderId == currentUserId && l.receiverId == targetUserId);
      _mockMatches.removeWhere((m) => m.id == 'match_${currentUserId}_$targetUserId' || m.id == 'match_${targetUserId}_$currentUserId');
      _matchesController.add(List.from(_mockMatches));
      
      _sentLikesController.add(_mockLikes.where((l) => l.senderId == currentUserId).toList());
      _incomingLikesController.add(_mockLikes.where((l) => l.receiverId == targetUserId).toList());
    }
  }

  /// Streams received likes for a user.
  Stream<List<InteractionModel>> getReceivedLikesStream(String userId) {
    if (_isFirebaseInitialized) {
      return _firestore
          .collection('likes')
          .where('receiverId', isEqualTo: userId)
          .snapshots()
          .map((snap) => snap.docs.map((d) => InteractionModel.fromMap(d.data(), d.id)).toList());
    } else {
      Timer.run(() => _incomingLikesController.add(_mockLikes.where((l) => l.receiverId == userId).toList()));
      return _incomingLikesController.stream;
    }
  }

  /// Streams sent likes by a user.
  Stream<List<InteractionModel>> getSentLikesStream(String userId) {
    if (_isFirebaseInitialized) {
      return _firestore
          .collection('likes')
          .where('senderId', isEqualTo: userId)
          .snapshots()
          .map((snap) => snap.docs.map((d) => InteractionModel.fromMap(d.data(), d.id)).toList());
    } else {
      Timer.run(() => _sentLikesController.add(_mockLikes.where((l) => l.senderId == userId).toList()));
      return _sentLikesController.stream;
    }
  }
}

@riverpod
InteractionRepository interactionRepository(InteractionRepositoryRef ref) {
  return InteractionRepository(FirebaseFirestore.instance);
}

@riverpod
Stream<List<MatchModel>> matchesStream(MatchesStreamRef ref, {required String currentUserId}) {
  final repo = ref.watch(interactionRepositoryProvider);
  return repo.getMatchesStream(currentUserId);
}


@riverpod
Stream<List<MessageRequestModel>> connectionRequestsStream(ConnectionRequestsStreamRef ref, {required String currentUserId}) {
  final repo = ref.watch(interactionRepositoryProvider);
  return repo.getConnectionRequestsStream(currentUserId);
}

@riverpod
Stream<List<InteractionModel>> receivedLikesStream(ReceivedLikesStreamRef ref, {required String currentUserId}) {
  final repo = ref.watch(interactionRepositoryProvider);
  return repo.getReceivedLikesStream(currentUserId);
}

@riverpod
Stream<List<InteractionModel>> sentLikesStream(SentLikesStreamRef ref, {required String currentUserId}) {
  final repo = ref.watch(interactionRepositoryProvider);
  return repo.getSentLikesStream(currentUserId);
}
