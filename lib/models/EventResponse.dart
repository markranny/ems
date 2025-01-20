class EventResponse {
  final int id;
  final int eventId;
  final int userId;
  final String response;
  final String userName; // Add this to get the user's name
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
    return EventResponse(
      id: json['id'],
      eventId: json['event_id'],
      userId: json['user_id'],
      response: json['response'],
      userName: json['user_name'] ??
          'Anonymous', // Fallback to 'Anonymous' if name is not provided
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
