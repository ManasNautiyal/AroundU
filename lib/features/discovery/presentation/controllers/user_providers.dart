import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/nearby_user.dart';
import '../../data/repositories/user_repository.dart';

part 'user_providers.g.dart';

@riverpod
Future<UserModel?> userProfile(UserProfileRef ref, String uid) async {
  if (uid == 'me') {
    return ref.watch(currentUserModelProvider.future);
  }
  final user = await ref.watch(userRepositoryProvider).getUserProfile(uid);
  if (user != null) {
    final geopoint = user.location?['geopoint'] as GeoPoint?;
    // ignore: avoid_print
    print('DEBUG USER PROFILE FETCHED: uid=${user.uid}, name=${user.name}, lat=${geopoint?.latitude}, lng=${geopoint?.longitude}, isGhostMode=${user.isGhostMode}');
  }
  return user;
}

