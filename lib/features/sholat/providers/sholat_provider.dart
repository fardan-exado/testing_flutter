import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/core/constants/cache_keys.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/features/sholat/models/sholat.dart';
import 'package:test_flutter/data/services/cache/cache_service.dart';
import 'package:test_flutter/data/services/location/location_service.dart';
import 'package:test_flutter/features/sholat/services/sholat_cache_service.dart';
import 'package:test_flutter/features/sholat/services/sholat_service.dart';
import 'package:test_flutter/features/sholat/states/sholat_state.dart';

final sholatProvider = StateNotifierProvider<SholatProvider, SholatState>((
  ref,
) {
  return SholatProvider();
});

class SholatProvider extends StateNotifier<SholatState> {
  SholatProvider() : super(SholatState.initial()) {
    _loadCachedData();
  }

  /// Load cached data saat inisialisasi
  /// NOTE: Only loads jadwal and location, NOT progress data
  Future<void> _loadCachedData() async {
    try {
      final cachedJadwal = SholatCacheService.getCachedJadwalSholat();
      final cachedLocation = await LocationService.getLocation();

      logger.info('Loading cached sholat data...');
      logger.info('Cached jadwal: ${cachedJadwal.length} items');
      logger.info('Cached location: ${cachedLocation != null}');
      logger.info(
        '⚠️ Progress data will be fetched from database (not cached)',
      );

      if (cachedJadwal.isNotEmpty) {
        logger.info('Loaded ${cachedJadwal.length} cached jadwal sholat');

        // Update state dengan jadwal dan lokasi dari cache
        // Progress data NOT loaded from cache - will be empty initially
        state = state.copyWith(
          status: SholatStatus.loaded,
          sholatList: cachedJadwal,
          latitude: cachedLocation?['lat'] as double?,
          longitude: cachedLocation?['long'] as double?,
          locationName: cachedLocation?['name'] as String?,
          localDate: cachedLocation?['date'] as String?,
          localTime: cachedLocation?['time'] as String?,
          // Explicitly set progress to empty
          progressWajibHariIni: {},
          progressSunnahHariIni: [],
          progressWajibRiwayat: {},
          progressSunnahRiwayat: {},
          isOffline: false,
        );
      } else if (cachedLocation != null) {
        // Jika ada lokasi tapi belum ada jadwal, set lokasi saja
        state = state.copyWith(
          latitude: cachedLocation['lat'] as double?,
          longitude: cachedLocation['long'] as double?,
          locationName: cachedLocation['name'] as String?,
          localDate: cachedLocation['date'] as String?,
          localTime: cachedLocation['time'] as String?,
          // Explicitly set progress to empty
          progressWajibHariIni: {},
          progressSunnahHariIni: [],
          progressWajibRiwayat: {},
          progressSunnahRiwayat: {},
        );
        logger.info('Loaded cached location, no jadwal available');
      } else {
        logger.warning('No cached data available');
      }
    } catch (e) {
      logger.severe('Error loading cached data: $e');
    }
  }

