import 'package:dio/dio.dart';
import 'package:test_flutter/core/utils/api_client.dart';

class QuranProgresService {
  // Add Progres Quran
  static Future<Map<String, dynamic>> addProgresQuran({
    required String suratId,
    required String ayat,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/quran/progres-baca',
        data: {'surat_id': suratId, 'ayat': ayat},
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

  // Get Progress Baca Terakhir
  static Future<Map<String, dynamic>> getProgresBacaTerakhir() async {
    try {
      final response = await ApiClient.dio.get('/quran/progres-baca/terakhir');

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

  // Get Progress Riwayat
  static Future<Map<String, dynamic>> getProgresRiwayat() async {
    try {
      final response = await ApiClient.dio.get('/quran/progres-baca/riwayat');

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

  // Delete Progres Quran
  static Future<Map<String, dynamic>> deleteProgresQuran({
    required String progresId,
  }) async {
    try {
      final response = await ApiClient.dio.delete(
        '/quran/progres-baca/$progresId',
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
}
