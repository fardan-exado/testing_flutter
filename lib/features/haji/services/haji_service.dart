import 'package:dio/dio.dart';
import 'package:test_flutter/core/utils/api_client.dart';

class HajiService {

  /// Mengambil semua artikel, dengan filter kategori opsional
  static Future<Map<String, dynamic>> getHajis({
    int page = 1,
    String keyword = '',
    int? kategoriId,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/haji/blog',
        queryParameters: {
          'page': page,
          'keyword': keyword,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      final hajis = responseData['data'] as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': hajis,
      };
    } on DioException catch (e) {
      final errorMessage = ApiClient.parseDioError(e);
      throw Exception(errorMessage);
    }
  }

  /// Mengambil satu haji berdasarkan ID
  static Future<Map<String, dynamic>> getHajiById(int id) async {
    try {
      final response = await ApiClient.dio.get('/haji/blog/$id');

      final responseData = response.data as Map<String, dynamic>;
      final haji = responseData['data'] as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': haji,
      };
    } on DioException catch (e) {
      final errorMessage = ApiClient.parseDioError(e);
      throw Exception(errorMessage);
    }
  }
}
