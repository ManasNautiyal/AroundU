import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/nearby_user.dart';
import '../../data/repositories/user_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';

part 'discovery_providers.g.dart';

@riverpod
class GhostModeController extends _$GhostModeController {
  @override
  bool build() {
    final userModel = ref.watch(currentUserModelProvider).valueOrNull;
    return userModel?.isGhostMode ?? false;
  }

  Future<void> toggle() async {
    final newValue = !state;
    state = newValue;
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid != null) {
      await ref.read(userRepositoryProvider).updateGhostMode(uid, newValue);
    }
  }
}

@riverpod
class MockDiscoveryUsersController extends _$MockDiscoveryUsersController {
  @override
  List<NearbyUser> build() {
    return [];
  }

  void clearUsers() {
    state = [];
  }

  void resetUsers() {
    state = [];
  }
}

/// Holds the user's chosen discovery range in meters (50 – 500 m).
/// Defaults to 500 m so all nearby users are visible initially.
@riverpod
class DiscoveryRangeFilter extends _$DiscoveryRangeFilter {
  @override
  double build() => 500.0;

  void setRange(double meters) {
    state = meters.clamp(50.0, 500.0);
  }
}