  /// Fetch jadwal sholat dengan strategi cache-first-then-network
  ///
  /// Mengambil jadwal waktu sholat dari API Kemenag melalui backend.
  /// Menggunakan strategi cache-first untuk performa optimal:
  /// 1. Cek cache terlebih dahulu
  /// 2. Jika cache kosong atau force refresh, ambil dari network
  /// 3. Gabungkan data network dengan cache untuk melengkapi data
  ///
  /// Waktu sholat diambil dari API resmi Kementerian Agama RI
  /// yang telah diintegrasikan di backend untuk akurasi tinggi.
  Future<void> fetchJadwalSholat({
    double? latitude,
    double? longitude,
    String? locationName,
    String? localDate,
    String? localTime,
    bool forceRefresh = false,
    bool useCurrentLocation = false,
  }) async {
    try {
      // Jika useCurrentLocation = true, ambil lokasi real-time
      if (useCurrentLocation) {
        logger.info('Fetching current location...');
        state = state.copyWith(status: SholatStatus.loading);

        try {
          final locationData = await LocationService.getCurrentLocation(
            forceRefresh: forceRefresh,
          );
          latitude = locationData['lat'] as double?;
          longitude = locationData['long'] as double?;
          locationName = locationData['name'] as String?;
          localDate = locationData['date'] as String?;
          localTime = locationData['time'] as String?;

          logger.info(
            'Location obtained: $locationName ($latitude, $longitude) | $localDate $localTime',
          );
        } catch (e) {
          logger.warning('Failed to get current location: $e');

          // Fallback ke cache location
          final cachedLocation = await LocationService.getLocation();
          if (cachedLocation != null && cachedLocation.isNotEmpty) {
            latitude = cachedLocation['lat'] as double?;
            longitude = cachedLocation['long'] as double?;
            locationName = cachedLocation['name'] as String?;
            localDate = cachedLocation['date'] as String?;
            localTime = cachedLocation['time'] as String?;
            logger.info('Using cached location due to error');
          } else {
            // Jika tidak ada lokasi sama sekali, gunakan cache jadwal yang ada
            final cachedJadwal = SholatCacheService.getCachedJadwalSholat();
            if (cachedJadwal.isNotEmpty) {
              state = state.copyWith(
                status: SholatStatus.offline,
                sholatList: cachedJadwal,
                isOffline: true,
                message: 'Menggunakan data offline',
              );
              return;
            }
            throw Exception('No location data available');
          }
        }
      } else {
        // Jika tidak ada parameter, gunakan dari state atau cache
        latitude ??= state.latitude;
        longitude ??= state.longitude;
        locationName ??= state.locationName;
        localDate ??= state.localDate;
        localTime ??= state.localTime;

        // Jika masih null, ambil dari cache
        if (latitude == null || longitude == null) {
          final cachedLocation = await LocationService.getLocation();
          if (cachedLocation != null && cachedLocation.isNotEmpty) {
            latitude = cachedLocation['lat'] as double?;
            longitude = cachedLocation['long'] as double?;
            locationName = cachedLocation['name'] as String?;
            localDate = cachedLocation['date'] as String?;
            localTime = cachedLocation['time'] as String?;
            logger.info('Using cached location');
          }
        }

        // Jika masih null, ambil lokasi saat ini
        if (latitude == null || longitude == null) {
          logger.info('No location available, fetching current location...');
          try {
            final locationData = await LocationService.getCurrentLocation();
            latitude = locationData['lat'] as double?;
            longitude = locationData['long'] as double?;
            locationName = locationData['name'] as String?;
            localDate = locationData['date'] as String?;
            localTime = locationData['time'] as String?;
          } catch (e) {
            logger.severe('Failed to get any location: $e');

            // Jika gagal total, gunakan data cache yang ada
            final cachedJadwal = SholatCacheService.getCachedJadwalSholat();
            if (cachedJadwal.isNotEmpty) {
              state = state.copyWith(
                status: SholatStatus.offline,
                sholatList: cachedJadwal,
                isOffline: true,
                message: 'Menggunakan data offline',
              );
              return;
            }
            throw Exception('No location or cached data available');
          }
        }
      }

      // Validasi bahwa kita punya koordinat
      if (latitude == null || longitude == null) {
        throw Exception('Location coordinates not available');
      }

      // Cek cache terlebih dahulu jika tidak force refresh
      final cachedJadwal = SholatCacheService.getCachedJadwalSholat();
      if (!forceRefresh && cachedJadwal.isNotEmpty) {
        logger.info(
          'Using cached jadwal sholat (${cachedJadwal.length} items)',
        );
        state = state.copyWith(
          status: SholatStatus.loaded,
          sholatList: cachedJadwal,
          latitude: latitude,
          longitude: longitude,
          locationName: locationName,
          localDate: localDate,
          localTime: localTime,
          isOffline: false,
          message: 'Data dimuat dari cache',
        );
        return;
      }

      // Set loading state
      state = state.copyWith(
        status: forceRefresh ? SholatStatus.refreshing : SholatStatus.loading,
      );

      try {
        // Fetch dari network
        final response = await SholatService.getJadwalSholat(
          latitude: latitude,
          longitude: longitude,
        );

        final sholatList = response['data'] as List<Sholat>;

        // Gabungkan dengan cache yang sudah ada (jika ada)
        List<Sholat> mergedList = [];
        if (cachedJadwal.isNotEmpty) {
          // Buat map untuk efisiensi lookup
          final newJadwalMap = {
            for (var item in sholatList) item.tanggal: item,
          };

          // Gabungkan: prioritaskan data baru, tapi simpan data lama jika tidak ada data baru
          mergedList = [...sholatList];

          // Tambahkan data cache yang tidak ada di data baru
          for (var cached in cachedJadwal) {
            if (!newJadwalMap.containsKey(cached.tanggal)) {
              mergedList.add(cached);
            }
          }

          // Sort by date
          mergedList.sort((a, b) {
            final dateA = DateTime.parse(
              a.tanggal.split('-').reversed.join('-'),
            );
            final dateB = DateTime.parse(
              b.tanggal.split('-').reversed.join('-'),
            );
            return dateA.compareTo(dateB);
          });
        } else {
          mergedList = sholatList;
        }

        // Cache the merged data
        await SholatCacheService.cacheJadwalSholat(mergedList);

        // Update state with network data
        state = state.copyWith(
          status: SholatStatus.loaded,
          sholatList: mergedList,
          latitude: latitude,
          longitude: longitude,
          locationName: locationName,
          localDate: localDate,
          localTime: localTime,
          isOffline: false,
          message: 'Jadwal sholat berhasil diperbarui',
        );

        logger.info(
          'Successfully fetched and cached ${mergedList.length} jadwal sholat',
        );
      } catch (networkError) {
        logger.warning(
          'Network error, trying to fetch missing data: $networkError',
        );

        // Jika network error dan ada cache, coba fetch data yang missing
        if (cachedJadwal.isNotEmpty) {
          logger.info('Using cached data with ${cachedJadwal.length} items');
          state = state.copyWith(
            status: SholatStatus.offline,
            sholatList: cachedJadwal,
            latitude: latitude,
            longitude: longitude,
            locationName: locationName,
            localDate: localDate,
            localTime: localTime,
            isOffline: true,
            message: 'Menggunakan data offline',
          );
        } else {
          throw networkError; // Re-throw jika tidak ada cache sama sekali
        }
      }
    } catch (e) {
      logger.severe('Error fetching jadwal sholat: $e');

      // Final fallback to cache
      final cachedJadwal = SholatCacheService.getCachedJadwalSholat();
      final cachedLocation = await LocationService.getLocation();

      if (cachedJadwal.isNotEmpty ||
          (cachedLocation != null && cachedLocation.isNotEmpty)) {
        logger.info('Using cached data due to error');

        state = state.copyWith(
          status: SholatStatus.offline,
          sholatList: cachedJadwal,
          latitude: cachedLocation != null
              ? (cachedLocation['lat'] as double?)
              : state.latitude,
          longitude: cachedLocation != null
              ? (cachedLocation['long'] as double?)
              : state.longitude,
          locationName: cachedLocation != null
              ? (cachedLocation['name'] as String?)
              : state.locationName ?? 'Unknown Location',
          localDate: cachedLocation != null
              ? (cachedLocation['date'] as String?)
              : state.localDate,
          localTime: cachedLocation != null
              ? (cachedLocation['time'] as String?)
              : state.localTime,
          isOffline: true,
          message: 'Menggunakan data offline',
        );
      } else {
        logger.warning('No cached data available');
        state = state.copyWith(
          status: SholatStatus.error,
          locationName: state.locationName ?? 'Unknown Location',
          isOffline: true,
          message: 'Gagal mengambil jadwal sholat: $e',
        );
      }
    }
  }

