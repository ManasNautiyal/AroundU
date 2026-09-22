import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/interaction_model.dart';
import '../models/message_request_model.dart';

part 'interaction_repository.g.dart';


class InteractionRepository {
  final FirebaseFirestore _firestore;

  InteractionRepository(this._firestore);

  /// Sends a Like. Returns true if a mutual match occurred.
  Future<bool> sendLike({required String currentUserId, required String targetUserId}) async {
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
  }

  /// Streams mutual matches for the user
  Stream<List<MatchModel>> getMatchesStream(String currentUserId) {
    return _firestore
        .collection('matches')
        .where('userIds', arrayContains: currentUserId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MatchModel.fromMap(d.data(), d.id)).toList());
  }

  /// Sends a connection request with an intro message note.
  Future<void> sendConnectionRequest({
    required String currentUserId,
    required String targetUserId,
    required String introMessage,
  }) async {
    await _firestore.collection('connection_requests').add({
      'senderId': currentUserId,
      'receiverId': targetUserId,
      'introMessage': introMessage,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Streams incoming and outgoing connection requests.
  Stream<List<MessageRequestModel>> getConnectionRequestsStream(String currentUserId) {
    final incomingStream = _firestore
        .collection('connection_requests')
        .where('receiverId', isEqualTo: currentUserId)
        .snapshots();

    final outgoingStream = _firestore
        .collection('connection_requests')
        .where('senderId', isEqualTo: currentUserId)
        .snapshots();

    return combineLatest2<QuerySnapshot<Map<String, dynamic>>, QuerySnapshot<Map<String, dynamic>>, List<MessageRequestModel>>(
      incomingStream,
      outgoingStream,
      (incomingSnap, outgoingSnap) {
        final incoming = incomingSnap.docs.map((d) => MessageRequestModel.fromMap(d.data(), d.id)).toList();
        final outgoing = outgoingSnap.docs.map((d) => MessageRequestModel.fromMap(d.data(), d.id)).toList();

        final Map<String, MessageRequestModel> requestMap = {};
        for (final req in incoming) {
          requestMap[req.id] = req;
        }
        for (final req in outgoing) {
          requestMap[req.id] = req;
        }

        final combined = requestMap.values.toList();
        combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return combined;
      },
    );
  }

  /// Accepts a connection request: creates a match, writes the first chat message, and deletes the request.
  Future<void> acceptConnectionRequest(MessageRequestModel request) async {
    final matchId = request.senderId.compareTo(request.receiverId) < 0
        ? '${request.senderId}_${request.receiverId}'
        : '${request.receiverId}_${request.senderId}';

    // 1. Create match first and await its completion
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

  /// Declines a connection request: deletes the request.
  Future<void> declineConnectionRequest(String requestId) async {
    await _firestore.collection('connection_requests').doc(requestId).delete();
  }

  /// Unlikes a user.
  Future<void> unlikeUser({required String currentUserId, required String targetUserId}) async {
    final likeRef = _firestore.collection('likes').doc('${currentUserId}_$targetUserId');
    final likeDoc = await likeRef.get();
    if (likeDoc.exists) {
      await likeRef.delete();

      // Decrement target user's likesCount
      await _firestore.collection('users').doc(targetUserId).update({
        'likesCount': FieldValue.increment(-1),
      });
    }

    // Also delete the match if it exists
    final matchId = currentUserId.compareTo(targetUserId) < 0
        ? '${currentUserId}_$targetUserId'
        : '${targetUserId}_$currentUserId';
    final matchDoc = await _firestore.collection('matches').doc(matchId).get();
    if (matchDoc.exists) {
      await matchDoc.reference.delete();
    }
  }

  /// Streams received likes for a user.
  Stream<List<InteractionModel>> getReceivedLikesStream(String userId) {
    return _firestore
        .collection('likes')
        .where('receiverId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => InteractionModel.fromMap(d.data(), d.id)).toList());
  }

  /// Streams sent likes by a user.
  Stream<List<InteractionModel>> getSentLikesStream(String userId) {
    return _firestore
        .collection('likes')
        .where('senderId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => InteractionModel.fromMap(d.data(), d.id)).toList());
  }

  /// Streams the total number of matches (connects) for any user.
  Stream<int> userConnectsCountStream(String userId) {
    return _firestore
        .collection('matches')
        .where('userIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.length);
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

@riverpod
Stream<int> userConnectsCount(UserConnectsCountRef ref, {required String userId}) {
  final repo = ref.watch(interactionRepositoryProvider);
  return repo.userConnectsCountStream(userId);
}

/// Helper function to combine two streams cleanly without race conditions or missing updates.
Stream<R> combineLatest2<T1, T2, R>(
  Stream<T1> stream1,
  Stream<T2> stream2,
  R Function(T1 a, T2 b) combiner,
) {
  late StreamController<R> controller;
  T1? last1;
  T2? last2;
  bool has1 = false;
  bool has2 = false;

  StreamSubscription<T1>? sub1;
  StreamSubscription<T2>? sub2;

  controller = StreamController<R>(
    onListen: () {
      sub1 = stream1.listen(
        (val1) {
          last1 = val1;
          has1 = true;
          if (has2 && !controller.isClosed) {
            controller.add(combiner(last1 as T1, last2 as T2));
          }
        },
        onError: (err, stack) {
          if (!controller.isClosed) controller.addError(err, stack);
        },
      );

      sub2 = stream2.listen(
        (val2) {
          last2 = val2;
          has2 = true;
          if (has1 && !controller.isClosed) {
            controller.add(combiner(last1 as T1, last2 as T2));
          }
        },
        onError: (err, stack) {
          if (!controller.isClosed) controller.addError(err, stack);
        },
      );
    },
    onCancel: () async {
      await sub1?.cancel();
      await sub2?.cancel();
    },
  );

  return controller.stream;
}
