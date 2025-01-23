import 'package:emsv7/models/students.dart';
import 'package:emsv7/models/faculty.dart';
import 'package:emsv7/models/executives.dart';

class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? status;
  final String createdAt;
  final String profilePhotoUrl;
  final String? description;
  final Students? student;
  final Faculty? faculty;
  final Executives? executive;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.status,
    required this.createdAt,
    required this.profilePhotoUrl,
    this.description,
    this.student,
    this.faculty,
    this.executive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'] as int,
        username: json['username'] as String? ?? '', // Add null check
        email: json['email'] as String? ?? '', // Add null check
        role: (json['role'] as String? ?? '').toLowerCase(),
        status: json['status'] as String?,
        createdAt: json['created_at'] as String? ?? '', // Add null check
        profilePhotoUrl:
            json['profile_photo_url'] as String? ?? '', // Add null check
        description: json['description'] as String?,
        student: json['student'] != null
            ? Students.fromJson(json['student'] as Map<String, dynamic>)
            : null,
        faculty: json['faculty'] != null
            ? Faculty.fromJson(json['faculty'] as Map<String, dynamic>)
            : null,
        executive: json['executive'] != null
            ? Executives.fromJson(json['executive'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      print('Error parsing User: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Getters remain unchanged
  bool get isAdmin => role == 'admin';
  bool get isSuperAdmin => role == 'superadmin';
  bool get hasAdminPrivileges => isAdmin || isSuperAdmin;
  bool get isStudent => role == 'student';
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isReject => status == 'reject';

  String? get roleDescription {
    if (faculty?.description != null) return faculty!.description;
    if (executive?.description != null) return executive!.description;
    return description;
  }

  int? get collegeId => student?.collegeId;
}
