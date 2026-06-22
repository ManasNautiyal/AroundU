import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/connections/data/repositories/interaction_repository.dart';
import '../../features/discovery/data/repositories/discovery_repository.dart';
import '../../features/discovery/presentation/controllers/discovery_providers.dart';
import 'location_service.dart';
import 'notification_service.dart';
import '../../features/connections/data/models/interaction_model.dart';
import '../../features/connections/data/models/message_request_model.dart';

/// Global provider for tracking user location in Firestore dynamically.
final locationTrackerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<Position>>(userPositionProvider, (previous, next) async {
    final position = next.valueOrNull;
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid;
    final isGhostMode = ref.read(ghostModeControllerProvider);

    if (position != null && currentUserId != null && !isGhostMode) {
      try {
        await ref.read(discoveryRepositoryProvider).updateUserLocation(
          uid: currentUserId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (_) {
        // Fail silently in background
      }
    }
  });
});

/// Global provider for observing incoming interactions and triggering local notifications.
final interactionObserverProvider = Provider.family<void, String>((ref, uid) {
  final startTime = DateTime.now();

  // 1. Listen to incoming Likes
  ref.listen<AsyncValue<List<InteractionModel>>>(receivedLikesStreamProvider(currentUserId: uid), (previous, next) {
    final likes = next.valueOrNull ?? [];
    for (final like in likes) {
      if (like.timestamp.isAfter(startTime)) {
        NotificationService.showNotification(
          id: like.id.hashCode,
          title: 'New Like! ❤️',
          body: 'Someone liked your profile.',
        );
      }
    }
  });

  // 2. Listen to incoming Waves
  ref.listen<AsyncValue<List<InteractionModel>>>(incomingWavesStreamProvider(currentUserId: uid), (previous, next) {
    final waves = next.valueOrNull ?? [];
    for (final wave in waves) {
      if (wave.timestamp.isAfter(startTime)) {
        NotificationService.showNotification(
          id: wave.id.hashCode,
          title: 'New Wave! 👋',
          body: 'Someone waved at you.',
        );
      }
    }
  });

  // 3. Listen to incoming Connection Requests
  ref.listen<AsyncValue<List<MessageRequestModel>>>(connectionRequestsStreamProvider(currentUserId: uid), (previous, next) {
    final requests = next.valueOrNull ?? [];
    for (final request in requests) {
      if (request.timestamp.isAfter(startTime)) {
        NotificationService.showNotification(
          id: request.id.hashCode,
          title: 'Connection Request! 📩',
          body: 'You received a new connection request: "${request.introMessage}"',
        );
      }
    }
  });
});
