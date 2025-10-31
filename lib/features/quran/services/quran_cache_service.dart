import 'package:hive_flutter/hive_flutter.dart';
import 'package:test_flutter/core/constants/cache_keys.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/data/models/quran/progres_quran.dart';
import 'package:test_flutter/data/models/quran/progres_quran_cache.dart';

class QuranCacheService {
  static const String _boxName = CacheKeys.progresQuranRiwayat;

  /// Get cached riwayat progres
  static List<ProgresBacaQuran> getCachedRiwayat() {
    try {
      final box = Hive.box<ProgresBacaQuranCache>(_boxName);
      final cached = box.values.toList();

      if (cached.isEmpty) {
        logger.fine('📭 No cached riwayat found');
        return [];
      }

      // Sort by createdAt descending (newest first)
      cached.sort((a, b) {
        final dateA = DateTime.tryParse(a.createdAt ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b.createdAt ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      final riwayat = cached.map((e) => e.toModel()).toList();
      logger.fine('📖 Loaded ${riwayat.length} cached riwayat');

      return riwayat;
    } catch (e) {
      logger.warning('❌ Error loading cached riwayat: $e');
      return [];
    }
  }

  /// Cache riwayat progres
  static Future<void> cacheRiwayat(List<ProgresBacaQuran> riwayat) async {
    try {
      final box = Hive.box<ProgresBacaQuranCache>(_boxName);

      // Clear old cache
      await box.clear();

      // Save new cache
      for (final item in riwayat) {
        final cache = ProgresBacaQuranCache.fromModel(item);
        await box.add(cache);
      }

      logger.fine('💾 Cached ${riwayat.length} riwayat items');
    } catch (e) {
      logger.warning('❌ Failed to cache riwayat: $e');
    }
  }

  /// Add single progres to cache
  static Future<void> addProgresToCache(ProgresBacaQuran progres) async {
    try {
      final box = Hive.box<ProgresBacaQuranCache>(_boxName);
      final cache = ProgresBacaQuranCache.fromModel(progres);
      await box.add(cache);

      logger.fine(
        '💾 Added progres to cache: Surah ${progres.suratId}, Ayah ${progres.ayat}',
      );
    } catch (e) {
      logger.warning('❌ Failed to add progres to cache: $e');
    }
  }

  /// Delete progres from cache by id
  static Future<void> deleteProgresFromCache(int progresId) async {
    try {
      final box = Hive.box<ProgresBacaQuranCache>(_boxName);

      // Find and delete item with matching id
      final keys = box.keys.toList();
      for (final key in keys) {
        final item = box.get(key);
        if (item?.id == progresId) {
          await box.delete(key);
          logger.fine('🗑️ Deleted progres from cache: id=$progresId');
          break;
        }
      }
    } catch (e) {
      logger.warning('❌ Failed to delete progres from cache: $e');
    }
  }

  /// Clear all cached riwayat
  static Future<void> clearCache() async {
    try {
      final box = Hive.box<ProgresBacaQuranCache>(_boxName);
      await box.clear();
      logger.fine('🗑️ Cleared all cached riwayat');
    } catch (e) {
      logger.warning('❌ Failed to clear cache: $e');
    }
  }
}
