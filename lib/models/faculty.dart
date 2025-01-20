import 'package:emsv7/models/user.dart';

class Faculty {
  final int id;
  final String description;
  final User user;

  Faculty({
    required this.id,
    required this.description,
    required this.user,
  });

  factory Faculty.fromJson(Map<String, dynamic> json) {
    try {
      // Check if we're getting a nested user object or if we need to create a minimal user
      final userJson = json['user'] ??
          {
            'id': json['user_id'],
            'username': '', // Add default values as needed
            'email': '',
            'role': 'faculty',
            'created_at': json['created_at'],
            'profile_photo_url': '',
          };

      return Faculty(
        id: json['id'] as int,
        description: json['description'] as String,
        user: User.fromJson(userJson as Map<String, dynamic>),
      );
    } catch (e, stackTrace) {
      print('Error parsing Faculty: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }
}
