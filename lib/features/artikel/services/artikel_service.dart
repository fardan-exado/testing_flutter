import 'package:dio/dio.dart';
import 'package:test_flutter/core/utils/api_client.dart';
import 'package:test_flutter/features/artikel/models/kategori/kategori_artikel.dart';

class ArtikelService {
  /// Mengambil semua kategori artikel
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await ApiClient.dio.get('/artikel/kategori');

      final responseData = response.data as Map<String, dynamic>;

      final kategoriArtikel = responseData['data'] as List<dynamic>? ?? [];
      final kategoriList = kategoriArtikel
          .map((e) => KategoriArtikel.fromJson(e as Map<String, dynamic>))
          .toList();

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': kategoriList,
      };
    } on DioException catch (e) {
      // Gunakan helper terpusat untuk parsing error
      final errorMessage = ApiClient.parseDioError(e);
      throw Exception(errorMessage);
    }
  }

  /// Mengambil semua artikel, dengan filter kategori opsional
  static Future<Map<String, dynamic>> getArtikels({
    int page = 1,
    String keyword = '',
    int? kategoriId,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/artikel/blog',
        queryParameters: {
          'page': page,
          'keyword': keyword,
          if (kategoriId != null) 'kategori_id': kategoriId,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      final artikels = responseData['data'] as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': artikels,
      };
    } on DioException catch (e) {
      final errorMessage = ApiClient.parseDioError(e);
      throw Exception(errorMessage);
    }
  }

  /// Mengambil satu artikel berdasarkan ID
  static Future<Map<String, dynamic>> getArtikelById(int id) async {
    try {
      final response = await ApiClient.dio.get('/artikel/blog/$id');

      final responseData = response.data as Map<String, dynamic>;
      final artikel = responseData['data'] as Map<String, dynamic>;

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': artikel,
      };
    } on DioException catch (e) {
      final errorMessage = ApiClient.parseDioError(e);
      throw Exception(errorMessage);
    }
  }
}
