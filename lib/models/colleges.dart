class Colleges {
  final int id;
  final String college;

  Colleges({required this.id, required this.college});

  factory Colleges.fromJson(Map<String, dynamic> json) {
    return Colleges(
      id: json['id'],
      college: json['college'],
    );
  }

  // Override toString to return a meaningful representation
  @override
  String toString() {
    return college; // Return the name of the college
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'college': college,
    };
  }
}
