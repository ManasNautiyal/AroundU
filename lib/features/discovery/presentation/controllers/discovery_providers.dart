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



@riverpod
class SelectedVibeFilter extends _$SelectedVibeFilter {
  @override
  String? build() => null;

  void selectFilter(String? filter) {
    state = filter;
  }
}



