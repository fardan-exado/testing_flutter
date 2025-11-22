import 'package:dio/dio.dart';
import 'package:test_flutter/core/utils/api_client.dart';
import 'package:test_flutter/features/puasa/models/puasa.dart';

class PuasaService {
  // GET DAFTAR PUASA SUNNAH
  static Future<Map<String, dynamic>> getAllPuasaSunnah() async {
    try {
      final response = await ApiClient.dio.get('/puasa/sunnah/daftar');

      final responseData = response.data as Map<String, dynamic>;
      final puasaSunnahData = responseData['data'] as List<dynamic>? ?? [];
      final puasaSunnahList = puasaSunnahData
          .map((e) => PuasaSunnah.fromJson(e))
          .toList();

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': puasaSunnahList,
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Add Progres Puasa Wajib
  static Future<Map<String, dynamic>> addProgresPuasaWajib({
    required String tanggalRamadhan,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/puasa/wajib/progres',
        data: {'tanggal_ramadhan': tanggalRamadhan},
      );

      final responseData = response.data as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Delete Progres Puasa Wajib
  static Future<Map<String, dynamic>> deleteProgresPuasaWajib({
    required String id,
  }) async {
    try {
      final response = await ApiClient.dio.delete('/puasa/wajib/progres/$id');

      final responseData = response.data as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Get Progress Puasa Wajib Riwayat
  static Future<Map<String, dynamic>> getRiwayatPuasaWajib({
    required String tahunHijriah,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/puasa/wajib/progres',
        queryParameters: {'tahun_hijriah': tahunHijriah},
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as List<dynamic>? ?? [];

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': data,
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Add Progres Puasa Sunnah
  static Future<Map<String, dynamic>> addProgresPuasaSunnah({
    required String jenis,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/puasa/sunnah/progres',
        data: {'jenis': jenis},
      );

      final responseData = response.data as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Delete Progres Puasa Sunnah
  static Future<Map<String, dynamic>> deleteProgresPuasaSunnah({
    required String id,
  }) async {
    try {
      final response = await ApiClient.dio.delete('/puasa/sunnah/progres/$id');

      final responseData = response.data as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }

  // Get Progress Puasa Sunnah Riwayat
  static Future<Map<String, dynamic>> getRiwayatPuasaSunnah({
    required String jenis,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/puasa/sunnah/progres',
        queryParameters: {'jenis': jenis},
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as List<dynamic>? ?? [];

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': data,
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }
}
