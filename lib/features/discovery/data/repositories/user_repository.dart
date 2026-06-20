import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/nearby_user.dart';

part 'user_repository.g.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String bio,
    required List<String> vibeTags,
    List<String> profilePictures = const [],
  }) async {
    final userModel = UserModel(
      uid: uid,
      name: name,
      bio: bio,
      profilePictures: profilePictures,
      vibeTags: vibeTags,
      isGhostMode: false,
      lastActive: DateTime.now(),
    );
    await _firestore.collection('users').doc(uid).set(userModel.toMap());
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }
}

@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepository(FirebaseFirestore.instance);
}
