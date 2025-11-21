import 'package:dio/dio.dart';
import 'package:test_flutter/core/utils/api_client.dart';

class MonitoringService {
  // Get Sholat Wajib
  static Future<Map<String, dynamic>> getSholatWajib({
    required int anakId,
    required String filter, // weekly, monthly, custom (default: weekly)
    String? tanggalMulai, // Format: YYYY-MM-DD
    String? tanggalSelesai, // Format: YYYY-MM-DD
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/laporan-orang-tua/sholat-wajib',
        queryParameters: {
          'anak_id': anakId,
          'filter': filter,
          if (tanggalMulai != null) 'tanggal_mulai': tanggalMulai,
          if (tanggalSelesai != null) 'tanggal_selesai': tanggalSelesai,
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      return {'status': responseData['status'], 'data': responseData['data']};
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Get Sholat Sunnah
  static Future<Map<String, dynamic>> getSholatSunnah({
    required int anakId,
    required String filter, // weekly, monthly, custom (default: weekly)
    String? tanggalMulai, // Format: YYYY-MM-DD
    String? tanggalSelesai, // Format: YYYY-MM-DD
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/laporan-orang-tua/sholat-sunnah',
        queryParameters: {
          'anak_id': anakId,
          'filter': filter,
          if (tanggalMulai != null) 'tanggal_mulai': tanggalMulai,
          if (tanggalSelesai != null) 'tanggal_selesai': tanggalSelesai,
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      return {'status': responseData['status'], 'data': responseData['data']};
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Get Quran
  static Future<Map<String, dynamic>> getQuran({
    required int anakId,
    required String filter, // weekly, monthly, custom (default: weekly)
    String? tanggalMulai, // Format: YYYY-MM-DD
    String? tanggalSelesai, // Format: YYYY-MM-DD
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/laporan-orang-tua/quran',
        queryParameters: {
          'anak_id': anakId,
          'filter': filter,
          if (tanggalMulai != null) 'tanggal_mulai': tanggalMulai,
          if (tanggalSelesai != null) 'tanggal_selesai': tanggalSelesai,
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      return {'status': responseData['status'], 'data': responseData['data']};
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Get Tahajud Challenge
  static Future<Map<String, dynamic>> getTahajud({
    required int anakId,
    required String filter, // weekly, monthly, custom (default: weekly)
    String? tanggalMulai, // Format: YYYY-MM-DD
    String? tanggalSelesai, // Format: YYYY-MM-DD
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/laporan-orang-tua/tahajud',
        queryParameters: {
          'anak_id': anakId,
          'filter': filter,
          if (tanggalMulai != null) 'tanggal_mulai': tanggalMulai,
          if (tanggalSelesai != null) 'tanggal_selesai': tanggalSelesai,
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      return {'status': responseData['status'], 'data': responseData['data']};
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Get Puasa Wajib
  static Future<Map<String, dynamic>> getPuasaWajib({
    required int anakId,
    required String filter, // weekly, monthly, custom (default: weekly)
    String? tanggalMulai, // Format: YYYY-MM-DD
    String? tanggalSelesai, // Format: YYYY-MM-DD
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/laporan-orang-tua/puasa-wajib',
        queryParameters: {
          'anak_id': anakId,
          'filter': filter,
          if (tanggalMulai != null) 'tanggal_mulai': tanggalMulai,
          if (tanggalSelesai != null) 'tanggal_selesai': tanggalSelesai,
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      return {'status': responseData['status'], 'data': responseData['data']};
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Get Puasa Sunnah
  static Future<Map<String, dynamic>> getPuasaSunnah({
    required int anakId,
    required String filter, // weekly, monthly, custom (default: weekly)
    String? tanggalMulai, // Format: YYYY-MM-DD
    String? tanggalSelesai, // Format: YYYY-MM-DD
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/laporan-orang-tua/puasa-sunnah',
        queryParameters: {
          'anak_id': anakId,
          'filter': filter,
          if (tanggalMulai != null) 'tanggal_mulai': tanggalMulai,
          if (tanggalSelesai != null) 'tanggal_selesai': tanggalSelesai,
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      return {'status': responseData['status'], 'data': responseData['data']};
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Get Sedekah
  static Future<Map<String, dynamic>> getSedekah({
    required int anakId,
    required String filter, // weekly, monthly, custom (default: weekly)
    String? tanggalMulai, // Format: YYYY-MM-DD
    String? tanggalSelesai, // Format: YYYY-MM-DD
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/laporan-orang-tua/sedekah',
        queryParameters: {
          'anak_id': anakId,
          'filter': filter,
          if (tanggalMulai != null) 'tanggal_mulai': tanggalMulai,
          if (tanggalSelesai != null) 'tanggal_selesai': tanggalSelesai,
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      return {'status': responseData['status'], 'data': responseData['data']};
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }
}
