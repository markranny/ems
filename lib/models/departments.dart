class Departments {
  int id;
  String description;

  Departments({required this.id, required this.description});

  factory Departments.fromJson(Map<String, dynamic> json) {
    return Departments(
      id: json['id'],
      description: json['description'],
    );
  }

  // Override toString to return a meaningful representation
  @override
  String toString() {
    return description; // Return the description of the department
  }
}
