import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../discovery/data/repositories/user_repository.dart';

part 'onboarding_providers.g.dart';

/// State representation for the multi-step onboarding profile setup.
class OnboardingState {
  final int currentPage;
  final String name;
  final String bio;
  final List<String?> profilePictures; // Index 0 is primary, 1 and 2 are secondary slots
  final List<String> selectedVibeTags;
  final bool isLoading;

  OnboardingState({
    this.currentPage = 0,
    this.name = '',
    this.bio = '',
    this.profilePictures = const [null, null, null],
    this.selectedVibeTags = const [],
    this.isLoading = false,
  });

  OnboardingState copyWith({
    int? currentPage,
    String? name,
    String? bio,
    List<String?>? profilePictures,
    List<String>? selectedVibeTags,
    bool? isLoading,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profilePictures: profilePictures ?? this.profilePictures,
      selectedVibeTags: selectedVibeTags ?? this.selectedVibeTags,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Helper to check if step 1 (Basic Info) is valid and complete.
  bool get isBasicInfoValid => name.trim().isNotEmpty && bio.trim().isNotEmpty;

  /// Helper to check if step 2 (Pictures) has at least the primary picture uploaded.
  bool get isPicturesValid => profilePictures[0] != null;

  /// Helper to check if step 3 (Vibe Tags) has at least 1 and at most 5 tags selected.
  bool get isVibeTagsValid => selectedVibeTags.isNotEmpty && selectedVibeTags.length <= 5;
}

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingState build() {
    return OnboardingState();
  }

  void setPage(int page) {
    if (page >= 0 && page <= 2) {
      state = state.copyWith(currentPage: page);
    }
  }

  void nextPage() {
    if (state.currentPage < 2) {
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

  void toggleVibeTag(String tag) {
    final currentTags = List<String>.from(state.selectedVibeTags);
    if (currentTags.contains(tag)) {
      currentTags.remove(tag);
    } else {
      if (currentTags.length < 5) {
        currentTags.add(tag);
      }
    }
    state = state.copyWith(selectedVibeTags: currentTags);
  }

  void updatePicture(int index, String? path) {
    final currentPics = List<String?>.from(state.profilePictures);
    if (index >= 0 && index < 3) {
      currentPics[index] = path;
      state = state.copyWith(profilePictures: currentPics);
    }
  }

  /// Real Firebase profile completion upload.
  Future<bool> finishProfile() async {
    if (!state.isBasicInfoValid || !state.isPicturesValid || !state.isVibeTagsValid) {
      return false;
    }

    state = state.copyWith(isLoading: true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);
      final uid = authRepo.currentUser?.uid;
      
      if (uid == null) {
        throw Exception('No authenticated user found');
      }

      // Convert local picture paths if any, or mock profiles for pictures since we are focusing on profile data wiring
      final nonNullPics = state.profilePictures.whereType<String>().toList();

      await userRepo.createUserProfile(
        uid: uid,
        name: state.name.trim(),
        bio: state.bio.trim(),
        vibeTags: state.selectedVibeTags,
        profilePictures: nonNullPics.isNotEmpty ? nonNullPics : const [
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500' // Fallback visual setup profile picture
        ],
      );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
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

