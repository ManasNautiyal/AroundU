import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/message_model.dart';
import '../../../discovery/presentation/controllers/discovery_providers.dart';
import '../../../auth/data/repositories/auth_repository.dart';

part 'local_room_controller.g.dart';

@riverpod
class LocalRoomMessages extends _$LocalRoomMessages {
  @override
  List<MessageModel> build() {
    return [];
  }

  void sendMessage(String text) {
    if (!ref.read(inLocalRoomProvider)) return;

    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? 'me';
    final newMessage = MessageModel(
      id: 'lr_${DateTime.now().millisecondsSinceEpoch}',
      senderId: currentUserId,
      text: text,
      timestamp: DateTime.now(),
    );
    state = [...state, newMessage];
  }

  void clearMessages() {
    state = [];
  }
}
