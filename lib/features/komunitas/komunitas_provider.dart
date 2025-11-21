import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/data/models/paginated.dart';
import 'package:test_flutter/features/komunitas/komunitas_state.dart';
import 'package:test_flutter/features/komunitas/models/kategori/kategori_komunitas.dart';
import 'package:test_flutter/features/komunitas/models/komunitas/komunitas.dart';
import 'package:test_flutter/features/komunitas/services/komunitas_cache_service.dart';
import 'package:test_flutter/features/komunitas/services/komunitas_service.dart';

// Bagian 3: StateNotifier (Logika Utama Provider)
class KomunitasPostinganNotifier extends StateNotifier<KomunitasState> {
  KomunitasPostinganNotifier() : super(KomunitasState.initial());

  // Init
  Future<void> init() async {
    await Future.wait([fetchKategori(), fetchPostingan()]);
  }

  // Get All Kategori Postingan
  Future<void> fetchKategori() async {
    try {
      final resp = await KomunitasService.getAllKategoriPostingan();
      final kategori = resp['data'] as List<KategoriKomunitas>;

      // 1. Sukses dari Jaringan: Simpan ke cache dan perbarui state
      await KomunitasCacheService.cacheKategori(kategori);
      state = state.copyWith(
        status: KomunitasStatus.loaded,
        kategori: kategori,
      );
    } catch (e) {
      logger.warning(
        'Gagal fetch kategori dari jaringan: $e. Mencoba dari cache...',
      );
      // 2. Gagal dari Jaringan: Coba ambil dari cache
      final cachedKategori = KomunitasCacheService.getCachedKategori();
      if (cachedKategori.isNotEmpty) {
        state = state.copyWith(
          status: KomunitasStatus.offline, // Gunakan status offline
          kategori: cachedKategori,
          message: 'Menampilkan data kategori offline.',
        );
      } else {
        // 3. Gagal dari Cache: Tampilkan error
        state = state.copyWith(
          status: KomunitasStatus.error,
          message: 'Gagal memuat kategori. Periksa koneksi internet Anda.',
        );
      }
    }
  }

