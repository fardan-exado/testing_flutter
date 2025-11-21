import 'package:test_flutter/core/constants/cache_keys.dart';
import 'package:test_flutter/features/artikel/models/artikel/artikel.dart';
import 'package:test_flutter/features/artikel/models/kategori/kategori_artikel.dart';
import 'package:test_flutter/data/models/cache/cache.dart';
import 'package:test_flutter/data/services/cache/cache_service.dart';

class ArtikelCacheService {
  static const Duration _cacheDuration = Duration(hours: 24);

  // --- CACHE KATEGORI ARTIKEL ---
  static Future<void> cacheKategori(List<KategoriArtikel> kategori) async {
    await CacheService.cacheData(
      key: CacheKeys.artikelKategori, // -> 2. Gunakan key untuk artikel
      data: kategori,
      dataType: 'artikel_kategori', // -> 3. Sesuaikan tipe data
      customExpiryDuration: _cacheDuration,
    );
  }

  static List<KategoriArtikel> getCachedKategori() {
    return CacheService.getCachedData<List<KategoriArtikel>>(
          key: CacheKeys.artikelKategori,
          fromJson: (jsonData) {
            if (jsonData is List) {
              return jsonData
                  .map(
                    // -> 4. Gunakan fromJson dari model yang sesuai
                    (item) =>
                        KategoriArtikel.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
            }
            return [];
          },
        ) ??
        []; // Kembalikan list kosong jika null
  }

  // --- CACHE LIST ARTIKEL ---
  static Future<void> cacheArtikelList({
    required List<Artikel> artikelList, // -> 5. Ganti nama & tipe parameter
    required int currentPage,
    required int totalPages,
    required int totalItems,
    bool isLoadMore = false,
  }) async {
    await CacheService.cachePaginatedData<Artikel>(
      key: CacheKeys.artikelList, // -> 2. Gunakan key untuk artikel
      newData: artikelList,
      currentPage: currentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      dataType: 'artikel_list', // -> 3. Sesuaikan tipe data
      isLoadMore: isLoadMore,
      customExpiryDuration: _cacheDuration,
    );
  }

  // --- GET CACHE LIST ARTIKEL ---
  static List<Artikel> getCachedArtikelList() {
    return CacheService.getCachedData<List<Artikel>>(
          key: CacheKeys.artikelList,
          fromJson: (jsonData) {
            if (jsonData is List) {
              return jsonData
                  .map(
                    // -> 4. Gunakan fromJson dari model yang sesuai
                    (item) => Artikel.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
            }
            return [];
          },
        ) ??
        []; // Kembalikan list kosong jika null
  }

  // --- CACHE DETAIL ARTIKEL ---
  static Future<void> cacheArtikelDetail(Artikel artikel) async {
    // Asumsi artikel.id adalah int
    final artikelId = artikel.id;

    await CacheService.cacheData(
      key: CacheKeys.artikelDetail(
        artikelId,
      ), // -> 2. Gunakan key untuk artikel
      data: artikel,
      dataType: 'artikel_detail', // -> 3. Sesuaikan tipe data
      customExpiryDuration: _cacheDuration,
    );
  }

  // --- GET CACHE DETAIL ARTIKEL ---
  static Artikel? getCachedArtikelDetail(int artikelId) {
    return CacheService.getCachedData<Artikel>(
      key: CacheKeys.artikelDetail(artikelId),
      fromJson: (json) => Artikel.fromJson(json as Map<String, dynamic>),
    );
  }

  // --- METADATA & CLEAR CACHE ---
  static CacheMetadata? getCacheMetadata() {
    return CacheService.getCacheMetadata(CacheKeys.artikelList);
  }

  static Future<void> clearCache() async {
    await CacheService.clearCache(CacheKeys.artikelList);
  }
}
