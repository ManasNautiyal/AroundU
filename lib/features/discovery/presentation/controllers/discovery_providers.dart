import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';
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

@riverpod
class InLocalRoom extends _$InLocalRoom {
  // Downtown Coffee Shop coordinates (mocked location center)
  static const double shopLatitude = 30.3004027;
  static const double shopLongitude = 78.0347056;

  bool? _manualOverride;

  @override
  bool build() {
    final positionAsync = ref.watch(userPositionProvider);
    return positionAsync.maybeWhen(
      data: (position) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          shopLatitude,
          shopLongitude,
        );
        final inRange = distance <= 100.0;
        final finalState = _manualOverride ?? inRange;
        // ignore: avoid_print
        print('DEBUG LOCAL ROOM RANGE CHECK: userLoc=(${position.latitude}, ${position.longitude}), dist=${distance.toStringAsFixed(1)}m, inRange=$inRange, manualOverride=$_manualOverride, finalState=$finalState');
        return finalState;
      },
      orElse: () => _manualOverride ?? true,
    );
  }

  void setInRoom(bool value) {
    _manualOverride = value;
    state = value;
  }

  void toggle() {
    final newValue = !state;
    _manualOverride = newValue;
    state = newValue;
  }
}

