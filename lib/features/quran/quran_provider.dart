import 'package:flutter_riverpod/legacy.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/data/models/quran/progres_quran.dart';
import 'package:test_flutter/features/quran/quran_state.dart';
import 'package:test_flutter/features/quran/services/quran_cache_service.dart';
import 'package:test_flutter/features/quran/services/quran_progres_service.dart';

class QuranNotifier extends StateNotifier<QuranState> {
  QuranNotifier() : super(QuranState.initial());

  // Init - Load from cache first
  Future<void> init() async {
    try {
      logger.fine('🔄 Initializing Quran Provider...');

      // Load from cache first
      final cachedRiwayat = QuranCacheService.getCachedRiwayat();

      if (cachedRiwayat.isNotEmpty) {
        state = state.copyWith(
          status: QuranStatus.loaded,
          riwayatProgres: cachedRiwayat,
          isOffline: false,
        );
        logger.fine('✅ Loaded ${cachedRiwayat.length} items from cache');
      } else {
        state = state.copyWith(status: QuranStatus.loaded, riwayatProgres: []);
        logger.fine('ℹ️ No cached riwayat found');
      }

      // Try to sync with API in background
      try {
        await fetchRiwayat();
      } catch (e) {
        logger.fine('⚠️ API sync failed, using cached data: $e');
      }
    } catch (e) {
      logger.fine('❌ Init error: $e');
      state = state.copyWith(status: QuranStatus.error, message: e.toString());
    }
  }

  // Fetch Riwayat Progres from API
  Future<void> fetchRiwayat() async {
    try {
      logger.fine('🌐 Fetching riwayat from API...');

      state = state.copyWith(status: QuranStatus.loading, message: null);

      final result = await QuranProgresService.getProgresRiwayat();

      logger.fine('📡 API Response: $result');

      final status = result['status'] as bool;
      final message = result['message'] as String;

      if (status) {
        final dataJson = result['data'];

        logger.fine('📦 Data from API: $dataJson');

        if (dataJson != null && dataJson is List) {
          final riwayat = dataJson
              .map(
                (item) =>
                    ProgresBacaQuran.fromJson(item as Map<String, dynamic>),
              )
              .toList();

          logger.fine('✅ Parsed ${riwayat.length} riwayat items');

          // Save to cache
          await QuranCacheService.cacheRiwayat(riwayat);

          state = state.copyWith(
            status: QuranStatus.loaded,
            riwayatProgres: riwayat,
            message: message,
            isOffline: false,
          );

          logger.fine('✅ Riwayat updated successfully');
        } else {
          logger.fine('⚠️ No data in API response, using cache');
          // No riwayat from API, use cache
          final cachedRiwayat = QuranCacheService.getCachedRiwayat();
          state = state.copyWith(
            status: QuranStatus.loaded,
            riwayatProgres: cachedRiwayat,
            isOffline: true,
          );
        }
      } else {
        logger.fine('❌ API returned error: $message');
        state = state.copyWith(status: QuranStatus.error, message: message);
      }
    } catch (e) {
      logger.fine('❌ API Error: $e');

      // On error, load from cache
      final cachedRiwayat = QuranCacheService.getCachedRiwayat();

      if (cachedRiwayat.isNotEmpty) {
        state = state.copyWith(
          status: QuranStatus.loaded,
          riwayatProgres: cachedRiwayat,
          message: 'Menampilkan data offline',
          isOffline: true,
        );
        logger.fine('📱 Fallback to cache: ${cachedRiwayat.length} items');
      } else {
        state = state.copyWith(
          status: QuranStatus.error,
          message: 'Gagal memuat data: ${e.toString()}',
        );
      }
    }
  }

  // Add Progres Quran
  Future<void> addProgresQuran({
    required String suratId,
    required String ayat,
  }) async {
    try {
      logger.fine('💾 Adding progress: Surah $suratId, Ayah $ayat');

      state = state.copyWith(status: QuranStatus.loading, message: null);

      final result = await QuranProgresService.addProgresQuran(
        suratId: suratId,
        ayat: ayat,
      );

      logger.fine('📡 Add response: $result');

      final status = result['status'];
      final message = result['message'];

      if (status) {
        logger.fine('✅ Progress saved to API');

        // Create progress object
        final progres = ProgresBacaQuran(
          id: result['data']?['id'] ?? DateTime.now().millisecondsSinceEpoch,
          suratId: int.parse(suratId),
          ayat: int.parse(ayat),
          createdAt:
              result['data']?['created_at'] ?? DateTime.now().toIso8601String(),
          userId: result['data']?['user_id'] ?? 0,
          surat: result['data']?['surat'],
        );

        // Add to cache
        await QuranCacheService.addProgresToCache(progres);

        state = state.copyWith(status: QuranStatus.success, message: message);

        logger.fine('✅ Progress saved and cached');

        // Fetch latest riwayat from API
        await fetchRiwayat();
      } else {
        logger.fine('❌ API save failed: $message');
        state = state.copyWith(status: QuranStatus.error, message: message);
      }
    } catch (e) {
      logger.fine('❌ Save error: $e');

      // If offline, save to cache only
      final offlineProgress = ProgresBacaQuran(
        id: DateTime.now().millisecondsSinceEpoch,
        suratId: int.parse(suratId),
        ayat: int.parse(ayat),
        createdAt: DateTime.now().toIso8601String(),
        userId: 0,
      );

      await QuranCacheService.addProgresToCache(offlineProgress);

      // Reload from cache
      final cachedRiwayat = QuranCacheService.getCachedRiwayat();

      state = state.copyWith(
        status: QuranStatus.success,
        riwayatProgres: cachedRiwayat,
        message: 'Bookmark disimpan (offline)',
        isOffline: true,
      );

      logger.fine('💾 Saved offline: Surah $suratId, Ayah $ayat');
    }
  }

  // Delete Progres Quran
  Future<void> deleteProgresQuran(int progresId) async {
    try {
      logger.fine('🗑️ Deleting progress: id=$progresId');

      state = state.copyWith(status: QuranStatus.loading, message: null);

      final result = await QuranProgresService.deleteProgresQuran(
        progresId: progresId.toString(),
      );

      logger.fine('📡 Delete response: $result');

      final status = result['status'];
      final message = result['message'];

      if (status) {
        logger.fine('✅ Progress deleted from API');

        // Delete from cache
        await QuranCacheService.deleteProgresFromCache(progresId);

        state = state.copyWith(status: QuranStatus.success, message: message);

        logger.fine('✅ Progress deleted from cache');

        // Fetch latest riwayat from API
        await fetchRiwayat();
      } else {
        logger.fine('❌ API delete failed: $message');
        state = state.copyWith(status: QuranStatus.error, message: message);
      }
    } catch (e) {
      logger.fine('❌ Delete error: $e');

      state = state.copyWith(
        status: QuranStatus.error,
        message: 'Gagal menghapus bookmark: ${e.toString()}',
      );
    }
  }

  // Clear message
  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  // Refresh data
  Future<void> refresh() async {
    state = state.copyWith(status: QuranStatus.refreshing);
    await fetchRiwayat();
  }
}

final quranProvider = StateNotifierProvider<QuranNotifier, QuranState>(
  (ref) => QuranNotifier(),
);
