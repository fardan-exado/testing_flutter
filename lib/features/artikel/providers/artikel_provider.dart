import 'package:flutter_riverpod/legacy.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/features/artikel/models/artikel/artikel.dart';
import 'package:test_flutter/data/models/paginated.dart';
import 'package:test_flutter/features/artikel/states/artikel_state.dart';
import 'package:test_flutter/features/artikel/services/artikel_cache_service.dart';
import 'package:test_flutter/features/artikel/services/artikel_service.dart';

class ArtikelNotifier extends StateNotifier<ArtikelState> {
  ArtikelNotifier() : super(ArtikelState.initial());

  // Inisialisasi
  Future<void> init() async {
    await Future.wait([fetchKategori(), fetchArtikel()]);
  }

  // Ambil Kategori Artikel dengan strategi network-first, cache-fallback
  Future<void> fetchKategori() async {
    try {
      final response = await ArtikelService.getCategories();
      final kategori = response['data'];

      await ArtikelCacheService.cacheKategori(kategori);

      state = state.copyWith(status: ArtikelStatus.loaded, kategori: kategori);
    } catch (e) {
      logger.warning(
        'Gagal fetch kategori artikel dari jaringan: $e. Mencoba dari cache...',
      );
      // 2. Gagal dari Jaringan: Coba ambil dari cache
      final cachedKategori = ArtikelCacheService.getCachedKategori();
      if (cachedKategori.isNotEmpty) {
        state = state.copyWith(
          status: ArtikelStatus.offline,
          kategori: cachedKategori,
          message: 'Menampilkan data kategori offline.',
        );
      } else {
        // 3. Gagal total: Tampilkan error
        state = state.copyWith(
          status: ArtikelStatus.error,
          message: 'Gagal memuat kategori. Periksa koneksi internet Anda.',
        );
      }
    }
  }

  /// Fungsi utama untuk mengambil daftar artikel (paginated).
  /// Strategi: Network-first, cache-fallback.
  Future<void> fetchArtikel({
    bool isLoadMore = false,
    bool isRefresh = false,
    int? kategoriId,
    String keyword = '',
  }) async {
    if (isLoadMore && !canLoadMore) return;

    // 1. Atur status loading yang sesuai
    if (isRefresh) {
      state = state.copyWith(status: ArtikelStatus.refreshing);
    } else if (isLoadMore) {
      state = state.copyWith(status: ArtikelStatus.loadingMore);
    } else if (state.artikelList.isEmpty) {
      state = state.copyWith(status: ArtikelStatus.loading);
    }

    final pageToLoad = isLoadMore ? state.currentPage + 1 : 1;

    try {
      // 2. Selalu coba ambil dari Jaringan (API)
      final response = await ArtikelService.getArtikels(
        page: pageToLoad,
        keyword: keyword,
        kategoriId: kategoriId,
      );

      final paginatedData = PaginatedResponse<Artikel>.fromJson(
        response,
        (json) => Artikel.fromJson(json),
      );

      // Simpan data baru ke cache
      await ArtikelCacheService.cacheArtikelList(
        artikelList: paginatedData.data,
        currentPage: paginatedData.currentPage,
        totalPages: paginatedData.lastPage,
        totalItems: paginatedData.total,
        isLoadMore: isLoadMore,
      );

      // 3. Jika berhasil, perbarui state dengan data dari Jaringan
      final fullList = isLoadMore
          ? [...state.artikelList, ...paginatedData.data]
          : paginatedData.data;

      state = state.copyWith(
        status: ArtikelStatus.loaded,
        artikelList: fullList,
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
          status: ArtikelStatus.loaded,
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
    final cachedArtikel = ArtikelCacheService.getCachedArtikelList();

    if (cachedArtikel.isNotEmpty) {
      final metadata = ArtikelCacheService.getCacheMetadata();
      state = state.copyWith(
        status: ArtikelStatus.offline,
        artikelList: cachedArtikel,
        currentPage: metadata?.currentPage ?? 1,
        lastPage: metadata?.totalPages ?? 1,
        isOffline: true,
        message: 'Menampilkan data offline. Periksa koneksi internet Anda.',
      );
    } else {
      // Jika cache juga kosong, tampilkan error
      state = state.copyWith(
        status: ArtikelStatus.error,
        artikelList: [],
        isOffline: true,
        // message: 'Gagal memuat data. Periksa koneksi internet Anda.',
      );
    }
  }

  // Ambil Detail Artikel berdasarkan ID
  Future<void> fetchArtikelById(int id) async {
    state = state.copyWith(status: ArtikelStatus.loading);
    try {
      final response = await ArtikelService.getArtikelById(id);
      final artikel = Artikel.fromJson(response['data']);
      state = state.copyWith(
        status: ArtikelStatus.loaded,
        selectedArtikel: artikel,
      );
    } catch (e) {
      logger.warning('Error fetching artikel by id: $e');
      state = state.copyWith(
        status: ArtikelStatus.error,
        message: e.toString(),
      );
    }
  }

  /// Fungsi publik untuk melakukan refresh data.
  Future<void> refresh({int? kategoriId, String keyword = ''}) async {
    await fetchArtikel(
      isRefresh: true,
      kategoriId: kategoriId,
      keyword: keyword,
    );
  }

  /// Getter untuk memeriksa apakah bisa 'load more'.
  bool get canLoadMore =>
      state.currentPage < state.lastPage &&
      !state.isOffline &&
      state.status != ArtikelStatus.loadingMore &&
      state.status != ArtikelStatus.refreshing;
}

// Bagian 4: Definisi Provider
final artikelProvider = StateNotifierProvider<ArtikelNotifier, ArtikelState>((
  ref,
) {
  return ArtikelNotifier();
});
