import 'package:flutter_riverpod/legacy.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/features/tahajud/models/tahajud.dart';
import 'package:test_flutter/features/tahajud/services/tahajud_service.dart';
import 'package:test_flutter/features/tahajud/states/tahajud_state.dart';

class TahajudNotifier extends StateNotifier<TahajudState> {
  TahajudNotifier() : super(TahajudState.initial()) {
    // Load data on initialization
    _initializeData();
  }

  /// Initialize data on app start
  Future<void> _initializeData() async {
    final now = DateTime.now();
    final monthFormat = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    await Future.wait([
      loadRiwayatTahajud(monthFormat),
      loadStatistikTahajud(monthFormat),
    ]);
  }

  /// Load statistik tahajud
  Future<void> loadStatistikTahajud(String monthFormat) async {
    try {
      final response = await TahajudService.getStatistikTahajudChallenge(
        month: monthFormat,
      );

      final statistikData = response['data'] as Map<String, dynamic>;
      final statistik = StatistikTahajud.fromJson(statistikData);

      state = state.copyWith(statistikTahajud: statistik);

      logger.fine(
        'Statistik tahajud loaded successfully for month: $monthFormat',
      );
    } catch (e) {
      logger.severe('Error loading statistik tahajud: $e');
      // Don't fail the entire initialization if statistik fails
    }
  }

  /// Load riwayat tahajud per bulan
  Future<void> loadRiwayatTahajud(String monthFormat) async {
    state = state.copyWith(
      status: TahajudStatus.loading,
      currentMonth: monthFormat,
    );
    try {
      // Use month format directly (YYYY-MM)
      final response = await TahajudService.getRiwayatTahajudChallenge(
        month: monthFormat,
      );

      final riwayatData = response['data'] as List<dynamic>;
      final riwayatList = riwayatData
          .map((item) => RiwayatTahajud.fromJson(item as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        status: TahajudStatus.loaded,
        riwayatTahajud: riwayatList,
        currentMonth: monthFormat,
      );

      logger.fine(
        'Riwayat tahajud loaded successfully for month: $monthFormat',
      );
    } catch (e) {
      logger.severe('Error loading riwayat tahajud: $e');
      state = state.copyWith(status: TahajudStatus.error, error: e.toString());
    }
  }

  /// Add tahajud challenge
  Future<void> addTahajud({
    required DateTime waktuSholat,
    required int jumlahRakaat,
    required DateTime waktuMakanTerakhir,
    required DateTime waktuTidur,
    required String keterangan,
  }) async {
    state = state.copyWith(status: TahajudStatus.loading);
    try {
      final response = await TahajudService.addTahajud(
        waktuSholat: waktuSholat,
        jumlahRakaat: jumlahRakaat,
        waktuMakanTerakhir: waktuMakanTerakhir,
        waktuTidur: waktuTidur,
        keterangan: keterangan,
      );

      logger.fine('Tahajud added successfully');

      // Reload data after adding
      state = state.copyWith(
        status: TahajudStatus.success,
        message: response['message'],
      );

      await Future.delayed(const Duration(milliseconds: 500));
      await loadRiwayatTahajud(state.currentMonth);
    } catch (e) {
      logger.severe('Error adding tahajud: $e');
      state = state.copyWith(
        status: TahajudStatus.error,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Get detail tahajud
  Future<Tahajud?> getDetailTahajud(String tahajudId) async {
    try {
      final response = await TahajudService.getDetailTahajudChallenge(
        tahajudId: tahajudId,
      );

      final tahajud = Tahajud.fromJson(
        response['data'] as Map<String, dynamic>,
      );
      logger.fine('Tahajud detail retrieved successfully');
      return tahajud;
    } catch (e) {
      logger.severe('Error getting tahajud detail: $e');
      return null;
    }
  }

  /// Delete tahajud challenge
  Future<void> deleteTahajud(String tahajudId) async {
    state = state.copyWith(status: TahajudStatus.loading);
    try {
      final response = await TahajudService.deleteTahajudChallenge(
        tahajudId: tahajudId,
      );

      state = state.copyWith(
        status: TahajudStatus.success,
        message: response['message'],
      );

      logger.fine('Tahajud deleted successfully');

      // Reload data after deleting
      await Future.delayed(const Duration(milliseconds: 500));
      await loadRiwayatTahajud(state.currentMonth);
    } catch (e) {
      logger.severe('Error deleting tahajud: $e');
      state = state.copyWith(status: TahajudStatus.error, error: e.toString());
    }
  }

  /// Change month
  Future<void> changeMonth(String monthFormat) async {
    await Future.wait([
      loadRiwayatTahajud(monthFormat),
      loadStatistikTahajud(monthFormat),
    ]);
  }

  /// Clear message
  void clearMessage() {
    state = state.copyWith(message: '', error: '');
  }

  /// Reset status
  void resetStatus() {
    state = state.copyWith(status: TahajudStatus.loaded);
  }
}

final tahajudProvider = StateNotifierProvider<TahajudNotifier, TahajudState>((
  ref,
) {
  return TahajudNotifier();
});
