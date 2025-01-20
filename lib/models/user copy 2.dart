import 'package:emsv7/models/students.dart';

class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? status;
  final Students? student; // Add this field

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.status,
    this.student,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'] ?? 0,
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        role: json['role']?.toString().toLowerCase() ?? '',
        status: json['status'],
        student:
            json['student'] != null ? Students.fromJson(json['student']) : null,
      );
    } catch (e) {
      print('Error parsing User: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  bool get isAdmin => role == 'admin';
  bool get isSuperAdmin => role == 'superadmin';
  bool get hasAdminPrivileges => isAdmin || isSuperAdmin;
  bool get isStudent => role == 'student';

  // Add getter for college ID
  int? get collegeId => student?.collegeId;
}
