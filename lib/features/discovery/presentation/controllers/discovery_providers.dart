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
  @override
  bool build() => true;

  void setInRoom(bool value) => state = value;
  void toggle() => state = !state;
}

