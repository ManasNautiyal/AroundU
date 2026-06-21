import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/nearby_user.dart';
import '../../data/repositories/user_repository.dart';

part 'user_providers.g.dart';

@riverpod
Future<UserModel?> userProfile(UserProfileRef ref, String uid) {
  if (uid == 'me') {
    return ref.watch(currentUserModelProvider.future);
  }
  return ref.watch(userRepositoryProvider).getUserProfile(uid);
}
