import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/nearby_user.dart';
import '../../../auth/data/repositories/auth_repository.dart';

part 'user_repository.g.dart';

class UserProfileValidationException implements Exception {
  final String message;
  UserProfileValidationException(this.message);

  @override
  String toString() => message;
}

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
    // 1. Sanitize input: Trim whitespace from name and bio
    final sanitizedName = name.trim();
    final sanitizedBio = bio.trim();

    // 2. Validate name
    if (sanitizedName.isEmpty) {
      throw UserProfileValidationException('Name cannot be empty. Please enter your first name.');
    }

    // 3. Validate bio length
    if (sanitizedBio.isEmpty) {
      throw UserProfileValidationException('Bio cannot be empty. Please share a little about yourself.');
    }
    if (sanitizedBio.length > 150) {
      throw UserProfileValidationException('Bio cannot exceed 150 characters.');
    }

    // 4. Validate vibe tags
    if (vibeTags.isEmpty) {
      throw UserProfileValidationException('Please select at least one vibe tag.');
    }
    if (vibeTags.length > 5) {
      throw UserProfileValidationException('You can select a maximum of 5 vibe tags.');
    }

    final userModel = UserModel(
      uid: uid,
      name: sanitizedName,
      bio: sanitizedBio,
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

  /// Updates or deletes the beacon values on the user's Firestore document.
  Future<void> updateBeacon(String uid, String? emoji, String? message) async {
    await _firestore.collection('users').doc(uid).update({
      'beaconEmoji': emoji ?? FieldValue.delete(),
      'beaconMessage': message ?? FieldValue.delete(),
      'lastActive': FieldValue.serverTimestamp(),
    });
  }
}

@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepository(FirebaseFirestore.instance, FirebaseStorage.instance);
}

@riverpod
Future<UserModel?> currentUserModel(CurrentUserModelRef ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final uid = authRepo.currentUser?.uid;
  if (uid == null) return null;
  return ref.watch(userRepositoryProvider).getUserProfile(uid);
}

