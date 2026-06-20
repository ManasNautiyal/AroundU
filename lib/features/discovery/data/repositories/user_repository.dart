import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/nearby_user.dart';

part 'user_repository.g.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  UserRepository(this._firestore, this._storage);

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

  /// Uploads a profile picture to Firebase Storage and returns its download URL.
  Future<String> uploadProfilePicture({
    required String uid,
    required String localPath,
    required String slot,
  }) async {
    final ref = _storage.ref().child('users').child(uid).child('profile_pics').child('$slot.jpg');
    final file = File(localPath);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}

@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepository(FirebaseFirestore.instance, FirebaseStorage.instance);
}

