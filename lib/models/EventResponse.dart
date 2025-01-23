class EventResponse {
  final int id;
  final int eventId;
  final int userId;
  final String response;
  final String userName;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventResponse({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.response,
    required this.userName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventResponse.fromJson(Map<String, dynamic> json) {
    // Safe integer parsing function
    int parseIntSafely(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return EventResponse(
      id: parseIntSafely(json['id']),
      eventId: parseIntSafely(json['event_id']),
      userId: parseIntSafely(json['user_id']),
      response: json['response']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Anonymous',
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }
}
