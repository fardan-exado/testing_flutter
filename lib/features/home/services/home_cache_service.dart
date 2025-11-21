import 'package:test_flutter/core/constants/cache_keys.dart';
import 'package:test_flutter/data/models/artikel/artikel.dart';
import 'package:test_flutter/features/sholat/models/sholat/sholat.dart';
import 'package:test_flutter/data/services/cache/cache_service.dart';

class HomeCacheService {
  static const Duration _sholatCacheDuration = Duration(hours: 24);
  static const Duration _articleCacheDuration = Duration(hours: 24);

  // CACHE JADWAL SHOLAT
  static Future<void> cacheJadwalSholat(Sholat jadwal) async {
    await CacheService.cacheData(
      key: CacheKeys.homeJadwalSholat,
      data: jadwal,
      dataType: 'home_jadwal_sholat',
      customExpiryDuration:
          _sholatCacheDuration, // -> 4. Kirim sebagai Duration
    );
  }

  // CACHE ARTIKEL TERBARU
  static Future<void> cacheArtikelTerbaru(List<Artikel> articles) async {
    await CacheService.cacheData(
      key: CacheKeys.homeLatestArticle,
      data: articles,
      dataType: 'home_artikel_terbaru',
      customExpiryDuration: _articleCacheDuration,
    );
  }

  // CACHE DETAIL ARTIKEL
  static Future<void> cacheArtikelDetail(Artikel article) async {
    await CacheService.cacheData(
      key: CacheKeys.homeArtikelDetail(article.id),
      data: article,
      dataType: 'home_detail_artikel_${article.id}',
      customExpiryDuration: _articleCacheDuration,
    );
  }

  // GET JADWAL SHOLAT DARI CACHE
  static Sholat getCachedJadwalSholat() {
    return CacheService.getCachedData<Sholat>(
          key: CacheKeys.homeJadwalSholat, // -> 3. Gunakan key dari CacheKeys
          fromJson: (jsonData) {
            if (jsonData is Map<String, dynamic>) {
              return Sholat.fromJson(jsonData);
            }
            return Sholat.empty();
          },
        ) ??
        Sholat.empty();
  }

  // GET ARTIKEL TERBARU DARI CACHE
  static List<Artikel> getCachedArtikelTerbaru() {
    return CacheService.getCachedData<List<Artikel>>(
          key: CacheKeys.homeLatestArticle,
          fromJson: (jsonData) {
            if (jsonData is List) {
              return jsonData.map((item) => Artikel.fromJson(item)).toList();
            }
            return [];
          },
        ) ??
        [];
  }

  // GET DETAIL ARTIKEL DARI CACHE
  static Artikel? getCachedArtikelDetail(int artikelId) {
    return CacheService.getCachedData<Artikel>(
      key: CacheKeys.homeArtikelDetail(artikelId),
      fromJson: (jsonData) {
        if (jsonData is Artikel) {
          return jsonData;
        }
        return Artikel.empty();
      },
    );
  }
}
