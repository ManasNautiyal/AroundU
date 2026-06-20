import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/nearby_user.dart';

part 'discovery_providers.g.dart';

@riverpod
class GhostModeController extends _$GhostModeController {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

@riverpod
class MockDiscoveryUsersController extends _$MockDiscoveryUsersController {
  @override
  List<NearbyUser> build() {
    return _initialMockUsers;
  }

  void clearUsers() {
    state = [];
  }

  void resetUsers() {
    state = _initialMockUsers;
  }

  static final List<NearbyUser> _initialMockUsers = [
    NearbyUser(
      user: UserModel(
        uid: 'mock_1',
        name: 'Sophia',
        bio: '☕ Coffee lover & bookworm. Always down to explore new coffee shops. Let\'s grab a flat white!',
        profilePictures: [
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop',
        ],
        vibeTags: ['☕ Coffee', '📚 Reading', '🌲 Nature'],
        isGhostMode: false,
        lastActive: DateTime.now(),
      ),
      distanceInMeters: 14.0,
    ),
    NearbyUser(
      user: UserModel(
        uid: 'mock_2',
        name: 'Marcus',
        bio: '🏋️ Gym enthusiast & fitness trainer. Love hiking, rock climbing, and good food. Let\'s crush a workout together!',
        profilePictures: [
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500&auto=format&fit=crop',
        ],
        vibeTags: ['🏋️ Gym', '⚽ Sports', '🍕 Foodie'],
        isGhostMode: false,
        lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      distanceInMeters: 45.0,
    ),
    NearbyUser(
      user: UserModel(
        uid: 'mock_3',
        name: 'Aria',
        bio: '🎨 Art director & film nerd. Let\'s talk about cinematography, design, or classic rock music.',
        profilePictures: [
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=500&auto=format&fit=crop',
        ],
        vibeTags: ['🎨 Art', '🎬 Movies', '🎵 Music'],
        isGhostMode: false,
        lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      distanceInMeters: 72.0,
    ),
    NearbyUser(
      user: UserModel(
        uid: 'mock_4',
        name: 'Leo',
        bio: '🎮 Indie game dev & board game collector. Love cooking, vinyl records, and late night walks. Challenge me in chess!',
        profilePictures: [
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=500&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1506863530036-1efeddceb993?w=500&auto=format&fit=crop',
        ],
        vibeTags: ['🎮 Gaming', '🎵 Music', '🍕 Foodie'],
        isGhostMode: false,
        lastActive: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      distanceInMeters: 91.0,
    ),
  ];
}

class BeaconInfo {
  final String emoji;
  final String message;
  const BeaconInfo({required this.emoji, required this.message});
}

@riverpod
class UserBeacons extends _$UserBeacons {
  @override
  Map<String, BeaconInfo> build() {
    return {
      'mock_1': const BeaconInfo(emoji: '☕', message: 'Coding & Coffee'),
      'mock_3': const BeaconInfo(emoji: '🎨', message: 'Sketching life'),
    };
  }

  void setBeacon(String userId, String emoji, String message) {
    state = {
      ...state,
      userId: BeaconInfo(emoji: emoji, message: message),
    };
  }

  void clearBeacon(String userId) {
    final newState = Map<String, BeaconInfo>.from(state);
    newState.remove(userId);
    state = newState;
  }
}

@riverpod
class SelectedVibeFilter extends _$SelectedVibeFilter {
  @override
  String? build() => null;

  void selectFilter(String? filter) {
    state = filter;
  }
}

@riverpod
class InLocalRoom extends _$InLocalRoom {
  @override
  bool build() => true;

  void setInRoom(bool value) => state = value;
  void toggle() => state = !state;
}

