import 'package:dio/dio.dart';
import 'package:test_flutter/core/utils/api_client.dart';

class FamilyService {
  // Daftar Pengajuan Anak
  static Future<Map<String, dynamic>> getDaftarPengajuanAnak() async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/relasi-orang-tua-anak/orang-tua/pengajuan-anak',
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'];

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

  // Pengajuan Anak
  static Future<Map<String, dynamic>> pengajuanAnak({
    required String emailAnak,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/premium/relasi-orang-tua-anak/orang-tua/pengajuan-anak',
        data: {'email_anak': emailAnak},
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'];

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

  // Hapus Pengajuan Anak
  static Future<Map<String, dynamic>> deletePengajuanAnak({
    required int pengajuanId,
  }) async {
    try {
      final response = await ApiClient.dio.delete(
        '/premium/relasi-orang-tua-anak/orang-tua/pengajuan-anak/$pengajuanId',
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

  // Daftar Anak Aktif
  static Future<Map<String, dynamic>> getDaftarAnakAktif() async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/relasi-orang-tua-anak/orang-tua/anak',
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'];

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

  // Hapus Anak
  static Future<Map<String, dynamic>> deleteAnak({
    required int relasiId,
  }) async {
    try {
      final response = await ApiClient.dio.delete(
        '/premium/relasi-orang-tua-anak/orang-tua/anak/$relasiId',
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

  // Detail Orang Tua
  static Future<Map<String, dynamic>> getDetailOrangTua() async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/relasi-orang-tua-anak/anak/orang-tua',
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'];

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

  // Daftar Pengajuan Orang Tua
  static Future<Map<String, dynamic>> getDaftarPengajuanOrangTua() async {
    try {
      final response = await ApiClient.dio.get(
        '/premium/relasi-orang-tua-anak/anak/pengajuan-orang-tua',
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'];

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

  // Persetujuan Anak
  static Future<Map<String, dynamic>> persetujuanAnak({
    required int pengajuanId,
    required bool persetujuan,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/premium/relasi-orang-tua-anak/anak/persetujuan-anak/$pengajuanId',
        data: {'persetujuan': persetujuan},
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'];

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
