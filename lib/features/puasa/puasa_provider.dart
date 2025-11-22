import 'package:flutter_riverpod/legacy.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/features/puasa/models/progres_puasa.dart';
import 'package:test_flutter/features/puasa/models/puasa.dart';
import 'package:test_flutter/features/puasa/puasa_state.dart';
import 'package:test_flutter/features/puasa/services/puasa_service.dart';

class PuasaNotifier extends StateNotifier<PuasaState> {
  PuasaNotifier() : super(PuasaState.initial());

  // Init
  Future<void> init() async {
    final tahunHijriah = _getCurrentTahunHijriah();
    await fetchRiwayatPuasaWajib(tahunHijriah: tahunHijriah);
    await fetchPuasaSunnahList();
  }

  /// Mendapatkan tahun hijriah saat ini sebagai default
  String _getCurrentTahunHijriah() {
    // Implementasi sederhana, bisa disesuaikan dengan logic lebih kompleks
    // Untuk saat ini return current year
    return DateTime.now().year.toString();
  }

  // Fetch Puasa Sunnah List
  Future<void> fetchPuasaSunnahList() async {
    try {
      state = state.copyWith(status: PuasaStatus.loading, message: null);
      final result = await PuasaService.getAllPuasaSunnah();
      final status = result['status'] as bool? ?? false;
      final message = result['message'] as String? ?? 'Unknown error';

      if (status) {
        final puasaSunnahList = result['data'] as List<PuasaSunnah>? ?? [];
        state = state.copyWith(
          status: PuasaStatus.loaded,
          puasaSunnahList: puasaSunnahList,
          message: message,
        );
      } else {
        state = state.copyWith(status: PuasaStatus.error, message: message);
      }
    } catch (e) {
      logger.severe('Error fetching puasa sunnah list: $e');
      state = state.copyWith(
        status: PuasaStatus.error,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Fetch Riwayat Puasa Wajib
  Future<void> fetchRiwayatPuasaWajib({required String tahunHijriah}) async {
    try {
      state = state.copyWith(status: PuasaStatus.loading, message: null);
      final result = await PuasaService.getRiwayatPuasaWajib(
        tahunHijriah: tahunHijriah,
      );
      final status = result['status'] as bool? ?? false;
      final message = result['message'] as String? ?? 'Unknown error';
      final data = result['data'] as List<dynamic>? ?? [];

      if (status) {
        // Parse list data to RiwayatProgresPuasaSunnah
        final riwayatList = data
            .map(
              (e) =>
                  RiwayatProgresPuasaWajib.fromJson(e as Map<String, dynamic>),
            )
            .toList();
        state = state.copyWith(
          status: PuasaStatus.loaded,
          riwayatPuasaWajib: riwayatList,
          message: message,
        );
      } else {
        state = state.copyWith(status: PuasaStatus.error, message: message);
      }
    } catch (e) {
      logger.severe('Error fetching riwayat puasa wajib: $e');
      state = state.copyWith(
        status: PuasaStatus.error,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Add Progres Puasa Wajib
  Future<void> addProgresPuasaWajib({
    required String tanggalRamadhan,
    required String tahunHijriah,
  }) async {
    try {
      state = state.copyWith(status: PuasaStatus.loading, message: null);
      final result = await PuasaService.addProgresPuasaWajib(
        tanggalRamadhan: tanggalRamadhan,
      );
      final status = result['status'] as bool? ?? false;
      final message = result['message'] as String? ?? 'Unknown error';
      if (status) {
        state = state.copyWith(status: PuasaStatus.success, message: message);
      } else {
        state = state.copyWith(status: PuasaStatus.error, message: message);
      }
      await fetchRiwayatPuasaWajib(tahunHijriah: tahunHijriah);
    } catch (e) {
      logger.severe('Error adding progres puasa wajib: $e');
      state = state.copyWith(
        status: PuasaStatus.error,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Delete Progres Puasa Wajib
  Future<void> deleteProgresPuasaWajib({
    required String id,
    required String tahunHijriah,
  }) async {
    try {
      state = state.copyWith(status: PuasaStatus.loading, message: null);
      final result = await PuasaService.deleteProgresPuasaWajib(id: id);
      final status = result['status'] as bool? ?? false;
      final message = result['message'] as String? ?? 'Unknown error';

      if (status) {
        state = state.copyWith(status: PuasaStatus.success, message: message);
      } else {
        state = state.copyWith(status: PuasaStatus.error, message: message);
      }
      await fetchRiwayatPuasaWajib(tahunHijriah: tahunHijriah);
    } catch (e) {
      logger.severe('Error deleting progres puasa wajib: $e');
      state = state.copyWith(
        status: PuasaStatus.error,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Fetch Riwayat Puasa Sunnah
  Future<void> fetchRiwayatPuasaSunnah({required String jenis}) async {
    try {
      state = state.copyWith(status: PuasaStatus.loading, message: null);

      final result = await PuasaService.getRiwayatPuasaSunnah(jenis: jenis);

      final status = result['status'] as bool? ?? false;
      final message = result['message'] as String? ?? 'Unknown error';
      final data = result['data'] as List<dynamic>? ?? [];

      if (status) {
        // Parse list data to RiwayatProgresPuasaSunnah
        final riwayatList = data
            .map(
              (e) =>
                  RiwayatProgresPuasaSunnah.fromJson(e as Map<String, dynamic>),
            )
            .toList();

        state = state.copyWith(
          status: PuasaStatus.loaded,
          riwayatPuasaSunnah: riwayatList,
          message: message,
        );
      } else {
        logger.warning('Status false, setting error state');
        state = state.copyWith(status: PuasaStatus.error, message: message);
      }
    } catch (e, stackTrace) {
      logger.severe('=== PROVIDER ERROR: fetchRiwayatPuasaSunnah ===');
      logger.severe('Error: $e');
      logger.severe('StackTrace: $stackTrace');

      state = state.copyWith(
        status: PuasaStatus.error,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Add Progres Puasa Sunnah
  Future<void> addProgresPuasaSunnah({required String jenis}) async {
    try {
      state = state.copyWith(status: PuasaStatus.loading, message: null);
      final result = await PuasaService.addProgresPuasaSunnah(jenis: jenis);
      final status = result['status'] as bool? ?? false;
      final message = result['message'] as String? ?? 'Unknown error';

      if (status) {
        state = state.copyWith(status: PuasaStatus.success, message: message);
      } else {
        state = state.copyWith(status: PuasaStatus.error, message: message);
      }
      await fetchRiwayatPuasaSunnah(jenis: jenis);
    } catch (e) {
      logger.severe('Error adding progres puasa sunnah: $e');
      state = state.copyWith(
        status: PuasaStatus.error,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Delete Progres Puasa Sunnah
  Future<void> deleteProgresPuasaSunnah({
    required String id,
    required String jenis,
  }) async {
    try {
      state = state.copyWith(status: PuasaStatus.loading, message: null);
      final result = await PuasaService.deleteProgresPuasaSunnah(id: id);
      final status = result['status'] as bool? ?? false;
      final message = result['message'] as String? ?? 'Unknown error';

      if (status) {
        state = state.copyWith(status: PuasaStatus.success, message: message);
      } else {
        state = state.copyWith(status: PuasaStatus.error, message: message);
      }
      await fetchRiwayatPuasaSunnah(jenis: jenis);
    } catch (e) {
      logger.severe('Error deleting progres puasa sunnah: $e');
      state = state.copyWith(
        status: PuasaStatus.error,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final puasaProvider = StateNotifierProvider<PuasaNotifier, PuasaState>(
  (ref) => PuasaNotifier(),
);
