import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path; // Add this import
import 'package:http_parser/http_parser.dart'; // Make sure this is also added
import 'package:intl/intl.dart'; // Add this for date formatting
import '../models/user.dart';
import '../models/colleges.dart';
import '../models/departments.dart';
import '../models/students.dart';
import '../models/executives.dart';
import '../models/faculty.dart';
import '../services/auth_service.dart';
import '../models/events.dart';
import '../models/location.dart';
import '../models/EventResponse.dart';
import '../models/EventNotification.dart';
import '../models/survey.dart';

class AuthProvider with ChangeNotifier {
  List<EventNotification> _notifications = [];

  List<EventNotification> get notifications => _notifications;
  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  // Add these new properties
  bool _isLoadingNotifications = false;
  String? _notificationError;

  bool get isLoadingNotifications => _isLoadingNotifications;
  String? get notificationError => _notificationError;

  User? _user;
  bool _loading = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _loading;
  String? get error => _error;

  final String baseUrl = 'https://eljincorp.com';
  /*  final String baseUrl = 'http://10.151.5.239:8080'; */
  /* final String baseUrl = 'http://127.0.0.1:8000'; */

  // Token Management
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      throw Exception("Error accessing secure storage: $e");
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("User is not authenticated");
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers':
          'Origin, Content-Type, X-Auth-Token, Authorization',
      'Access-Control-Allow-Credentials': 'true',
    };
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

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

  Future<List<User>> fetchPendingAdminRequests() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/pending-admin-requests'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      if (response.statusCode == 403) {
        throw Exception('Unauthorized access');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load pending requests: ${response.body}');
      }

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true || jsonResponse['data'] == null) {
        throw Exception(
            jsonResponse['message'] ?? 'Failed to load pending requests');
      }

      final List<dynamic> usersJson = jsonResponse['data'];
      return usersJson.map((userJson) => User.fromJson(userJson)).toList();
    } catch (e, stackTrace) {
      print('Error in fetchPendingAdminRequests: $e');
      print('Stack trace: $stackTrace');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> approveAdminRequest(int userId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();

      print('Approving admin request for user ID: $userId');

      final response = await http.put(
        Uri.parse('$baseUrl/api/approve-admin-request/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      print('Approval response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to approve admin request');
      }

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw Exception(
            jsonResponse['message'] ?? 'Failed to approve admin request');
      }
    } catch (e, stackTrace) {
      print('Error in approveAdminRequest: $e');
      print('Stack trace: $stackTrace');
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> rejectAdminRequest(int userId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();

      // Debug print
      print('Rejecting admin request for user ID: $userId');
      print('Headers: $headers');

      final response = await http.post(
        Uri.parse('$baseUrl/api/reject-admin-request/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      // Debug print
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 403) {
        throw Exception('Unauthorized to reject this user');
      }

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to reject admin request');
      }

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw Exception(
            jsonResponse['message'] ?? 'Failed to reject admin request');
      }
    } catch (e, stackTrace) {
      print('Error in rejectAdminRequest: $e');
      print('Stack trace: $stackTrace');
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String username,
    required String description,
    required String adminType,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Prepare request body
      final Map<String, dynamic> body = {
        'email': email,
        'password': password,
        'username': username,
        'description': description,
        'admin_type': adminType,
      };

      // Debug print the request
      print('Request URL: $baseUrl/api/register');
      print('Request Headers: $headers');
      print('Request Body: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode(body),
      );

      // Debug print the response
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // Registration successful
          _loading = false;
          notifyListeners();
          return;
        } else {
          throw Exception(responseData['message'] ?? 'Registration failed');
        }
      } else {
        final errorData = json.decode(response.body);
        if (errorData['errors'] != null) {
          // If there are validation errors, format them nicely
          final errors = (errorData['errors'] as Map<String, dynamic>)
              .entries
              .map((e) => '${e.key}: ${(e.value as List).join(', ')}')
              .join('\n');
          throw Exception(errors);
        } else {
          throw Exception(errorData['message'] ?? 'Registration failed');
        }
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Check authentication status
  Future<void> checkAuth() async {
    try {
      final token = await _getToken();
      if (token == null) {
        _user = null;
        notifyListeners();
        return;
      }

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/user'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      if (response.statusCode == 200) {
        _user = User.fromJson(json.decode(response.body));
        notifyListeners();
      } else {
        await _removeToken();
        _user = null;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _user = null;
      await _removeToken();
      notifyListeners();
    }
  }

  Future<List<Students>> fetchStudents() async {
    try {
      _loading = true;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/students'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> studentsJson = responseData['data'];

        // Debug the response
        print('Response data: ${response.body}');

        return studentsJson.map((json) {
          try {
            return Students.fromJson(json);
          } catch (e) {
            print('Error parsing student: $e');
            rethrow;
          }
        }).toList();
      } else {
        throw Exception('Failed to load students: ${response.body}');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error fetching students: $e');
    }
  }

  // Data Fetching Methods
  Future<List<Colleges>> fetchColleges() async {
    try {
      _loading = true;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/colleges'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final List<dynamic> collegesJson = json.decode(response.body)['data'];
        return collegesJson.map((json) => Colleges.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load colleges: ${response.body}');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error fetching colleges: $e');
    }
  }

  Future<List<Departments>> fetchDepartments() async {
    try {
      _loading = true;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/departments'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final List<dynamic> departmentsJson =
            json.decode(response.body)['data'];
        return departmentsJson
            .map((json) => Departments.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load departments: ${response.body}');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error fetching departments: $e');
    }
  }

  // Error Handling
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse('$baseUrl/api/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to reset password: ${json.decode(response.body)['message']}',
        );
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update User Profile
  Future<void> updateProfile(Map<String, dynamic> userData) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        _user = User.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to update profile: ${json.decode(response.body)['message']}',
        );
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Change Password
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to change password: ${json.decode(response.body)['message']}',
        );
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Student Management
  Future<void> addStudent(
      String fullName, String email, int? collegeId, int? departmentId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/students'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode({
          'fullname': fullName,
          'email': email,
          'college_id': collegeId,
          'department_id': departmentId,
        }),
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to add student: ${json.decode(response.body)['message']}',
        );
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addCollege(String collegeName) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/colleges'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode({
          'college': collegeName,
        }),
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to add college: ${json.decode(response.body)['message']}',
        );
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addDepartment(String description) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/departments'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode({
          'description': description,
        }),
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to add department: ${json.decode(response.body)['message']}',
        );
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDepartmentDescription(int id, String description) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/departments/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode({
          'description': description,
        }),
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update department: ${json.decode(response.body)['message']}');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteDepartment(int id) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/departments/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete department: ${json.decode(response.body)['message']}');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCollegeName(int id, String collegeName) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/colleges/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode({
          'college': collegeName,
        }),
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update college: ${json.decode(response.body)['message']}',
        );
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCollege(int id) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/colleges/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete college: ${json.decode(response.body)['message']}',
        );
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // In auth_provider.dart
  Future<void> updateStudent(
    int id,
    String fullName,
    String email,
    int collegeId,
    int departmentId,
    String? password,
  ) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();

      final Map<String, dynamic> body = {
        'fullname': fullName,
        'email': email,
        'college_id': collegeId,
        'department_id': departmentId,
      };

      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/students/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update student');
      }

      // Parse the response to update local data if needed
      final responseData = json.decode(response.body);
      print('Update response: $responseData'); // Debug print

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/students/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete student: ${json.decode(response.body)['message']}',
        );
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Executives>> fetchExecutives() async {
    try {
      _loading = true;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/executives'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> executivesJson = responseData['data'];

        // Debug the response
        print('Response data: ${response.body}');

        return executivesJson.map((json) {
          try {
            return Executives.fromJson(json);
          } catch (e) {
            print('Error parsing executive: $e');
            rethrow;
          }
        }).toList();
      } else {
        throw Exception('Failed to load executives: ${response.body}');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error fetching executives: $e');
    }
  }

  Future<void> addExecutive(String description, String email) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();

      // Ensure the request body matches exactly what Laravel expects
      final Map<String, dynamic> body = {
        'description': description,
        'email': email,
      };

      print('Request body: ${json.encode(body)}'); // Debug print

      final response = await http.post(
        Uri.parse('$baseUrl/api/executives'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode(body),
      );

      print('Response status: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print

      if (response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add executive');
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Failed to add executive: $e');
    }
  }

  // Update existing executive
  Future<void> updateExecutive(
    int id,
    String description,
    String email, {
    String? password,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();

      final Map<String, dynamic> body = {
        'description': description,
        'email': email,
      };

      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/executives/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update executive');
      }

      // Parse and log the response for debugging
      final responseData = json.decode(response.body);
      print('Update response: $responseData');

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete executive
  Future<void> deleteExecutive(int id) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/executives/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete executive: ${json.decode(response.body)['message']}',
        );
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get single executive
  Future<Executives> getExecutive(int id) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/executives/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Executives.fromJson(responseData['data']);
      } else {
        throw Exception(
          'Failed to get executive: ${json.decode(response.body)['message']}',
        );
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Faculty>> fetchFaculty() async {
    try {
      _loading = true;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/faculty'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> facultyJson = responseData['data'];

        print('Response data: ${response.body}'); // Debug print

        return facultyJson.map((json) {
          try {
            return Faculty.fromJson(json);
          } catch (e) {
            print('Error parsing faculty: $e');
            rethrow;
          }
        }).toList();
      } else {
        throw Exception('Failed to load faculty: ${response.body}');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error fetching faculty: $e');
    }
  }

  Future<void> addFaculty(String description, String email) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();

      final Map<String, dynamic> body = {
        'description': description,
        'email': email,
      };

      print('Request body: ${json.encode(body)}'); // Debug print

      final response = await http.post(
        Uri.parse('$baseUrl/api/faculty'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode(body),
      );

      print('Response status: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print

      if (response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add faculty');
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Failed to add faculty: $e');
    }
  }

  Future<void> updateFaculty(
    int id,
    String description,
    String email, {
    String? password,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();

      final Map<String, dynamic> body = {
        'description': description,
        'email': email,
      };

      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/faculty/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update faculty');
      }

      final responseData = json.decode(response.body);
      print('Update response: $responseData');

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteFaculty(int id) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/faculty/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete faculty: ${json.decode(response.body)['message']}');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /* Future<Map<DateTime, List<Events>>> fetchEvents(int month, int year) async {
    try {
      _loading = true;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/month?month=$month&year=$year'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final Map<String, dynamic> eventsData = responseData['data'] ?? {};
        final Map<DateTime, List<Events>> events = {};

        eventsData.forEach((dateStr, eventsList) {
          try {
            final date = DateTime.parse(dateStr.split('T')[0]);

            if (eventsList != null) {
              final List<Events> parsedEvents = (eventsList as List)
                  .map((e) => Events.fromJson(Map<String, dynamic>.from(e)))
                  .toList();

              events[date] = parsedEvents;
            }
          } catch (e) {
            print('Error parsing date or events for $dateStr: $e');
          }
        });

        _loading = false;
        notifyListeners();
        return events;
      } else {
        _loading = false;
        notifyListeners();
        throw Exception('Failed to load events: ${response.body}');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error fetching events: $e');
    }
  } */

  Future<Map<DateTime, List<Events>>> fetchEvents(int month, int year) async {
    try {
      _loading = true;
      notifyListeners();

      final headers = await _getAuthHeaders();
      debugPrint('Fetching events for month: $month, year: $year');
      debugPrint('User role: ${_user?.role}, collegeId: ${_user?.collegeId}');

      final response = await http.get(
        Uri.parse('$baseUrl/api/events/month?month=$month&year=$year'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<DateTime, List<Events>> events = {};
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          if (responseData['data'] == null || responseData['data'] == []) {
            debugPrint('No events found in response');
            _loading = false;
            notifyListeners();
            return events;
          }

          if (responseData['data'] is Map) {
            final Map<String, dynamic> eventsData = responseData['data'];

            eventsData.forEach((dateStr, eventsList) {
              try {
                if (eventsList != null && eventsList is List) {
                  debugPrint('Processing events for date: $dateStr');
                  final date = DateTime.parse(dateStr.split('T')[0]);
                  final List<Events> parsedEvents = [];

                  for (var event in eventsList) {
                    try {
                      debugPrint(
                          'Processing event: ${event['title']}, status: ${event['status']}');
                      final parsedEvent =
                          Events.fromJson(Map<String, dynamic>.from(event));
                      parsedEvents.add(parsedEvent);
                    } catch (e) {
                      debugPrint('Error parsing individual event: $e');
                    }
                  }

                  if (parsedEvents.isNotEmpty) {
                    // Normalize the date to avoid time-related issues
                    final normalizedDate =
                        DateTime(date.year, date.month, date.day);
                    events[normalizedDate] = parsedEvents;
                  }
                }
              } catch (e) {
                debugPrint('Error processing date $dateStr: $e');
              }
            });
          }
        }

        _loading = false;
        notifyListeners();
        return events;
      } else {
        _loading = false;
        _error = 'Failed to load events: ${response.body}';
        notifyListeners();
        throw Exception(_error);
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error fetching events: $e');
    }
  }

  Future<void> createEvent(Map<String, dynamic> eventData,
      [File? imageFile]) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/events'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Process and validate date/time
      if (eventData['event_date'] != null) {
        final date = DateTime.parse(eventData['event_date']);
        eventData['event_date'] = DateFormat('yyyy-MM-dd').format(date);
      }

      // Add all event data as fields
      eventData.forEach((key, value) {
        if (value != null) {
          if (value is List) {
            request.fields[key] = json.encode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      // Add image if provided
      if (imageFile != null) {
        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();

        var multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: path.basename(imageFile.path),
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create event');
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateEvent(int eventId, Map<String, dynamic> eventData,
      [File? imageFile]) async {
    try {
      _loading = true;
      notifyListeners();

      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST', // Using POST with _method field for Laravel
        Uri.parse('$baseUrl/api/events/$eventId'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add _method field for Laravel to handle it as PUT
      request.fields['_method'] = 'PUT';

      // Handle allowed view
      if (eventData['allowedView'] != null) {
        if (eventData['allowedView'] is List) {
          request.fields['allowedView'] = json.encode(eventData['allowedView']);
        } else {
          request.fields['allowedView'] = eventData['allowedView'].toString();
        }
      }

      // Add all other event data fields
      eventData.forEach((key, value) {
        if (value != null && key != 'allowedView') {
          if (value is DateTime) {
            request.fields[key] = value.toIso8601String();
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      // Add image if provided
      if (imageFile != null) {
        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();

        var multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: path.basename(imageFile.path),
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update event');
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteEvent(int eventId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();

      // Make sure to include the _method field in the body for Laravel
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode({'_method': 'DELETE'}),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete event');
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Fetch notifications
  Future<void> fetchNotifications() async {
    if (_isLoadingNotifications) return;

    try {
      _isLoadingNotifications = true;
      _notificationError = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      debugPrint('Notifications Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> notificationsJson = responseData['data'];
          _notifications = notificationsJson
              .map((json) => EventNotification.fromJson(json))
              .toList();
        } else {
          _notificationError =
              responseData['message'] ?? 'Failed to load notifications';
        }
      } else {
        _notificationError = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      _notificationError = e.toString();
    } finally {
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }

  // Mark single notification as read
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        _notifications = _notifications.map((notification) {
          if (notification.id == notificationId) {
            return notification.copyWith(isRead: true);
          }
          return notification;
        }).toList();

        notifyListeners();
      } else {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/mark-all-read'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        _notifications = _notifications
            .map((notification) => notification.copyWith(isRead: true))
            .toList();

        notifyListeners();
      } else {
        throw Exception('Failed to mark all notifications as read');
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      if (response.statusCode == 200) {
        // Remove from local state
        _notifications
            .removeWhere((notification) => notification.id == notificationId);
        notifyListeners();
      } else {
        throw Exception('Failed to delete notification');
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  Future<void> updateEventResponse(String eventId, String response) async {
    try {
      final headers = await _getAuthHeaders();
      final responseData = await http.post(
        Uri.parse('$baseUrl/api/events/$eventId/response'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode({
          'response': response,
        }),
      );

      if (responseData.statusCode != 200) {
        final errorData = json.decode(responseData.body);
        throw Exception(
            errorData['message'] ?? 'Failed to update event response');
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, String>> getUserEventResponses(
      List<String> eventIds) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/responses'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode({
          'event_ids': eventIds,
          'user_id': _user?.id,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, String> responses = {};

        data.forEach((key, value) {
          responses[key] = value.toString();
        });

        // Store responses in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('event_responses', json.encode(responses));

        return responses;
      } else {
        // Try to get cached responses if API call fails
        final prefs = await SharedPreferences.getInstance();
        final cachedResponses = prefs.getString('event_responses');
        if (cachedResponses != null) {
          return Map<String, String>.from(json.decode(cachedResponses));
        }
        throw Exception('Failed to fetch user responses');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> shareEvent(String eventId) async {
    try {
      // Log share event with backend
      await shareEventLog(eventId);

      // Generate shareable link
      final shareLink = await generateEventShareLink(eventId);

      // Get event details if needed
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch event details');
      }

      final eventData = json.decode(response.body)['data'];
      final event = Events.fromJson(eventData);

      // Create share text with event details and link
      final String shareText = '''
${event.title}
Date: ${event.readableDate}
Time: ${event.formattedTime}
Location: ${event.location}

Join the event here: $shareLink''';

      // Share using platform share dialog
      await Share.share(shareText, subject: 'Join this event!');
    } catch (e) {
      throw Exception('Failed to share event: $e');
    }
  }

  Future<String> generateEventShareLink(String eventId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/$eventId/share-link'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['shareLink'];
      } else {
        throw Exception('Failed to generate share link');
      }
    } catch (e) {
      throw Exception('Error generating share link: $e');
    }
  }

  Future<void> shareEventLog(String eventId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/$eventId/share'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to log share event');
      }
    } catch (e) {
      print('Error logging share event: $e');
      // Don't throw here to allow sharing to continue even if logging fails
    }
  }

  Future<Events> getEvent(String eventId) async {
    try {
      _loading = true;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Events.fromJson(responseData['data']);
      } else {
        throw Exception('Failed to load event: ${response.body}');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error fetching event: $e');
    }
  }

  Future<Map<String, dynamic>> getEventResponses(List<String> eventIds) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/responses'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode({
          'event_ids': eventIds,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch event responses: ${response.body}');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw Exception('Error fetching event responses: $e');
    }
  }

  Future<Map<String, int>> getEventParticipantCounts(
      List<String> eventIds) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/participant-counts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode({
          'event_ids': eventIds,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body)['data'];
        final Map<String, int> counts = {};

        // Convert the response data into a Map<String, int>
        data.forEach((key, value) {
          // Only count 'Going' responses for participant count
          final goingCount = (value as List)
              .where((response) => response['response'] == 'Going')
              .length;
          counts[key] = goingCount;
        });

        return counts;
      } else {
        throw Exception('Failed to fetch participant counts');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Event Notification Methods
  Future<void> markEventNotificationAsRead(String notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }

      await fetchNotifications(); // Refresh notifications
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateEventNotificationSettings(
      Map<String, bool> settings) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/user/notification-settings'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode(settings),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update notification settings');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Events>> searchEvents(String query) async {
    try {
      _loading = true;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/events/search?query=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map((event) => Events.fromJson(event))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to search events: ${response.body}');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw Exception('Error searching events: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Calendar Integration Methods
  Future<String> getEventCalendarLink(String eventId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/$eventId/calendar-link'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['calendar_link'] as String;
      } else {
        throw Exception('Failed to get calendar link');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Location>> fetchLocations() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/locations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> locationsJson = responseData['data'];

        // Debug the response
        print('Response data: ${response.body}');

        return locationsJson.map((json) {
          try {
            return Location.fromJson(json);
          } catch (e) {
            print('Error parsing location: $e');
            rethrow;
          }
        }).toList();
      } else {
        throw Exception('Failed to load locations: ${response.body}');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error fetching locations: $e');
    }
  }

  Future<void> addLocation(String description) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();

      // Debug print for request
      print('Request body: ${json.encode({'description': description})}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/locations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode({
          'description': description,
        }),
      );

      // Debug prints for response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add location');
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Failed to add location: $e');
    }
  }

  Future<void> updateLocationDescription(int id, String description) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();

      // Debug print for request
      print('Updating location $id with description: $description');

      final response = await http.put(
        Uri.parse('$baseUrl/api/locations/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
        body: json.encode({
          'description': description,
        }),
      );

      // Debug prints
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update location');
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Failed to update location: $e');
    }
  }

  Future<void> deleteLocation(int id) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final headers = await _getAuthHeaders();

      // Debug print
      print('Deleting location: $id');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/locations/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': headers['Authorization'] ?? '',
        },
      );

      // Debug prints
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete location');
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Failed to delete location: $e');
    }
  }

  Future<List<Survey>> fetchSurveys() async {
    try {
      _loading = true;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/surveys'),
        headers: headers,
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map((survey) => Survey.fromJson(survey))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to load surveys: ${response.body}');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error fetching surveys: $e');
    }
  }

  Future<void> createSurvey(Map<String, dynamic> surveyData) async {
    try {
      _loading = true;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/surveys'),
        headers: headers,
        body: json.encode(surveyData),
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create survey');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error creating survey: $e');
    }
  }

  Future<void> submitSurveyResponse(
      int surveyId, Map<String, dynamic> answers) async {
    try {
      _loading = true;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/surveys/$surveyId/submit'),
        headers: headers,
        body: json.encode({'answers': answers}),
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to submit survey response');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error submitting survey response: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSurveyResponses(int surveyId) async {
    try {
      _loading = true;
      notifyListeners();

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/surveys/$surveyId/responses'),
        headers: headers,
      );

      _loading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
        return [];
      } else {
        throw Exception('Failed to load survey responses: ${response.body}');
      }
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error fetching survey responses: $e');
    }
  }
}
