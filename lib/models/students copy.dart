import 'package:emsv7/models/colleges.dart';
import 'package:emsv7/models/departments.dart';
import 'package:emsv7/models/user.dart';

class Students {
  final int id;
  final String fullname;
  final Colleges college;
  final Departments department;
  final User user;

  Students({
    required this.id,
    required this.fullname,
    required this.college,
    required this.department,
    required this.user,
  });

  factory Students.fromJson(Map<String, dynamic> json) {
    try {
      return Students(
        id: json['id'],
        fullname: json['fullname'],
        college: Colleges.fromJson(json['college']),
        department: Departments.fromJson(json['department']),
        user: User.fromJson(json['user']),
      );
    } catch (e, stackTrace) {
      print('Error parsing Students: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }

  int get collegeId => college.id;
  int get userId => user.id;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'college': college.toJson(),
      'department': department.toJson(),
      // Avoid circular reference by not including full user object
      'user_id': userId,
    };
  }
}
