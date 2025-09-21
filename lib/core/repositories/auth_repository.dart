import 'package:dio/dio.dart';
import '../models/user.dart';
import '../environment/environment.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository({required Dio dio}) : _dio = dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '${EnvironmentConfig.baseUrl}/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      return {
        'success': true,
        'data': response.data['token'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'code': e.response?.data['code'],
        'message': e.response?.data['message'],
      };
    }
  }

  Future<Map<String, dynamic>> signup(String email, String password, String nickname) async {
    try {
      final response = await _dio.post(
        '${EnvironmentConfig.baseUrl}/auth/signup',
        data: {
          'email': email,
          'password': password,
          'nickname': nickname,
        },
      );

      return {
        'success': true,
        'data': User.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'code': e.response?.data['code'],
        'message': e.response?.data['message'],
      };
    }
  }

  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final response = await _dio.get(
        '${EnvironmentConfig.baseUrl}/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return {
        'success': true,
        'data': User.fromJson(response.data),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'code': e.response?.data['code'],
        'message': e.response?.data['message'],
      };
    }
  }
}