import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/profile_service.dart';

// Profile State
class ProfileState {
  final User? user;
  final bool isLoading;
  final String? error;

  ProfileState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Profile Notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileService _profileService = ProfileService();

  ProfileNotifier() : super(ProfileState());

  // Load user profile
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _profileService.getProfile();
      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? businessName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedUser = await _profileService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        businessName: businessName,
      );

      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Upload profile image
  Future<bool> uploadProfileImage(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final imageUrl = await _profileService.uploadProfileImage(filePath);

      if (state.user != null) {
        state = state.copyWith(
          user: User(
            id: state.user!.id,
            firstName: state.user!.firstName,
            lastName: state.user!.lastName,
            email: state.user!.email,
            phone: state.user!.phone,
            role: state.user!.role,
            profileImage: imageUrl,
            businessName: state.user!.businessName,
            addresses: state.user!.addresses,
            wishlist: state.user!.wishlist,
          ),
          isLoading: false,
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _profileService.deleteAccount();
      state = ProfileState(); // Reset state
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

// Provider
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
