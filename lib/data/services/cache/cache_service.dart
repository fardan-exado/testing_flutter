import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:test_flutter/data/models/cache/cache.dart'; // Model data untuk cache

class CacheService {
  static const String _cacheBoxName = 'app_cache';
  static const String _metadataBoxName = 'cache_metadata';

  static Box<CacheEntry>? _cacheBox;
  static Box<CacheMetadata>? _metadataBox;

  /// FUNGSI init()
  static Future<void> init() async {
    try {
      await Hive.initFlutter();

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CacheMetadataAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(CacheEntryAdapter());
      }

      _cacheBox = await Hive.openBox<CacheEntry>(_cacheBoxName);
      _metadataBox = await Hive.openBox<CacheMetadata>(_metadataBoxName);
    } catch (e) {
      rethrow;
    }
  }

  ///
  /// Tugas: Mengambil barang dari gudang berdasarkan kodenya (key).
  static T? getCachedData<T>({
    required String key,
    required T Function(dynamic jsonData) fromJson,
  }) {
    final entry = _cacheBox?.get(key);
    if (entry == null) {
      return null;
    }

    final DateTime expiryDate =
        entry.customExpiry ?? entry.cachedAt.add(const Duration(hours: 24));
    final bool isExpired = DateTime.now().isAfter(expiryDate);

    if (isExpired) {
      _cacheBox?.delete(key);
      _metadataBox?.delete(key);
      return null;
    }

    final dynamic decodedData = jsonDecode(entry.jsonData);
    return fromJson(decodedData);
  }

  /// ================================================================
  ///
  /// Tugas: Menyimpan satu buah data (bukan list/paginasi).
  /// Contoh: Detail profil pengguna, detail artikel tunggal.
  static Future<void> cacheData<T>({
    required String key,
    required T data, // Menerima satu objek data, bukan List<T>
    required String dataType,
    Duration? customExpiryDuration,
  }) async {
    // 1. Ubah objek data menjadi format teks (JSON).
    //    `jsonEncode` secara otomatis akan mencari dan memanggil method `.toJson()`
    //    jika `data` adalah sebuah custom object/model.
    final jsonData = jsonEncode(data);

    // 2. Hitung waktu pasti kedaluwarsanya jika durasi custom diberikan.
    DateTime? expiryDate;
    if (customExpiryDuration != null) {
      expiryDate = DateTime.now().add(customExpiryDuration);
    }

    // 3. Buat "paket" entri cache.
    final cacheEntry = CacheEntry(
      key: key,
      jsonData: jsonData,
      cachedAt: DateTime.now(),
      customExpiry: expiryDate,
      dataType: dataType,
    );

    // 4. Simpan paket ke dalam kotak cache.
    await _cacheBox?.put(key, cacheEntry);
  }

  /// ================================================================

  ///
  /// Tugas: Menyimpan data yang bentuknya berhalaman-halaman (paginasi).
  static Future<void> cachePaginatedData<T>({
    required String key,
    required List<T> newData,
    required int currentPage,
    required int totalPages,
    required int totalItems,
    required String dataType,
    bool isLoadMore = false,
    Duration? customExpiryDuration,
  }) async {
    List<dynamic> dataToCache;

    if (isLoadMore) {
      final existingData =
          getCachedData<List<dynamic>>(
            key: key,
            fromJson: (jsonData) => jsonData as List<dynamic>,
          ) ??
          [];

      dataToCache = [...existingData, ...newData];
    } else {
      dataToCache = newData;
    }

    final jsonData = jsonEncode(
      dataToCache.map((item) => (item as dynamic).toJson()).toList(),
    );

    DateTime? expiryDate;
    if (customExpiryDuration != null) {
      expiryDate = DateTime.now().add(customExpiryDuration);
    }

    final cacheEntry = CacheEntry(
      key: key,
      jsonData: jsonData,
      cachedAt: DateTime.now(),
      customExpiry: expiryDate,
      dataType: dataType,
    );
    await _cacheBox?.put(key, cacheEntry);

    final metadata = CacheMetadata(
      lastFetch: DateTime.now(),
      totalPages: totalPages,
      currentPage: currentPage,
      totalItems: totalItems,
      cacheKey: key,
      customExpiry: expiryDate,
    );
    await _metadataBox?.put(key, metadata);
  }

  /// FUNGSI hasCachedData()
  ///
  /// Tugas: Cuma ngecek, "apakah ada data untuk kode ini dan belum kedaluwarsa?"
  static bool hasCachedData(String key) {
    final data = getCachedData(key: key, fromJson: (json) => json);
    return data != null;
  }

  /// FUNGSI isCacheValid()
  ///
  /// Tugas: Mengecek apakah cache masih valid (belum expired)
  /// Return true jika cache ada dan belum expired
  /// Return false jika cache tidak ada atau sudah expired
  static bool isCacheValid(String key) {
    final entry = _cacheBox?.get(key);
    if (entry == null) {
      return false;
    }

    final DateTime expiryDate =
        entry.customExpiry ?? entry.cachedAt.add(const Duration(hours: 24));
    final bool isExpired = DateTime.now().isAfter(expiryDate);

    return !isExpired;
  }

  /// FUNGSI getAllCacheKeys()
  ///
  /// Tugas: Mendapatkan semua key yang ada di cache box
  /// Return list of string keys
  static List<String> getAllCacheKeys() {
    return _cacheBox?.keys.cast<String>().toList() ?? [];
  }

  /// FUNGSI getCacheInfo()
  ///
  /// Tugas: Mendapatkan informasi statistik cache
  /// Return map dengan info total cache, types, dll
  static Map<String, dynamic> getCacheInfo() {
    final allEntries = _cacheBox?.values.toList() ?? [];

    // Group by dataType
    final Map<String, int> typeCount = {};
    for (final entry in allEntries) {
      final type = entry.dataType;
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }

    return {
      'total_entries': allEntries.length,
      'types': typeCount,
      'cache_box_name': _cacheBoxName,
      'metadata_box_name': _metadataBoxName,
    };
  }

  /// FUNGSI getCacheMetadata()
  ///
  /// Tugas: Mendapatkan metadata dari cache (untuk paginated data)
  static CacheMetadata? getCacheMetadata(String key) => _metadataBox?.get(key);

  /// FUNGSI clearCache()
  ///
  /// Tugas: Menghapus cache berdasarkan key
  static Future<void> clearCache(String key) async {
    try {
      if (_cacheBox != null && _cacheBox!.isOpen) {
        await _cacheBox!.delete(key);
      }
      if (_metadataBox != null && _metadataBox!.isOpen) {
        await _metadataBox!.delete(key);
      }
    } catch (e) {
      print('Error clearing cache for key $key: $e');
    }
  }

  /// FUNGSI clearAllCache()
  ///
  /// Tugas: Menghapus semua cache yang ada
  static Future<void> clearAllCache() async {
    try {
      if (_cacheBox != null && _cacheBox!.isOpen) {
        await _cacheBox!.clear();
      }
      if (_metadataBox != null && _metadataBox!.isOpen) {
        await _metadataBox!.clear();
      }
    } catch (e) {
      print('Error clearing all cache: $e');
    }
  }

  /// FUNGSI getCacheSize()
  ///
  /// Tugas: Mendapatkan estimasi ukuran cache dalam bytes
  static int getCacheSize() {
    int totalSize = 0;
    final allEntries = _cacheBox?.values.toList() ?? [];

    for (final entry in allEntries) {
      // Estimate size based on JSON string length
      totalSize += entry.jsonData.length;
    }

    return totalSize;
  }

  /// FUNGSI clearExpiredCache()
  ///
  /// Tugas: Menghapus semua cache yang sudah expired
  static Future<int> clearExpiredCache() async {
    int deletedCount = 0;
    final allKeys = getAllCacheKeys();

    for (final key in allKeys) {
      final entry = _cacheBox?.get(key);
      if (entry != null) {
        final DateTime expiryDate =
            entry.customExpiry ?? entry.cachedAt.add(const Duration(hours: 24));
        final bool isExpired = DateTime.now().isAfter(expiryDate);

        if (isExpired) {
          await clearCache(key);
          deletedCount++;
        }
      }
    }

    return deletedCount;
  }

  /// FUNGSI close()
  ///
  /// Tugas: Menutup box cache (biasanya dipanggil saat app terminate)
  static Future<void> close() async {
    await _cacheBox?.close();
    await _metadataBox?.close();
  }
}
