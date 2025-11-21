import 'package:flutter_riverpod/legacy.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/features/profile/models/anak.dart';
import 'package:test_flutter/features/profile/models/relasi_orang_tua_anak.dart';
import 'package:test_flutter/features/profile/services/family_service.dart';
import 'package:test_flutter/features/profile/states/family_state.dart';

class FamilyNotifier extends StateNotifier<FamilyState> {
  FamilyNotifier() : super(FamilyState.initial());

  /// Load data anak aktif dan pengajuan anak dari API
  Future<void> loadFamilyData() async {
    state = state.copyWith(status: FamilyStatus.loading);
    try {
      // Load anak aktif
      final anakAktifResponse = await FamilyService.getDaftarAnakAktif();
      final anakAktifData = anakAktifResponse['data'] as List<dynamic>;
      final anakAktifList = anakAktifData
          .map((item) => Anak.fromJson(item))
          .toList();

      // Load pengajuan anak
      final pengajuanResponse = await FamilyService.getDaftarPengajuanAnak();
      final pengajuanData = pengajuanResponse['data'] as List<dynamic>;
      final pengajuanList = pengajuanData
          .map((item) => RelasiOrangTuaAnak.fromJson(item))
          .toList();

      state = state.copyWith(
        status: FamilyStatus.loaded,
        anakAktif: anakAktifList,
        pengajuanAnak: pengajuanList,
      );

      logger.fine('Family data loaded successfully');
    } catch (e) {
      logger.severe('Error loading family data: $e');
      state = state.copyWith(status: FamilyStatus.error, message: e.toString());
    }
  }

  /// Pengajuan anak baru
  Future<void> pengajuanAnak({required String emailAnak}) async {
    state = state.copyWith(status: FamilyStatus.loading);
    try {
      final response = await FamilyService.pengajuanAnak(emailAnak: emailAnak);
      final newPengajuan = response['data'] as Map<String, dynamic>;

      // Tambah pengajuan ke list
      final updatedPengajuan = [
        ...state.pengajuanAnak,
        RelasiOrangTuaAnak.fromJson(newPengajuan),
      ];

      state = state.copyWith(
        status: FamilyStatus.success,
        pengajuanAnak: updatedPengajuan,
        message: response['message'],
      );

      logger.fine('Pengajuan anak sent successfully');

      // Reload data setelah berhasil
      // await Future.delayed(const Duration(milliseconds: 500));
      await loadFamilyData();
    } catch (e) {
      logger.severe('Error sending pengajuan anak: $e');
      state = state.copyWith(
        status: FamilyStatus.error,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Hapus pengajuan anak
  Future<void> deletePengajuanAnak({required int pengajuanId}) async {
    state = state.copyWith(status: FamilyStatus.loading);
    try {
      final response = await FamilyService.deletePengajuanAnak(
        pengajuanId: pengajuanId,
      );

      // Hapus dari list
      final updatedPengajuan = state.pengajuanAnak
          .where((p) => p.id != pengajuanId)
          .toList();

      state = state.copyWith(
        status: FamilyStatus.success,
        pengajuanAnak: updatedPengajuan,
        message: response['message'],
      );

      logger.fine('Pengajuan anak deleted successfully');

      // Reload data setelah berhasil
      // await Future.delayed(const Duration(milliseconds: 500));
      await loadFamilyData();
    } catch (e) {
      logger.severe('Error deleting pengajuan anak: $e');
      state = state.copyWith(status: FamilyStatus.error, message: e.toString());
    }
  }

  /// Hapus anak aktif
  Future<void> deleteAnak({required int relasiId}) async {
    state = state.copyWith(status: FamilyStatus.loading);
    try {
      final response = await FamilyService.deleteAnak(relasiId: relasiId);

      // Hapus dari list
      final updatedAnakAktif = state.anakAktif
          .where((anak) => anak.id != relasiId)
          .toList();

      state = state.copyWith(
        status: FamilyStatus.success,
        anakAktif: updatedAnakAktif,
        message: response['message'],
      );

      logger.fine('Anak deleted successfully');

      // Reload data setelah berhasil
      // await Future.delayed(const Duration(milliseconds: 500));
      await loadFamilyData();
    } catch (e) {
      logger.severe('Error deleting anak: $e');
      state = state.copyWith(status: FamilyStatus.error, message: e.toString());
    }
  }

  /// Clear message
  void clearMessage() {
    state = state.copyWith(message: '', clearMessage: true);
  }

  /// Reset status
  void resetStatus() {
    state = state.copyWith(status: FamilyStatus.loaded);
  }
}

final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyState>((
  ref,
) {
  return FamilyNotifier();
});
