import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/core/utils/storage_helper.dart';
import 'package:test_flutter/features/profile/services/profile_service.dart';
import 'package:test_flutter/features/profile/states/profile_state.dart';

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(ProfileState.initial());

  /// Memuat data user dari local storage saat aplikasi dimulai.
  Future<void> loadUser() async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      // StorageHelper.getUser() sekarang kita asumsikan mengembalikan User
      final user = await StorageHelper.getUser();
      if (user != null) {
        state = state.copyWith(status: ProfileStatus.loaded, profile: user);
      }

      logger.fine('User loaded from storage: $user');
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        message: e.toString(),
      );
    }
  }

  /// Memperbarui profil pengguna (nama, email, telepon).
  Future<void> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final response = await ProfileService.updateProfile(name, email, phone);
      final data = response['data'];
      final updatedUser = data['user'];

      // Simpan user yang sudah diperbarui ke local storage
      await StorageHelper.saveUser(updatedUser as Map<String, dynamic>);

      state = state.copyWith(
        status: ProfileStatus.success,
        profile: updatedUser,
        message: response['message'],
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        message: e.toString(),
      );
    }
  }

  /// Memperbarui password pengguna.
  Future<void> editPassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final response = await ProfileService.updatePassword(
        currentPassword,
        newPassword,
        confirmPassword,
      );

      state = state.copyWith(
        status: ProfileStatus.success,
        message: response['message'],
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        message: e.toString(),
      );
    }
  }

  // Memperbarui avatar pengguna.
  Future<void> updateAvatar({required XFile avatar}) async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final response = await ProfileService.updateAvatar(avatar: avatar);
      final data = response['data'];
      final updatedUser = data['user'];

      // Simpan user yang sudah diperbarui ke local storage
      await StorageHelper.saveUser(updatedUser as Map<String, dynamic>);

      state = state.copyWith(
        status: ProfileStatus.success,
        profile: updatedUser,
        message: response['message'],
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        message: e.toString(),
      );
    }
  }

  // Delete avatar pengguna.
  Future<void> deleteAvatar() async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final response = await ProfileService.deleteAvatar();
      final data = response['data'];
      final updatedUser = data['user'];

      // Simpan user yang sudah diperbarui ke local storage
      await StorageHelper.saveUser(updatedUser as Map<String, dynamic>);

      state = state.copyWith(
        status: ProfileStatus.success,
        profile: updatedUser,
        message: response['message'],
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        message: e.toString(),
      );
    }
  }

  /// Membersihkan pesan (error/sukses) setelah ditampilkan di UI.
  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  /// Mengembalikan status ke loaded setelah operasi sukses.
  void resetStatus() {
    if (state.status == ProfileStatus.success) {
      state = state.copyWith(status: ProfileStatus.loaded);
    }
  }
}

// Provider that can be used throughout the app
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier();
});
