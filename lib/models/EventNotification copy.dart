class EventNotification {
  final int id;
  final int eventId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  EventNotification({
    required this.id,
    required this.eventId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory EventNotification.fromJson(Map<String, dynamic> json) {
    return EventNotification(
      id: json['id'],
      eventId: json['event_id'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