  /// Fungsi utama untuk mengambil data.
  /// Selalu mencoba dari jaringan terlebih dahulu, jika gagal, beralih ke cache.
  Future<void> fetchPostingan({
    bool isLoadMore = false,
    bool isRefresh = false,
    String? kategoriId,
    String keyword = '',
  }) async {
    if (isLoadMore && !canLoadMore) return;

    // 1. Atur status loading yang sesuai
    if (isRefresh) {
      state = state.copyWith(status: KomunitasStatus.refreshing);
    } else if (isLoadMore) {
      state = state.copyWith(status: KomunitasStatus.loadingMore);
    } else {
      // Jika sudah ada data, jangan tampilkan loading fullscreen
      if (state.postinganList.isEmpty) {
        state = state.copyWith(status: KomunitasStatus.loading);
      }
    }

    final pageToLoad = isLoadMore ? state.currentPage + 1 : 1;

    try {
      // 2. SELALU coba ambil dari Jaringan (API)
      final resp = await KomunitasService.getAllPostingan(
        page: pageToLoad,
        keyword: keyword,
        kategoriId: kategoriId,
      );
      final paginatedData = PaginatedResponse<KomunitasPostingan>.fromJson(
        resp,
        (json) => KomunitasPostingan.fromJson(json),
      );

      // Simpan data baru ke cache
      await KomunitasCacheService.cachePostingan(
        postingan: paginatedData.data,
        currentPage: paginatedData.currentPage,
        totalPages: paginatedData.lastPage,
        totalItems: paginatedData.total,
        isLoadMore: isLoadMore,
      );

      // 3. Jika berhasil, perbarui state dengan data dari Jaringan
      final fullList = isLoadMore
          ? [...state.postinganList, ...paginatedData.data]
          : paginatedData.data;

      state = state.copyWith(
        status: KomunitasStatus.loaded,
        postinganList: fullList,
        currentPage: paginatedData.currentPage,
        lastPage: paginatedData.lastPage,
        isOffline: false,
      );
    } catch (e) {
      logger.warning(
        'Gagal mengambil data dari jaringan: $e. Mencoba dari cache...',
      );

      // 4. Jika Jaringan GAGAL, baru coba ambil dari Cache
      if (isLoadMore) {
        state = state.copyWith(
          status: KomunitasStatus.loaded, // Kembalikan status ke loaded
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
    final cachedPostingan = KomunitasCacheService.getCachedPostingan();

    if (cachedPostingan.isNotEmpty) {
      final metadata = KomunitasCacheService.getCacheMetadata();
      state = state.copyWith(
        status: KomunitasStatus.offline,
        postinganList: cachedPostingan,
        currentPage: metadata?.currentPage ?? 1,
        lastPage: metadata?.totalPages ?? 1,
        isOffline: true,
        message: 'Menampilkan data offline. Periksa koneksi internet Anda.',
      );
    } else {
      // Jika cache juga kosong, tampilkan error
      state = state.copyWith(
        status: KomunitasStatus.error,
        postinganList: [],
        isOffline: true,
        message: 'Gagal memuat data. Periksa koneksi internet Anda.',
      );
    }
  }

  // Get Detail Postingan
  Future<void> fetchPostinganById(String id) async {
    state = state.copyWith(status: KomunitasStatus.loading);

    try {
      final resp = await KomunitasService.getPostinganById(id);
      final postinganMap = resp['data'] as Map<String, dynamic>;
      logger.fine('state postingan: ${postinganMap}');
      final postingan = KomunitasPostingan.fromJson(postinganMap);

      state = state.copyWith(
        status: KomunitasStatus.loaded,
        postingan: postingan,
      );

    } catch (e) {
      logger.warning('Error fetching postingan by id: $e');
      state = state.copyWith(
        status: KomunitasStatus.error,
        message: e.toString(),
      );
    }
  }

  // Create Postingan
  Future<void> createPostingan({
    required int kategoriId,
    required String judul,
    required XFile cover,
    required String konten,
    List<XFile>? daftarGambar,
    bool? isAnonymous,
  }) async {
    state = state.copyWith(status: KomunitasStatus.loading);

    try {
      final response = await KomunitasService.createPostingan(
        kategoriId: kategoriId,
        judul: judul,
        cover: cover,
        konten: konten,
        daftarGambar: daftarGambar,
        isAnonymous: isAnonymous,
      );

      state = state.copyWith(
        status: KomunitasStatus.success,
        message: response['message'],
      );
    } catch (e) {
      state = state.copyWith(
        status: KomunitasStatus.error,
        message: e.toString(),
      );
    }
  }

  // Delete Postingan
  Future<void> deletePostingan(int postinganId) async {
    state = state.copyWith(status: KomunitasStatus.loading);
    try {
      final response = await KomunitasService.deletePostingan(postinganId);

      state = state.copyWith(
        status: KomunitasStatus.success,
        message: response['message'],
        postinganList: state.postinganList
            .where((post) => post.id != postinganId)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(
        status: KomunitasStatus.error,
        message: e.toString(),
      );
    }
  }

  // Toggle Like
  Future<void> toggleLike(String postinganId) async {
    // Don't set loading state for toggle like to avoid UI blocking
    try {
      final response = await KomunitasService.toggleLike(postinganId);

      // Update postingan list if exists
      final updatedList = state.postinganList.map((post) {
        if (post.id.toString() == postinganId) {
          final isLiked = post.liked ?? false;
          final newLikesCount = isLiked
              ? (post.likesCount ?? 0) - 1
              : (post.likesCount ?? 0) + 1;
          return post.copyWith(liked: !isLiked, likesCount: newLikesCount);
        }
        return post;
      }).toList();

      // Update current postingan if viewing detail
      KomunitasPostingan? updatedPostingan;
      if (state.postingan?.id.toString() == postinganId) {
        final isLiked = state.postingan!.liked ?? false;
        final newLikesCount = isLiked
            ? (state.postingan!.likesCount ?? 0) - 1
            : (state.postingan!.likesCount ?? 0) + 1;
        updatedPostingan = state.postingan!.copyWith(
          liked: !isLiked,
          likesCount: newLikesCount,
        );
      }

      state = state.copyWith(
        postinganList: updatedList,
        postingan: updatedPostingan,
        message: response['message'],
      );
    } catch (e) {
      logger.warning  ('Error toggling like: $e');
      // Don't update state on error to avoid disrupting UI
    }
  }

  // Add Comment
  Future<void> addComment({
    required String postinganId,
    required String komentar,
    required bool isAnonymous,
    String? userName,
  }) async {
    // Don't set loading for the whole state
    try {
      final response = await KomunitasService.addComment(
        postinganId: postinganId,
        komentar: komentar,
        isAnonymous: isAnonymous,
      );

      final commentData = response['data'] as Komentar;

      // Update postingan with new comment
      if (state.postingan?.id.toString() == postinganId) {
        final updatedKomentars = [...?state.postingan?.komentars, commentData];
        final newKomentarsCount = (state.postingan?.komentarsCount ?? 0) + 1;

        state = state.copyWith(
          status: KomunitasStatus.success,
          message: response['message'],
          postingan: state.postingan?.copyWith(
            komentars: updatedKomentars,
            komentarsCount: newKomentarsCount,
          ),
        );
      } else {
        state = state.copyWith(
          status: KomunitasStatus.success,
          message: response['message'],
        );
      }
    } catch (e) {
      logger.warning('Error adding comment: $e');
      state = state.copyWith(
        status: KomunitasStatus.error,
        message: e.toString(),
      );
    }
  }

  // Report Postingan
  Future<void> reportPostingan(int postinganId, String alasan) async {
    state = state.copyWith(status: KomunitasStatus.loading);

    try {
      final response = await KomunitasService.reportPostingan(
        postinganId: postinganId,
        alasan: alasan,
      );

      state = state.copyWith(
        status: KomunitasStatus.success,
        message: response['message'],
      );
    } catch (e) {
      state = state.copyWith(
        status: KomunitasStatus.error,
        message: e.toString(),
      );
    }
  }

  /// Fungsi publik untuk melakukan refresh data.
  Future<void> refresh({String? kategoriId, String keyword = ''}) async {
    await fetchPostingan(
      isRefresh: true,
      kategoriId: kategoriId,
      keyword: keyword,
    );
  }

  /// Getter untuk memeriksa apakah bisa 'load more'.
  bool get canLoadMore =>
      state.currentPage < state.lastPage &&
      !state.isOffline &&
      state.status != KomunitasStatus.loadingMore &&
      state.status != KomunitasStatus.refreshing;

  void clear() {
    state = state.copyWith(clear: true);
  }
}

// Bagian 4: Definisi Provider
// Ini adalah "pintu masuk" yang akan digunakan oleh UI untuk berinteraksi dengan Notifier.
final komunitasProvider =
    StateNotifierProvider<KomunitasPostinganNotifier, KomunitasState>((ref) {
      return KomunitasPostinganNotifier();
    });
