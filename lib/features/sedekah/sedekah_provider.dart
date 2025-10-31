import 'package:flutter_riverpod/legacy.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/data/models/sedekah/sedekah.dart';
import 'package:test_flutter/features/sedekah/sedekah_state.dart';
import 'package:test_flutter/features/sedekah/services/sedekah_cache_service.dart';
import 'package:test_flutter/features/sedekah/services/sedekah_service.dart';

/// Notifier yang di-refactor untuk mengelola SedekahState.
class SedekahNotifier extends StateNotifier<SedekahState> {
  SedekahNotifier() : super(SedekahState.initial());

  /// Mengambil data statistik.
  /// Pola: Coba Jaringan -> Jika Gagal -> Coba Cache -> Jika Gagal -> Error.
  Future<void> loadSedekah() async {
    // Tampilkan loading hanya jika belum ada data sama sekali
    if (state.status == SedekahStatus.initial) {
      state = state.copyWith(status: SedekahStatus.loading);
    }

    try {
      final response = await SedekahService.loadStats();
      // Service mengembalikan data di dalam key 'data'
      final sedekahStats = StatistikSedekah.fromJson(response['data']);

      // 1. Sukses dari Jaringan: Simpan ke cache dan perbarui state
      await SedekahCacheService.cacheSedekah(sedekahStats);

      state = state.copyWith(
        status: SedekahStatus.loaded,
        sedekahStats: sedekahStats,
        isOffline: false,
      );
    } catch (e) {
      logger.warning(
        'Gagal load sedekah dari jaringan: $e. Mencoba dari cache...',
      );
      // 2. Gagal dari Jaringan: Coba ambil dari cache
      final cachedStats = SedekahCacheService.getCachedSedekah();

      // Cek apakah cache benar-benar ada isinya
      if (cachedStats.riwayat.isNotEmpty || cachedStats.totalBulanIni > 0) {
        state = state.copyWith(
          status: SedekahStatus.offline,
          sedekahStats: cachedStats,
          isOffline: true,
          message: 'Menampilkan data offline.',
        );
      } else {
        // 3. Gagal dari Cache juga: Tampilkan error
        state = state.copyWith(
          status: SedekahStatus.error,
          message: 'Gagal memuat data. Periksa koneksi internet Anda.',
        );
      }
    }
  }

  /// Menambahkan data sedekah baru.
  Future<void> addSedekah({
    required String jenisSedekah,
    required String tanggal,
    required int jumlah,
    String? keterangan,
  }) async {
    state = state.copyWith(status: SedekahStatus.loading);

    try {
      final response = await SedekahService.addSedekah(
        jenisSedekah: jenisSedekah,
        tanggal: tanggal,
        jumlah: jumlah,
        keterangan: keterangan,
      );

      state = state.copyWith(
        status: SedekahStatus.success,
        message: response['message'] as String?,
      );

      // Setelah berhasil menambahkan, muat ulang data agar UI terupdate
      await loadSedekah();
    } catch (e) {
      state = state.copyWith(
        status: SedekahStatus.error,
        message: e.toString(),
      );
    }
  }

  /// Menghapus data sedekah berdasarkan ID
  Future<void> deleteSedekah(int id) async {
    state = state.copyWith(status: SedekahStatus.loading);

    try {
      final response = await SedekahService.deleteSedekah(id);

      state = state.copyWith(
        status: SedekahStatus.success,
        message: response['message'] as String?,
      );

      // Setelah berhasil menghapus, muat ulang data agar UI terupdate
      await loadSedekah();
    } catch (e) {
      state = state.copyWith(
        status: SedekahStatus.error,
        message: e.toString(),
      );
    }
  }

  /// Fungsi publik untuk melakukan refresh data (untuk pull-to-refresh).
  Future<void> refresh() async {
    state = state.copyWith(status: SedekahStatus.refreshing);
    await loadSedekah();
  }

  /// Membersihkan pesan (error/sukses) setelah ditampilkan di UI.
  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}

final sedekahProvider = StateNotifierProvider<SedekahNotifier, SedekahState>((
  ref,
) {
  return SedekahNotifier();
});