  /// Get jadwal untuk tanggal tertentu
  Sholat? getJadwalByDate(DateTime date) {
    final formatter = DateFormat('dd-MM-yyyy');
    final dateString = formatter.format(date);

    try {
      return state.sholatList.firstWhere(
        (jadwal) => jadwal.tanggal == dateString,
      );
    } catch (e) {
      logger.warning('Jadwal not found for date: $dateString');

      // Coba fetch dari database jika tidak ada di cache
      if (state.status != SholatStatus.loading &&
          state.status != SholatStatus.refreshing) {
        // Trigger background fetch without blocking UI
        Future.microtask(() => _fetchMissingJadwal(date));
      }

      return null;
    }
  }

  /// Fetch jadwal yang missing di background
  Future<void> _fetchMissingJadwal(DateTime targetDate) async {
    try {
      logger.info('Fetching missing jadwal for date: $targetDate');

      // Jangan fetch jika sudah loading
      if (state.status == SholatStatus.loading ||
          state.status == SholatStatus.refreshing) {
        return;
      }

      // Ambil location yang sudah ada
      final latitude = state.latitude;
      final longitude = state.longitude;

      if (latitude == null || longitude == null) {
        logger.warning('No location available for fetching missing jadwal');
        return;
      }

      // Fetch data dari server
      final response = await SholatService.getJadwalSholat(
        latitude: latitude,
        longitude: longitude,
        startDate: targetDate,
        endDate: targetDate,
      );

      final newJadwal = response['data'] as List<Sholat>;

      // Gabungkan dengan data yang sudah ada
      final existingJadwal = state.sholatList;
      final Map<String, Sholat> jadwalMap = {
        for (var item in existingJadwal) item.tanggal: item,
      };

      // Update dengan data baru
      for (var item in newJadwal) {
        jadwalMap[item.tanggal] = item;
      }

      final mergedList = jadwalMap.values.toList();

      // Sort by date
      mergedList.sort((a, b) {
        final dateA = DateTime.parse(a.tanggal.split('-').reversed.join('-'));
        final dateB = DateTime.parse(b.tanggal.split('-').reversed.join('-'));
        return dateA.compareTo(dateB);
      });

      // Update cache dan state
      await SholatCacheService.cacheJadwalSholat(mergedList);

      state = state.copyWith(
        sholatList: mergedList,
        status: SholatStatus.loaded,
        message: 'Data updated',
      );

      logger.info('Successfully merged ${mergedList.length} jadwal items');
    } catch (e) {
      logger.warning('Failed to fetch missing jadwal: $e');
      // Tidak perlu throw error, ini background process
    }
  }

