import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool get isAuthenticated => _user != null;
  User? get user => _user;

  Future<void> login(String email, String password) async {
    try {
      final response =
          await AuthService().login(email: email, password: password);
      _user = User.fromJson(response['user']);
      await _saveToken(response['access_token']);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _user = null;
    await _removeToken();
    notifyListeners();
  }

  Future<void> addStudent(
      String fullName, int? collegeId, int? departmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception("User is not authenticated");
      }

      final url = Uri.parse('https://http://127.0.0.1:8000/api/students');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'fullname': fullName,
          'college_id': collegeId,
          'department_id': departmentId,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception(
            'Failed to add student: ${json.decode(response.body)['message']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
