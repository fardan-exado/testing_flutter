import 'package:test_flutter/core/constants/cache_keys.dart';
import 'package:test_flutter/data/models/cache/cache.dart';
import 'package:test_flutter/data/services/cache/cache_service.dart';
import 'package:test_flutter/features/komunitas/models/kategori/kategori_komunitas.dart';
import 'package:test_flutter/features/komunitas/models/komunitas/komunitas.dart';

class KomunitasCacheService {
  static const Duration _cacheDuration = Duration(hours: 24);

  // CACHE KATEGORI
  static Future<void> cacheKategori(List<KategoriKomunitas> kategori) async {
    await CacheService.cacheData(
      key: CacheKeys.komunitasKategori, // -> 3. Gunakan key dari CacheKeys
      data: kategori,
      dataType: 'komunitas_kategori',
      customExpiryDuration: _cacheDuration, // -> 4. Kirim sebagai Duration
    );
  }

  static List<KategoriKomunitas> getCachedKategori() {
    return CacheService.getCachedData<List<KategoriKomunitas>>(
          key: CacheKeys.komunitasKategori, // -> 3. Gunakan key dari CacheKeys
          fromJson: (jsonData) {
            if (jsonData is List) {
              return jsonData
                  .map(
                    (item) => KategoriKomunitas.fromJson(
                      item as Map<String, dynamic>,
                    ),
                  )
                  .toList();
            }
            return [];
          },
        ) ??
        []; // Kembalikan list kosong jika null
  }

  // --- CACHE POSTINGAN ---
  static Future<void> cachePostingan({
    required List<KomunitasPostingan> postingan,
    required int currentPage,
    required int totalPages,
    required int totalItems,
    bool isLoadMore = false,
  }) async {
    await CacheService.cachePaginatedData<KomunitasPostingan>(
      key: CacheKeys.komunitasPostingan, // -> 3. Gunakan key dari CacheKeys
      newData: postingan,
      currentPage: currentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      dataType: 'komunitas_postingan',
      isLoadMore: isLoadMore,
      customExpiryDuration: _cacheDuration, // -> 4. Kirim sebagai Duration
    );
  }

  // --- GET CACHE POSTINGAN ---
  static List<KomunitasPostingan> getCachedPostingan() {
    return CacheService.getCachedData<List<KomunitasPostingan>>(
          key: CacheKeys.komunitasPostingan, // -> 3. Gunakan key dari CacheKeys
          fromJson: (jsonData) {
            if (jsonData is List) {
              return jsonData
                  .map(
                    (item) => KomunitasPostingan.fromJson(
                      item as Map<String, dynamic>,
                    ),
                  )
                  .toList();
            }
            return [];
          },
        ) ??
        []; // Kembalikan list kosong jika null
  }

  // --- CACHE POSTINGAN DETAIL ---
  static Future<void> cachePostinganDetail(KomunitasPostingan postingan) async {
    final postinganId = postingan.id as String;

    await CacheService.cacheData(
      // Asumsi CacheService punya method `cacheData`
      key: CacheKeys.postinganDetail(
        postinganId,
      ), // -> 5. Gunakan helper method dari CacheKeys
      data: postingan,
      dataType: 'komunitas_postingan_detail',
      customExpiryDuration: _cacheDuration, // -> 4. Kirim sebagai Duration
    );
  }

  // Get cached postingan detail
  static KomunitasPostingan? getCachedPostinganDetail(String postinganId) {
    return CacheService.getCachedData<KomunitasPostingan>(
      key: CacheKeys.postinganDetail(postinganId),
      fromJson: (json) =>
          KomunitasPostingan.fromJson(json as Map<String, dynamic>),
    );
  }

  static CacheMetadata? getCacheMetadata() {
    return CacheService.getCacheMetadata(CacheKeys.komunitasPostingan);
  }

  static Future<void> clearCache() async {
    await CacheService.clearCache(CacheKeys.komunitasPostingan);
  }
}
