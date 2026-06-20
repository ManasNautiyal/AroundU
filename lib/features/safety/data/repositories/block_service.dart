import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/block_model.dart';

part 'block_service.g.dart';

class BlockService {
  final FirebaseFirestore _firestore;

  // Local Mock Databases (used if Firebase is not initialized)
  final List<BlockModel> _mockBlocks = [];
  final List<Map<String, dynamic>> _mockReports = [];

  // StreamController to update local mock list of blocked IDs
  final _blockedUsersController = StreamController<List<String>>.broadcast();

  BlockService(this._firestore);

  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Blocks a user.
  Future<void> blockUser({required String blockerId, required String blockedId}) async {
    if (_isFirebaseInitialized) {
      final blockId = '${blockerId}_$blockedId';
      await _firestore.collection('blocks').doc(blockId).set({
        'blockerId': blockerId,
        'blockedId': blockedId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      // Mock local write
      if (!_mockBlocks.any((b) => b.blockerId == blockerId && b.blockedId == blockedId)) {
        _mockBlocks.add(BlockModel(
          id: 'block_${blockerId}_$blockedId',
          blockerId: blockerId,
          blockedId: blockedId,
          timestamp: DateTime.now(),
        ));
        
        final list = _mockBlocks
            .where((b) => b.blockerId == blockerId || b.blockedId == blockerId)
            .map((b) => b.blockerId == blockerId ? b.blockedId : b.blockerId)
            .toList();
        _blockedUsersController.add(list);
      }
    }
  }

  /// Reports and automatically blocks a user.
  Future<void> reportUser({
    required String reporterId,
    required String targetUserId,
    required String reason,
  }) async {
    if (_isFirebaseInitialized) {
      await _firestore.collection('reports').add({
        'reporterId': reporterId,
        'reportedId': targetUserId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      _mockReports.add({
        'reporterId': reporterId,
        'reportedId': targetUserId,
        'reason': reason,
        'timestamp': DateTime.now(),
      });
    }

    // Automatically block the reported user for safety
    await blockUser(blockerId: reporterId, blockedId: targetUserId);
  }

  /// Streams the list of user IDs that the current user has blocked or has been blocked by.
  Stream<List<String>> getBlockedUsersStream(String blockerId) {
    if (_isFirebaseInitialized) {
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
    } else {
      final initialList = _mockBlocks
          .where((b) => b.blockerId == blockerId || b.blockedId == blockerId)
          .map((b) => b.blockerId == blockerId ? b.blockedId : b.blockerId)
          .toList();
      Timer.run(() => _blockedUsersController.add(initialList));
      return _blockedUsersController.stream;
    }
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