  /// Get progress untuk tanggal tertentu (UPDATED)
  /// For wajib: returns Map<String, dynamic>
  /// For sunnah today: converts List to Map for compatibility
  Future<Map<String, dynamic>> getProgressForDate(
    DateTime date,
    String jenis,
  ) async {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (isToday) {
      if (jenis == 'wajib') {
        // Wajib: return Map directly
        final progressData = state.progressWajibHariIni;
        if (progressData.isEmpty) {
          await fetchProgressSholatWajibHariIni(forceRefresh: true);
          return state.progressWajibHariIni;
        }
        return progressData;
      } else {
        // Sunnah: convert List to Map for compatibility
        final progressList = state.progressSunnahHariIni;
        if (progressList.isEmpty) {
          await fetchProgressSholatSunnahHariIni(forceRefresh: true);
        }
        // Convert list to map { slug: { sholat_sunnah, progres } }
        final Map<String, dynamic> progressMap = {};
        for (var item in state.progressSunnahHariIni) {
          if (item is Map<String, dynamic>) {
            final sholat = item['sholat_sunnah'] as Map<String, dynamic>?;
            if (sholat != null) {
              final slug = sholat['slug'] as String;
              progressMap[slug] = item;
            }
          }
        }
        return progressMap;
      }
    } else {
      // Ambil dari riwayat berdasarkan tanggal
      final formatter = DateFormat('yyyy-MM-dd');
      final dateKey = formatter.format(date);

      final riwayat = jenis == 'wajib'
          ? state.progressWajibRiwayat
          : state.progressSunnahRiwayat;

      // Jika cache kosong, fetch dari network
      if (riwayat.isEmpty) {
        if (jenis == 'wajib') {
          await fetchProgressSholatWajibRiwayat(forceRefresh: true);
        } else {
          await fetchProgressSholatSunnahRiwayat(forceRefresh: true);
        }
        // Return updated data
        final updatedRiwayat = jenis == 'wajib'
            ? state.progressWajibRiwayat
            : state.progressSunnahRiwayat;
        return (updatedRiwayat[dateKey] as Map<String, dynamic>?) ?? {};
      }

      // Riwayat berstruktur: { 'date': { 'subuh': {...}, 'dzuhur': {...} } }
      return (riwayat[dateKey] as Map<String, dynamic>?) ?? {};
    }
  }

  /// Tambah progress sholat (wajib atau sunnah)
  Future<Map<String, dynamic>?> addProgressSholat({
    required String jenis,
    required String sholat,
    required String status,
    bool? isJamaah,
    String? lokasi,
    String? keterangan,
    int? sunnahId,
  }) async {
    try {
      logger.info(
        'Adding progress sholat: $jenis - $sholat - $status${sunnahId != null ? " (sunnahId: $sunnahId)" : ""}',
      );

      // 1. Kirim ke network
      final response = await SholatService.addProgressSholat(
        jenis: jenis,
        sholat: sholat,
        status: status,
        isJamaah: isJamaah,
        lokasi: lokasi,
        keterangan: keterangan,
        sunnahId: sunnahId,
      );

      // 2. Refresh progress setelah berhasil menambahkan
      if (jenis.toLowerCase() == 'wajib') {
        await Future.wait([
          fetchProgressSholatWajibHariIni(forceRefresh: true),
          fetchProgressSholatWajibRiwayat(forceRefresh: true),
        ]);
      } else {
        await Future.wait([
          fetchProgressSholatSunnahHariIni(forceRefresh: true),
          fetchProgressSholatSunnahRiwayat(forceRefresh: true),
        ]);
      }

      logger.info('Successfully added progress sholat');
      return response;
    } catch (e) {
      logger.severe('Error adding progress sholat: $e');
      rethrow;
    }
  }

