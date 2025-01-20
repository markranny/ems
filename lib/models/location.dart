class Location {
  int id;
  String description;

  Location({required this.id, required this.description});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      description: json['description'],
    );
  }

  @override
  String toString() {
    return description;
  }
}
