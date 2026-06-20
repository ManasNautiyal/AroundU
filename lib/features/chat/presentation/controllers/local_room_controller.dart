import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/message_model.dart';
import '../../../discovery/presentation/controllers/discovery_providers.dart';

part 'local_room_controller.g.dart';

@riverpod
class LocalRoomMessages extends _$LocalRoomMessages {
  @override
  List<MessageModel> build() {
    final isInRoom = ref.watch(inLocalRoomProvider);
    if (!isInRoom) {
      return [];
    }
    return [
      MessageModel(
        id: 'lr_1',
        senderId: 'mock_1', // Sophia
        text: "Hey everyone! The pumpkin spice latte here is amazing today. ☕",
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      MessageModel(
        id: 'lr_2',
        senderId: 'mock_2', // Marcus
        text: "Just ordered a cold brew. Anyone up for a quick chat?",
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      MessageModel(
        id: 'lr_3',
        senderId: 'mock_3', // Aria
        text: "I am sketching in the corner, stop by if you want to see!",
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];
  }

  void sendMessage(String text) {
    if (!ref.read(inLocalRoomProvider)) return;

    final newMessage = MessageModel(
      id: 'lr_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      text: text,
      timestamp: DateTime.now(),
    );
    state = [...state, newMessage];
  }

  void clearMessages() {
    state = [];
  }
}
