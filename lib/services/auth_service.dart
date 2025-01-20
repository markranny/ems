import 'package:dio/dio.dart';
import '../config/api_config.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    headers: ApiConfig.headers,
    connectTimeout: ApiConfig.timeoutDuration,
  ));

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await _dio.post('/register', data: {
        'username': username,
        'email': email,
        'password': password,
        'role': role,
        if (additionalData != null) ...additionalData,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      return error.response?.data['message'] ?? 'An error occurred';
    }
    return 'Network error occurred';
  }
}