  // Delete progress sholat
  Future<bool> deleteProgressSholat({
    required int id,
    required String jenis,
  }) async {
    try {
      logger.info('Deleting progress sholat: ID=$id, jenis=$jenis');

      // 1. Kirim ke network
      await SholatService.deleteProgressSholat(id: id, jenis: jenis);

      // 2. Refresh progress setelah berhasil menghapus
      if (jenis.toLowerCase() == 'wajib') {
        await Future.wait([
          fetchProgressSholatWajibHariIni(forceRefresh: true),
          fetchProgressSholatWajibRiwayat(forceRefresh: true),
        ]);
      } else {
        await Future.wait([
          fetchProgressSholatSunnahHariIni(forceRefresh: true),
          fetchProgressSholatSunnahRiwayat(forceRefresh: true),
        ]);
      }

      logger.info('Successfully deleted progress sholat');
      return true;
    } catch (e) {
      logger.severe('Error deleting progress sholat: $e');
      return false;
    }
  }

  /// Fetch progress sholat wajib hari ini - ALWAYS from database (no cache)
  Future<void> fetchProgressSholatWajibHariIni({
    bool forceRefresh = false,
  }) async {
    try {
      logger.info('📡 Fetching progress wajib hari ini from database...');

      // Always fetch from network - no cache check, no cache fallback
      final response = await SholatService.getProgressSholatWajibHariIni();
      final progressData = response['data'] as Map<String, dynamic>;

      // Update state directly (no caching)
      state = state.copyWith(
        progressWajibHariIni: progressData,
        isOffline: false,
      );

      logger.info('✓ Successfully fetched progress wajib from database');
      logger.info('Total: ${progressData['total'] ?? 0}/5');
    } catch (e) {
      logger.severe('❌ Error fetching progress wajib: $e');

      // Set to empty on error (no cache fallback)
      state = state.copyWith(progressWajibHariIni: {}, isOffline: true);

      rethrow; // Re-throw to let caller handle
    }
  }

  /// Fetch progress sholat sunnah hari ini - ALWAYS from database (no cache)
  Future<void> fetchProgressSholatSunnahHariIni({
    bool forceRefresh = false,
  }) async {
    try {
      logger.info('📡 Fetching progress sunnah hari ini from database...');

      // Always fetch from network - no cache check, no cache fallback
      final response = await SholatService.getProgressSholatSunnahHariIni();
      final rawData = response['data'];

      logger.info('Raw sunnah data type: ${rawData.runtimeType}');
      logger.info('Raw sunnah data: $rawData');

      // FIX: Handle type casting properly
      List<dynamic> progressData;
      if (rawData is List) {
        // Already a list - use directly
        progressData = rawData;
      } else if (rawData is Map<String, dynamic>) {
        // If Map, might be empty state or error - convert to empty list
        logger.warning('⚠️ Expected List but got Map: $rawData');
        progressData = [];
      } else {
        // Unknown type - default to empty
        logger.warning('⚠️ Unknown data type: ${rawData.runtimeType}');
        progressData = [];
      }

      // Update state directly (no caching)
      state = state.copyWith(
        progressSunnahHariIni: progressData,
        isOffline: false,
      );

      final completedCount = progressData
          .where((item) => item['progres'] == true)
          .length;
      logger.info('✓ Successfully fetched progress sunnah from database');
      logger.info('Total: $completedCount/${progressData.length}');
    } catch (e) {
      logger.severe('❌ Error fetching progress sunnah: $e');

      // Set to empty on error (no cache fallback)
      state = state.copyWith(progressSunnahHariIni: [], isOffline: true);

      rethrow; // Re-throw to let caller handle
    }
  }

  /// Fetch progress sholat wajib riwayat dengan strategi network-first-then-cache
  Future<void> fetchProgressSholatWajibRiwayat({
    bool forceRefresh = false,
  }) async {
    // Jika sudah ada data dan bukan force refresh, skip
    if (!forceRefresh && state.progressWajibRiwayat.isNotEmpty) {
      logger.info('Using existing progress wajib riwayat data');
      return;
    }

    try {
      logger.info('📡 Fetching progress wajib riwayat from database...');

      // Always fetch from network - no cache
      final response = await SholatService.getProgressSholatWajibRiwayat();
      final progressData = response['data'] as Map<String, dynamic>;

      // Update state directly (no caching)
      state = state.copyWith(
        progressWajibRiwayat: progressData,
        isOffline: false,
      );

      logger.info('✓ Successfully fetched progress wajib riwayat');
      logger.info('Total dates: ${progressData.keys.length}');
    } catch (e) {
      logger.severe('❌ Error fetching progress wajib riwayat: $e');

      // Set to empty on error
      state = state.copyWith(progressWajibRiwayat: {}, isOffline: true);

      rethrow;
    }
  }

