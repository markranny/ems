import 'package:emsv7/models/students.dart';
import 'package:emsv7/models/faculty.dart';
import 'package:emsv7/models/executives.dart';

class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String status;
  final String createdAt;
  final String? description; // Add description field
  final Students? student;
  final Faculty? faculty; // Add faculty relationship
  final Executives? executive; // Add executive relationship

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
    this.description,
    this.student,
    this.faculty,
    this.executive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'] ?? 0,
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        role: json['role']?.toString().toLowerCase() ?? '',
        status: json['status'] ?? 'pending',
        createdAt: json['created_at'],
        description: json['description'],
        student:
            json['student'] != null ? Students.fromJson(json['student']) : null,
        faculty:
            json['faculty'] != null ? Faculty.fromJson(json['faculty']) : null,
        executive: json['executive'] != null
            ? Executives.fromJson(json['executive'])
            : null,
      );
    } catch (e) {
      print('Error parsing User: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Existing getters
  bool get isAdmin => role == 'admin';
  bool get isSuperAdmin => role == 'superadmin';
  bool get hasAdminPrivileges => isAdmin || isSuperAdmin;
  bool get isStudent => role == 'student';
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  // Get description based on role
  String? get roleDescription {
    if (faculty != null) return faculty!.description;
    if (executive != null) return executive!.description;
    return description;
  }

  int? get collegeId => student?.collegeId;
}
