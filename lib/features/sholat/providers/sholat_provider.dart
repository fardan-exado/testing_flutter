import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:test_flutter/core/constants/cache_keys.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:test_flutter/features/sholat/models/sholat/sholat.dart';
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

        state = state.copyWith(
          status: SholatStatus.loaded,
          sholatList: cachedJadwal,
          latitude: cachedLocation?['lat'] as double?,
          longitude: cachedLocation?['long'] as double?,
          locationName: cachedLocation?['name'] as String?,
          localDate: cachedLocation?['date'] as String?,
          localTime: cachedLocation?['time'] as String?,
          progressWajibRiwayat: {},
          progressSunnahRiwayat: {},
          isOffline: false,
        );
      } else if (cachedLocation != null) {
        state = state.copyWith(
          latitude: cachedLocation['lat'] as double?,
          longitude: cachedLocation['long'] as double?,
          locationName: cachedLocation['name'] as String?,
          localDate: cachedLocation['date'] as String?,
          localTime: cachedLocation['time'] as String?,
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

          final cachedLocation = await LocationService.getLocation();
          if (cachedLocation != null && cachedLocation.isNotEmpty) {
            latitude = cachedLocation['lat'] as double?;
            longitude = cachedLocation['long'] as double?;
            locationName = cachedLocation['name'] as String?;
            localDate = cachedLocation['date'] as String?;
            localTime = cachedLocation['time'] as String?;
            logger.info('Using cached location due to error');
          } else {
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
        latitude ??= state.latitude;
        longitude ??= state.longitude;
        locationName ??= state.locationName;
        localDate ??= state.localDate;
        localTime ??= state.localTime;

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

      if (latitude == null || longitude == null) {
        throw Exception('Location coordinates not available');
      }

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

      state = state.copyWith(
        status: forceRefresh ? SholatStatus.refreshing : SholatStatus.loading,
      );

      try {
        final response = await SholatService.getJadwalSholat(
          latitude: latitude,
          longitude: longitude,
        );

        final sholatList = response['data'] as List<JadwalSholat>;

        List<JadwalSholat> mergedList = [];
        if (cachedJadwal.isNotEmpty) {
          final newJadwalMap = {
            for (var item in sholatList) item.tanggal: item,
          };

          mergedList = [...sholatList];

          for (var cached in cachedJadwal) {
            if (!newJadwalMap.containsKey(cached.tanggal)) {
              mergedList.add(cached);
            }
          }

          mergedList.sort((a, b) {
            // Parse format dd-MM-yyyy to DateTime
            final dateAParts = a.tanggal.split('-');
            final dateBParts = b.tanggal.split('-');

            final dateA = DateTime(
              int.parse(dateAParts[2]), // year
              int.parse(dateAParts[1]), // month
              int.parse(dateAParts[0]), // day
            );
            final dateB = DateTime(
              int.parse(dateBParts[2]), // year
              int.parse(dateBParts[1]), // month
              int.parse(dateBParts[0]), // day
            );

            return dateA.compareTo(dateB);
          });
        } else {
          mergedList = sholatList;
        }

        await SholatCacheService.cacheJadwalSholat(mergedList);

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
          throw networkError;
        }
      }
    } catch (e) {
      logger.severe('Error fetching jadwal sholat: $e');

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
  JadwalSholat? getJadwalByDate(DateTime date) {
    final formatter = DateFormat('yyyy-MM-dd');
    final dateString = formatter.format(date);

    try {
      return state.sholatList.firstWhere(
        (jadwal) => jadwal.tanggal == dateString,
      );
    } catch (e) {
      logger.warning('Jadwal not found for date: $dateString');

      if (state.status != SholatStatus.loading &&
          state.status != SholatStatus.refreshing) {
        Future.microtask(() => _fetchMissingJadwal(date));
      }

      return null;
    }
  }

  /// Fetch jadwal yang missing di background
  Future<void> _fetchMissingJadwal(DateTime targetDate) async {
    try {
      logger.info('Fetching missing jadwal for date: $targetDate');

      if (state.status == SholatStatus.loading ||
          state.status == SholatStatus.refreshing) {
        return;
      }

      final latitude = state.latitude;
      final longitude = state.longitude;

      if (latitude == null || longitude == null) {
        logger.warning('No location available for fetching missing jadwal');
        return;
      }

      final response = await SholatService.getJadwalSholat(
        latitude: latitude,
        longitude: longitude,
        startDate: targetDate,
        endDate: targetDate,
      );

      final newJadwal = response['data'] as List<JadwalSholat>;

      final existingJadwal = state.sholatList;
      final Map<String, JadwalSholat> jadwalMap = {
        for (var item in existingJadwal) item.tanggal: item,
      };

      for (var item in newJadwal) {
        jadwalMap[item.tanggal] = item;
      }

      final mergedList = jadwalMap.values.toList();

      mergedList.sort((a, b) {
        // Parse format dd-MM-yyyy to DateTime
        final dateAParts = a.tanggal.split('-');
        final dateBParts = b.tanggal.split('-');

        final dateA = DateTime(
          int.parse(dateAParts[2]), // year
          int.parse(dateAParts[1]), // month
          int.parse(dateAParts[0]), // day
        );
        final dateB = DateTime(
          int.parse(dateBParts[2]), // year
          int.parse(dateBParts[1]), // month
          int.parse(dateBParts[0]), // day
        );

        return dateA.compareTo(dateB);
      });

      await SholatCacheService.cacheJadwalSholat(mergedList);

      state = state.copyWith(
        sholatList: mergedList,
        status: SholatStatus.loaded,
        message: 'Data updated',
      );

      logger.info('Successfully merged ${mergedList.length} jadwal items');
    } catch (e) {
      logger.warning('Failed to fetch missing jadwal: $e');
    }
  }

  /// Fetch progress sholat berdasarkan tanggal (default: hari ini)
  /// Returns Map<String, dynamic> untuk kedua jenis (wajib & sunnah)
  Future<Map<String, dynamic>> fetchProgressSholatByDate({
    required String jenis,
    DateTime? tanggal,
  }) async {
    try {
      final formatter = DateFormat('yyyy-MM-dd');
      final tanggalStr = formatter.format(tanggal ?? DateTime.now());

      logger.info('📡 Fetching progress $jenis riwayat for date: $tanggalStr');

      final response = await SholatService.getRiwayatProgressSholatByTanggal(
        jenis: jenis,
        tanggal: tanggalStr,
      );

      final progressData = response['data'];

      // Update state berdasarkan jenis
      if (jenis.toLowerCase() == 'wajib') {
        state = state.copyWith(
          progressWajibRiwayat: {tanggalStr: progressData},
        );
      } else {
        state = state.copyWith(
          progressSunnahRiwayat: {tanggalStr: progressData},
        );
      }

      logger.info('✓ Successfully fetched progress $jenis for $tanggalStr');
      return progressData;
    } catch (e) {
      logger.severe('❌ Error fetching progress $jenis: $e');
      rethrow;
    }
  }

  /// Get progress untuk tanggal tertentu dari state
  /// Jika belum ada di state, fetch dari network
  Future<Map<String, dynamic>> getProgressForDate({
    required DateTime date,
    required String jenis,
  }) async {
    final formatter = DateFormat('yyyy-MM-dd');
    final dateKey = formatter.format(date);

    // Tentukan riwayat mana yang digunakan
    final riwayat = jenis.toLowerCase() == 'wajib'
        ? state.progressWajibRiwayat
        : state.progressSunnahRiwayat;

    // Cek apakah sudah ada di state
    if (riwayat.containsKey(dateKey)) {
      logger.info('Using cached progress $jenis for $dateKey');
      return riwayat[dateKey] as Map<String, dynamic>;
    }

    // Jika belum ada, fetch dari network
    logger.info('Progress $jenis not in cache, fetching from network...');
    return await fetchProgressSholatByDate(jenis: jenis, tanggal: date);
  }

  /// Tambah progress sholat
  Future<Map<String, dynamic>?> addProgressSholat({
    required String jenis,
    required String sholat,
    required String status,
    bool? isJamaah,
    String? lokasi,
    String? keterangan,
    int? rakaat,
  }) async {
    try {
      logger.info('Adding progress sholat: $jenis - $sholat - $status');

      final response = await SholatService.addProgressSholat(
        jenis: jenis,
        sholat: sholat,
        status: status,
        isJamaah: isJamaah,
        lokasi: lokasi,
        keterangan: keterangan,
        rakaat: rakaat,
      );

      // Refresh progress hari ini setelah berhasil
      await fetchProgressSholatByDate(jenis: jenis);

      logger.info('Successfully added progress sholat');
      return response;
    } catch (e) {
      logger.severe('Error adding progress sholat: $e');
      rethrow;
    }
  }

  /// Delete progress sholat
  Future<bool> deleteProgressSholat({
    required int id,
    required String jenis,
  }) async {
    try {
      logger.info('Deleting progress sholat: ID=$id, jenis=$jenis');

      await SholatService.deleteProgressSholat(id: id, jenis: jenis);

      // Refresh progress hari ini setelah berhasil
      await fetchProgressSholatByDate(jenis: jenis);

      logger.info('Successfully deleted progress sholat');
      return true;
    } catch (e) {
      logger.severe('Error deleting progress sholat: $e');
      return false;
    }
  }

  /// Refresh jadwal sholat dengan lokasi yang sudah ada
  Future<void> refreshJadwalSholat() async {
    if (state.latitude == null || state.longitude == null) {
      logger.warning('Cannot refresh: location not available');

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

  /// Clear progress data (called on logout)
  Future<void> clearProgressData() async {
    logger.info('🗑️ Clearing progress data from state and cache...');

    try {
      await CacheService.clearCache(CacheKeys.progressSholatWajibRiwayat);
      await CacheService.clearCache(CacheKeys.progressSholatSunnahRiwayat);
      logger.info('✓ Cleared progress cache entries');
    } catch (e) {
      logger.warning('Error clearing progress cache: $e');
    }

    state = state.copyWith(
      progressWajibRiwayat: <String, dynamic>{},
      progressSunnahRiwayat: <String, dynamic>{},
    );
    logger.info('✓ Cleared progress data from state');
  }
}
