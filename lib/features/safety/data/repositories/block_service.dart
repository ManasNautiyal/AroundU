import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';


part 'block_service.g.dart';

class BlockService {
  final FirebaseFirestore _firestore;

  BlockService(this._firestore);

  /// Blocks a user.
  Future<void> blockUser({required String blockerId, required String blockedId}) async {
    final blockId = '${blockerId}_$blockedId';
    await _firestore.collection('blocks').doc(blockId).set({
      'blockerId': blockerId,
      'blockedId': blockedId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Reports and automatically blocks a user.
  Future<void> reportUser({
    required String reporterId,
    required String targetUserId,
    required String reason,
  }) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'reportedId': targetUserId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Automatically block the reported user for safety
    await blockUser(blockerId: reporterId, blockedId: targetUserId);
  }

  /// Streams the list of user IDs that the current user has blocked or has been blocked by.
  Stream<List<String>> getBlockedUsersStream(String blockerId) {
    return _firestore
        .collection('blocks')
        .where(Filter.or(
          Filter('blockerId', isEqualTo: blockerId),
          Filter('blockedId', isEqualTo: blockerId),
        ))
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              final bId = data['blockerId'] as String;
              final blId = data['blockedId'] as String;
              return bId == blockerId ? blId : bId;
            }).toList());
  }
}

@riverpod
BlockService blockService(BlockServiceRef ref) {
  return BlockService(FirebaseFirestore.instance);
}

@riverpod
Stream<List<String>> blockedUsersStream(BlockedUsersStreamRef ref, {required String currentUserId}) {
  final service = ref.watch(blockServiceProvider);
  return service.getBlockedUsersStream(currentUserId);
}
