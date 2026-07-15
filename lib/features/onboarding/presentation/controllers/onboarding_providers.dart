import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../discovery/data/repositories/user_repository.dart';
import '../../../../core/widgets/image_helper.dart';

part 'onboarding_providers.g.dart';

/// State representation for the multi-step onboarding profile setup.
class OnboardingState {
  final int currentPage;
  final String name;
  final String bio;
  final List<String?> profilePictures; // Index 0 is primary, 1 and 2 are secondary slots
  final bool isLoading;

  OnboardingState({
    this.currentPage = 0,
    this.name = '',
    this.bio = '',
    this.profilePictures = const [null, null, null],
    this.isLoading = false,
  });

  OnboardingState copyWith({
    int? currentPage,
    String? name,
    String? bio,
    List<String?>? profilePictures,
    bool? isLoading,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profilePictures: profilePictures ?? this.profilePictures,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Helper to check if step 1 (Basic Info) is valid and complete.
  bool get isBasicInfoValid => name.trim().isNotEmpty && bio.trim().isNotEmpty;

  /// Helper to check if step 2 (Pictures) has at least the primary picture uploaded.
  bool get isPicturesValid => profilePictures[0] != null;
}

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingState build() {
    return OnboardingState();
  }

  void setPage(int page) {
    if (page >= 0 && page <= 1) {
      state = state.copyWith(currentPage: page);
    }
  }

  void nextPage() {
    if (state.currentPage < 1) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateBio(String bio) {
    state = state.copyWith(bio: bio.substring(0, bio.length > 150 ? 150 : bio.length));
  }

  void updatePicture(int index, String? path) {
    final currentPics = List<String?>.from(state.profilePictures);
    if (index >= 0 && index < 3) {
      currentPics[index] = path;
      state = state.copyWith(profilePictures: currentPics);
    }
  }

  /// Real Firebase profile completion upload.
  Future<void> finishProfile() async {
    if (!state.isBasicInfoValid || !state.isPicturesValid) {
      throw UserProfileValidationException('Please complete all steps before finishing.');
    }

    state = state.copyWith(isLoading: true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);
      final uid = authRepo.currentUser?.uid;
      
      if (uid == null) {
        throw UserProfileValidationException('No authenticated user found');
      }

      // Compress and convert local files to Base64 data strings to bypass Firebase Storage
      final List<String> uploadedUrls = [];
      for (int i = 0; i < state.profilePictures.length; i++) {
        final path = state.profilePictures[i];
        if (path != null) {
          if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('base64:')) {
            uploadedUrls.add(path);
          } else {
            // Compress image and convert to compact Base64 string
            final base64String = await compressAndEncodeImage(path);
            uploadedUrls.add(base64String);
          }
        }
      }

      await userRepo.createUserProfile(
        uid: uid,
        name: state.name.trim(),
        bio: state.bio.trim(),
        profilePictures: uploadedUrls.isNotEmpty ? uploadedUrls : const [
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500'
        ],
      );

      ref.invalidate(currentUserModelProvider);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

@riverpod
class OnboardingStep extends _$OnboardingStep {
  @override
  int build() => 0;

  void setStep(int step) {
    state = step;
  }
}

