import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/interaction_model.dart';
import '../../data/models/message_request_model.dart';

part 'social_mock_providers.g.dart';

@riverpod
class MockMessageRequests extends _$MockMessageRequests {
  @override
  List<MessageRequestModel> build() {
    return [
      MessageRequestModel(
        id: 'req_1',
        senderId: 'mock_2', // Marcus
        receiverId: 'me',
        introMessage: 'Hey! Saw we both like pizza and gym. Let\'s grab a bite sometime? 🍕💪',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      MessageRequestModel(
        id: 'req_2',
        senderId: 'mock_3', // Aria
        receiverId: 'me',
        introMessage: 'Hey! I noticed you enjoy art and classic movies. Let\'s talk cinema! 🎬🎨',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  void declineRequest(String id) {
    state = state.where((req) => req.id != id).toList();
  }

  void acceptRequest(String id) {
    final request = state.firstWhere((req) => req.id == id);
    state = state.where((req) => req.id != id).toList();
    
    // Add to active connections list
    ref.read(mockActiveConnectionsProvider.notifier).addConnection(
      MatchModel(
        id: 'match_me_${request.senderId}',
        user1Id: 'me',
        user2Id: request.senderId,
        userIds: ['me', request.senderId],
        timestamp: DateTime.now(),
      ),
    );
  }

  void addRequest(MessageRequestModel request) {
    state = [...state, request];
  }
}

@riverpod
class MockActiveConnections extends _$MockActiveConnections {
  @override
  List<MatchModel> build() {
    // Initial active connection (e.g. Sophia)
    return [
      MatchModel(
        id: 'match_me_mock_1', // Sophia
        user1Id: 'me',
        user2Id: 'mock_1',
        userIds: ['me', 'mock_1'],
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  void addConnection(MatchModel match) {
    state = [...state, match];
  }
}
