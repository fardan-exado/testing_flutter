import 'package:test_flutter/core/constants/cache_keys.dart';
import 'package:test_flutter/data/models/cache/cache.dart';
import 'package:test_flutter/features/sholat/models/sholat/sholat.dart';
import 'package:test_flutter/data/services/cache/cache_service.dart';

class SholatCacheService {
  // Cache hanya untuk 1 hari (akan refresh otomatis setiap hari)
  static const Duration _jadwalCacheDuration = Duration(hours: 24);
  static const Duration _progressCacheDuration = Duration(hours: 12);

  // CACHE JADWAL SHOLAT
  static Future<void> cacheJadwalSholat(List<JadwalSholat> jadwal) async {
    await CacheService.cacheData(
      key: CacheKeys.jadwalSholat,
      data: jadwal,
      dataType: 'jadwal_sholat',
      customExpiryDuration: _jadwalCacheDuration,
    );
  }

  // CACHE PROGRESS HARI INI
  static Future<void> cacheProgressSholatWajibHariIni(
    Map<String, dynamic> progress,
  ) async {
    await CacheService.cacheData(
      key: CacheKeys.progressSholatWajibHariIni,
      data: progress,
      dataType: 'progress_sholat_wajib_hari_ini',
      customExpiryDuration: _progressCacheDuration,
    );
  }

  // CACHE PROGRESS WAJIB RIWAYAT
  static Future<void> cacheProgressSholatWajibRiwayat(
    Map<String, dynamic> progress,
  ) async {
    await CacheService.cacheData(
      key: CacheKeys.progressSholatWajibRiwayat,
      data: progress,
      dataType: 'progress_sholat_wajib_riwayat',
      customExpiryDuration: _progressCacheDuration,
    );
  }

  // CACHE PROGRESS SUNNAH RIWAYAT
  static Future<void> cacheProgressSholatSunnahRiwayat(
    Map<String, dynamic> progress,
  ) async {
    await CacheService.cacheData(
      key: CacheKeys.progressSholatSunnahRiwayat,
      data: progress,
      dataType: 'progress_sholat_sunnah_riwayat',
      customExpiryDuration: _progressCacheDuration,
    );
  }

  // CACHE PROGRESS HARI INI
  static Future<void> cacheProgressSholatSunnahHariIni(
    List<dynamic> progress,
  ) async {
    await CacheService.cacheData(
      key: CacheKeys.progressSholatSunnahHariIni,
      data: progress,
      dataType: 'progress_sholat_sunnah_hari_ini',
      customExpiryDuration: _progressCacheDuration,
    );
  }

  // GET JADWAL SHOLAT DARI CACHE
  static List<JadwalSholat> getCachedJadwalSholat() {
    return CacheService.getCachedData<List<JadwalSholat>>(
          key: CacheKeys.jadwalSholat,
          fromJson: (jsonData) {
            if (jsonData is List) {
              return jsonData
                  .map((item) => JadwalSholat.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
            return [];
          },
        ) ??
        [];
  }

  // GET PROGRESS SHOLAT WAJIB HARI INI DARI CACHE
  static Map<String, dynamic> getCachedProgressSholatWajibHariIni() {
    return CacheService.getCachedData<Map<String, dynamic>>(
          key: CacheKeys.progressSholatWajibHariIni,
          fromJson: (jsonData) {
            if (jsonData is Map<String, dynamic>) {
              return jsonData;
            }
            return {};
          },
        ) ??
        {};
  }

  // GET PROGRESS SHOLAT SUNNAH HARI INI DARI CACHE
  static List<dynamic> getCachedProgressSholatSunnahHariIni() {
    return CacheService.getCachedData<List<dynamic>>(
          key: CacheKeys.progressSholatSunnahHariIni,
          fromJson: (jsonData) {
            if (jsonData is List) {
              return jsonData;
            }
            return [];
          },
        ) ??
        [];
  }

  // GET PROGRESS SHOLAT WAJIB RIWAYAT DARI CACHE
  static Map<String, dynamic> getCachedProgressSholatWajibRiwayat() {
    return CacheService.getCachedData<Map<String, dynamic>>(
          key: CacheKeys.progressSholatWajibRiwayat,
          fromJson: (jsonData) {
            if (jsonData is Map<String, dynamic>) {
              return jsonData;
            }
            return {};
          },
        ) ??
        {};
  }

  // GET PROGRESS SHOLAT SUNNAH RIWAYAT DARI CACHE
  static Map<String, dynamic> getCachedProgressSholatSunnahRiwayat() {
    return CacheService.getCachedData<Map<String, dynamic>>(
          key: CacheKeys.progressSholatSunnahRiwayat,
          fromJson: (jsonData) {
            if (jsonData is Map<String, dynamic>) {
              return jsonData;
            }
            return {};
          },
        ) ??
        {};
  }

  static CacheMetadata? getCacheMetadata() {
    return CacheService.getCacheMetadata(CacheKeys.jadwalSholat);
  }

  static Future<void> clearCache() async {
    await CacheService.clearCache(CacheKeys.jadwalSholat);
    await CacheService.clearCache(CacheKeys.progressSholatWajibHariIni);
    await CacheService.clearCache(CacheKeys.progressSholatSunnahHariIni);
    await CacheService.clearCache(CacheKeys.progressSholatWajibRiwayat);
    await CacheService.clearCache(CacheKeys.progressSholatSunnahRiwayat);
  }
}
