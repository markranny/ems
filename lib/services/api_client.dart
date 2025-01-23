import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiClient {
  final String baseUrl;
  final Future<Map<String, String>> Function() getHeaders;

  ApiClient({
    required this.baseUrl,
    required this.getHeaders,
  });

  Future<T> _handleResponse<T>(Future<http.Response> Function() request) async {
    try {
      final response = await request();

      if (response.statusCode >= 500) {
        throw Exception('Server error occurred. Please try again later.');
      }

      final bodyData = json.decode(response.body);

      if (response.statusCode >= 400) {
        final message = bodyData['message'] ?? 'An error occurred';
        throw Exception(message);
      }

      return bodyData as T;
    } on FormatException {
      throw Exception('Invalid response format from server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    return _handleResponse(() async {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return response;
    });
  }

  Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    return _handleResponse(() async {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return response;
    });
  }

  Future<Map<String, dynamic>> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    return _handleResponse(() async {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return response;
    });
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    return _handleResponse(() async {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return response;
    });
  }
}
