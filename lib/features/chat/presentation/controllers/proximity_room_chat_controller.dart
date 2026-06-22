import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';

part 'proximity_room_chat_controller.g.dart';

@riverpod
Stream<List<MessageModel>> proximityRoomMessages(ProximityRoomMessagesRef ref, {required String roomId}) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getProximityRoomMessagesStream(roomId);
}
