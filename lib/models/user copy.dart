class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? status;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'] ?? 0,
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? '',
        status: json['status'],
      );
    } catch (e) {
      print('Error parsing User: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}
