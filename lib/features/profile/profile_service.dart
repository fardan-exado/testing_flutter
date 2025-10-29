import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_flutter/core/utils/api_client.dart';

class ProfileService {
  // Update user profile
  static Future<Map<String, dynamic>> updateProfile(
    String name,
    String email,
    String? phone,
  ) async {
    try {
      final response = await ApiClient.dio.post(
        '/edit-profile',
        data: {'name': name, 'email': email, if (phone != null) 'phone': phone},
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>;

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

  // Update user password for auth method email only
  static Future<Map<String, dynamic>> updatePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final response = await ApiClient.dio.post(
        '/edit-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
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

  // Update avatar
  static Future<Map<String, dynamic>> updateAvatar({
    required XFile avatar,
  }) async {
    try {
      MultipartFile avatarImage = await MultipartFile.fromFile(
        avatar.path,
        filename: avatar.name,
      );

      FormData formData = FormData.fromMap({'avatar': avatarImage});

      final response = await ApiClient.dio.post(
        '/edit-avatar',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      final responseData = response.data as Map<String, dynamic>;
      final userData = responseData['data'];

      return {
        'status': responseData['status'],
        'message': responseData['message'],
        'data': userData,
      };
    } on DioException catch (e) {
      final error = ApiClient.parseDioError(e);
      throw Exception(error);
    }
  }
}