  /// Fetch progress sholat sunnah riwayat - ALWAYS from database (no cache)
  Future<void> fetchProgressSholatSunnahRiwayat({
    bool forceRefresh = false,
  }) async {
    try {
      logger.info('📡 Fetching progress sunnah riwayat from database...');

      // Always fetch from network - no cache
      final response = await SholatService.getProgressSholatSunnahRiwayat();
      final progressData = response['data'] as Map<String, dynamic>;

      // Update state directly (no caching)
      state = state.copyWith(
        progressSunnahRiwayat: progressData,
        isOffline: false,
      );

      logger.info('✓ Successfully fetched progress sunnah riwayat');
      logger.info('Total dates: ${progressData.keys.length}');
    } catch (e) {
      logger.severe('❌ Error fetching progress sunnah riwayat: $e');

      // Set to empty on error
      state = state.copyWith(progressSunnahRiwayat: {}, isOffline: true);

      rethrow;
    }
  }

  /// Refresh semua data progress
  Future<void> refreshAllProgress() async {
    await Future.wait([
      fetchProgressSholatWajibHariIni(forceRefresh: true),
      fetchProgressSholatSunnahHariIni(forceRefresh: true),
      fetchProgressSholatWajibRiwayat(forceRefresh: true),
      fetchProgressSholatSunnahRiwayat(forceRefresh: true),
    ]);
  }

  /// Refresh jadwal sholat dengan lokasi yang sudah ada
  Future<void> refreshJadwalSholat() async {
    if (state.latitude == null || state.longitude == null) {
      logger.warning('Cannot refresh: location not available');

      // Coba ambil dari cache
      final cachedLocation = await LocationService.getLocation();
      if (cachedLocation == null) {
        logger.warning(
          'No cached location available, will fetch current location',
        );
        await fetchJadwalSholat(useCurrentLocation: true);
        return;
      }
    }

    await fetchJadwalSholat(
      latitude: state.latitude,
      longitude: state.longitude,
      locationName: state.locationName,
      localDate: state.localDate,
      localTime: state.localTime,
      forceRefresh: true,
    );
  }

  /// Update lokasi dan fetch jadwal baru
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required String locationName,
    String? localDate,
    String? localTime,
  }) async {
    logger.info('Updating location to: $locationName ($latitude, $longitude)');

    // Fetch jadwal dengan lokasi baru
    await fetchJadwalSholat(
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      localDate: localDate,
      localTime: localTime,
      forceRefresh: true,
    );
  }

  /// Gunakan lokasi saat ini
  Future<void> useCurrentLocation() async {
    await fetchJadwalSholat(useCurrentLocation: true);
  }

  /// Clear all cache
  Future<void> clearCache() async {
    await SholatCacheService.clearCache();
    await LocationService.clear();
    state = SholatState.initial();
    logger.info('Cleared all sholat cache and location');
  }

  /// Clear progress data and cache (called on logout)
  Future<void> clearProgressData() async {
    logger.info('🗑️ Clearing progress data from state and cache...');

    // Clear cache first using CacheService.clearCache (proper deletion)
    try {
      await CacheService.clearCache(CacheKeys.progressSholatWajibHariIni);
      await CacheService.clearCache(CacheKeys.progressSholatSunnahHariIni);
      await CacheService.clearCache(CacheKeys.progressSholatWajibRiwayat);
      await CacheService.clearCache(CacheKeys.progressSholatSunnahRiwayat);
      logger.info('✓ Cleared progress cache entries');
    } catch (e) {
      logger.warning('Error clearing progress cache: $e');
    }

    // Then clear state (set to empty explicitly)
    state = state.copyWith(
      progressWajibHariIni: <String, dynamic>{},
      progressSunnahHariIni: [], // List kosong untuk sunnah
      progressWajibRiwayat: <String, dynamic>{},
      progressSunnahRiwayat: <String, dynamic>{},
    );
    logger.info('✓ Cleared progress data from state');
  }
}
