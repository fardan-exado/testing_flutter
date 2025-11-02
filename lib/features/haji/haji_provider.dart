import 'package:flutter_riverpod/legacy.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/data/models/haji/haji.dart';
import 'package:test_flutter/data/models/paginated.dart';
import 'package:test_flutter/features/haji/haji_state.dart';
import 'package:test_flutter/features/haji/services/haji_cache_service.dart';
import 'package:test_flutter/features/haji/services/haji_service.dart';

class HajiNotifier extends StateNotifier<HajiState> {
  HajiNotifier() : super(HajiState.initial());

  // Inisialisasi
  Future<void> init() async {
    await Future.wait([fetchHaji()]);
  }

  /// Fungsi utama untuk mengambil daftar haji (paginated).
  /// Strategi: Network-first, cache-fallback.
  Future<void> fetchHaji({
    bool isLoadMore = false,
    bool isRefresh = false,
    String keyword = '',
  }) async {
    if (isLoadMore && !canLoadMore) return;

    // 1. Atur status loading yang sesuai
    if (isRefresh) {
      state = state.copyWith(status: HajiStatus.refreshing);
    } else if (isLoadMore) {
      state = state.copyWith(status: HajiStatus.loadingMore);
    } else if (state.hajiList.isEmpty) {
      state = state.copyWith(status: HajiStatus.loading);
    }

    final pageToLoad = isLoadMore ? state.currentPage + 1 : 1;

    try {
      // 2. Selalu coba ambil dari Jaringan (API)
      final response = await HajiService.getHajis(
        page: pageToLoad,
        keyword: keyword,
      );

      final paginatedData = PaginatedResponse<Haji>.fromJson(
        response,
        (json) => Haji.fromJson(json),
      );

      // Simpan data baru ke cache
      await HajiCacheService.cacheHajiList(
        hajiList: paginatedData.data,
        currentPage: paginatedData.currentPage,
        totalPages: paginatedData.lastPage,
        totalItems: paginatedData.total,
        isLoadMore: isLoadMore,
      );

      // 3. Jika berhasil, perbarui state dengan data dari Jaringan
      final fullList = isLoadMore
          ? [...state.hajiList, ...paginatedData.data]
          : paginatedData.data;

      state = state.copyWith(
        status: HajiStatus.loaded,
        hajiList: fullList,
        currentPage: paginatedData.currentPage,
        lastPage: paginatedData.lastPage,
        isOffline: false,
      );
    } catch (e) {
      logger.warning(
        'Gagal mengambil artikel dari jaringan: $e. Mencoba dari cache...',
      );

      // 4. Jika Jaringan GAGAL, coba ambil dari Cache
      if (isLoadMore) {
        // Jika gagal saat load more, cukup tampilkan pesan, jangan ganti data
        state = state.copyWith(
          status: HajiStatus.loaded,
          isOffline: true,
          message: 'Koneksi bermasalah, tidak dapat memuat lebih banyak.',
        );
      } else {
        await _loadFromCache();
      }
    }
  }

  /// Fungsi private untuk memuat data HANYA dari cache.
  Future<void> _loadFromCache() async {
    final cachedHaji = HajiCacheService.getCachedHajiList();

    if (cachedHaji.isNotEmpty) {
      final metadata = HajiCacheService.getCacheMetadata();
      state = state.copyWith(
        status: HajiStatus.offline,
        hajiList: cachedHaji,
        currentPage: metadata?.currentPage ?? 1,
        lastPage: metadata?.totalPages ?? 1,
        isOffline: true,
        message: 'Menampilkan data offline. Periksa koneksi internet Anda.',
      );
    } else {
      // Jika cache juga kosong, tampilkan error
      state = state.copyWith(
        status: HajiStatus.error,
        hajiList: [],
        isOffline: true,
        // message: 'Gagal memuat data. Periksa koneksi internet Anda.',
      );
    }
  }

  // Ambil Detail Artikel berdasarkan ID
  Future<void> fetchArtikelById(int id) async {
    state = state.copyWith(status: HajiStatus.loading);
    try {
      final response = await HajiService.getHajiById(id);
      final haji = Haji.fromJson(response['data']);
      state = state.copyWith(status: HajiStatus.loaded, selectedHaji: haji);
    } catch (e) {
      logger.warning('Error fetching artikel by id: $e');
      state = state.copyWith(status: HajiStatus.error, message: e.toString());
    }
  }

  /// Fungsi publik untuk melakukan refresh data.
  Future<void> refresh({String keyword = ''}) async {
    await fetchHaji(isRefresh: true, keyword: keyword);
  }

  /// Getter untuk memeriksa apakah bisa 'load more'.
  bool get canLoadMore =>
      state.currentPage < state.lastPage &&
      !state.isOffline &&
      state.status != HajiStatus.loadingMore &&
      state.status != HajiStatus.refreshing;
}

// Bagian 4: Definisi Provider
final hajiProvider = StateNotifierProvider<HajiNotifier, HajiState>((ref) {
  return HajiNotifier();
});
