import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/proximity_room_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../../core/services/location_service.dart';

import '../../../auth/data/repositories/auth_repository.dart';

part 'proximity_rooms_controller.g.dart';

@riverpod
Stream<List<ProximityRoomModel>> proximityRooms(ProximityRoomsRef ref) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  final positionAsync = ref.watch(userPositionProvider);
  final currentUserId = ref.watch(authRepositoryProvider).currentUser?.uid;

  return positionAsync.when(
    data: (position) {
      return chatRepo.getNearbyProximityRooms(
        latitude: position.latitude,
        longitude: position.longitude,
        currentUserId: currentUserId,
      );
    },
    error: (err, stack) => Stream.value([]),
    loading: () => Stream.value([]),
  );
}
