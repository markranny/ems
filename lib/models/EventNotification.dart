// lib/models/EventNotification.dart

class EventNotification {
  final int id;
  final int? eventId;
  final int userId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  EventNotification({
    required this.id,
    this.eventId,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory EventNotification.fromJson(Map<String, dynamic> json) {
    return EventNotification(
      id: json['id'],
      eventId: json['event_id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  EventNotification copyWith({
    int? id,
    int? eventId,
    int? userId,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return EventNotification(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
