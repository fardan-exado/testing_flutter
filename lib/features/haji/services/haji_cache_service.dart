import 'package:test_flutter/core/constants/cache_keys.dart';
import 'package:test_flutter/data/models/haji/haji.dart';
import 'package:test_flutter/data/models/cache/cache.dart';
import 'package:test_flutter/data/services/cache/cache_service.dart';

class HajiCacheService {
  static const Duration _cacheDuration = Duration(hours: 24);

  // --- CACHE LIST HAJI ---
  static Future<void> cacheHajiList({
    required List<Haji> hajiList,
    required int currentPage,
    required int totalPages,
    required int totalItems,
    bool isLoadMore = false,
  }) async {
    await CacheService.cachePaginatedData<Haji>(
      key: CacheKeys.hajiList, // -> 2. Gunakan key untuk haji
      newData: hajiList,
      currentPage: currentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      dataType: 'haji_list', // -> 3. Sesuaikan tipe data
      isLoadMore: isLoadMore,
      customExpiryDuration: _cacheDuration,
    );
  }

  // --- GET CACHE LIST HAJI ---
  static List<Haji> getCachedHajiList() {
    return CacheService.getCachedData<List<Haji>>(
          key: CacheKeys.hajiList,
          fromJson: (jsonData) {
            if (jsonData is List) {
              return jsonData
                  .map(
                    // -> 4. Gunakan fromJson dari model yang sesuai
                    (item) => Haji.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
            }
            return [];
          },
        ) ??
        []; // Kembalikan list kosong jika null
  }

  // --- CACHE DETAIL Haji ---
  static Future<void> cacheHajiDetail(Haji haji) async {
    // Asumsi haji.id adalah int
    final hajiId = haji.id;

    await CacheService.cacheData(
      key: CacheKeys.hajiDetail(hajiId), // -> 2. Gunakan key untuk haji
      data: haji,
      dataType: 'haji_detail', // -> 3. Sesuaikan tipe data
      customExpiryDuration: _cacheDuration,
    );
  }

  // --- GET CACHE DETAIL Haji ---
  static Haji? getCachedHajiDetail(int hajiId) {
    return CacheService.getCachedData<Haji>(
      key: CacheKeys.hajiDetail(hajiId),
      fromJson: (json) => Haji.fromJson(json as Map<String, dynamic>),
    );
  }

  // --- METADATA & CLEAR CACHE ---
  static CacheMetadata? getCacheMetadata() {
    return CacheService.getCacheMetadata(CacheKeys.hajiList);
  }

  static Future<void> clearCache() async {
    await CacheService.clearCache(CacheKeys.hajiList);
  }
}
