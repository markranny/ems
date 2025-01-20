import 'package:intl/intl.dart';

class Events {
  final int id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String eventTime;
  final String location;
  final int creatorId;
  final int maxParticipants;
  final String status;
  final String? eventImagePath;
  final List<int> allowedView;

  Events({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.eventTime,
    required this.location,
    required this.creatorId,
    required this.maxParticipants,
    required this.status,
    this.eventImagePath,
    required this.allowedView,
  });

  factory Events.fromJson(Map<String, dynamic> json) {
    return Events(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      eventDate: DateTime.parse(json['event_date']),
      eventTime: json['event_time'] as String,
      location: json['location'] as String,
      creatorId: json['creator_id'] as int,
      maxParticipants: json['max_participants'] as int,
      status: json['status'] as String,
      eventImagePath: json['eventImagePath'] as String?,
      allowedView: List<int>.from(json['allowedView'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_date': formatter.format(eventDate),
      'event_time': eventTime,
      'location': location,
      'creator_id': creatorId,
      'max_participants': maxParticipants,
      'status': status,
      'eventImagePath': eventImagePath,
      'allowedView': allowedView,
    };
  }

  // Date formatting methods
  String get formattedDate {
    return "${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}";
  }

  // Get formatted date in a more readable format
  String get readableDate {
    return DateFormat('EEEE, MMMM d, y').format(eventDate);
  }

  // Get formatted time in 12-hour format
  String get formattedTime {
    final timeParts = eventTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }

  // Get datetime by combining date and time
  DateTime get dateTime {
    final timeParts = eventTime.split(':');
    return DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  // Check if event has image
  bool get hasImage => eventImagePath != null && eventImagePath!.isNotEmpty;

  // Get full image URL
  String? get imageUrl {
    if (!hasImage) return null;
    // If the path is already a full URL, return it
    if (eventImagePath!.startsWith('http')) return eventImagePath;
    // Otherwise, construct the full URL (adjust base URL as needed)
    const baseUrl = 'YOUR_BASE_URL'; // Replace with your actual base URL
    return '$baseUrl$eventImagePath';
  }

  // Check if event is upcoming
  bool get isUpcoming => dateTime.isAfter(DateTime.now());

  // Check if event is ongoing
  bool get isOngoing {
    final now = DateTime.now();
    // Assuming events last for 2 hours by default
    return dateTime.isBefore(now) &&
        dateTime.add(const Duration(hours: 2)).isAfter(now);
  }

  // Get event status in a more readable format
  String get readableStatus {
    return status[0].toUpperCase() + status.substring(1);
  }

  Events copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? eventDate,
    String? eventTime,
    String? location,
    int? creatorId,
    int? maxParticipants,
    String? status,
    String? eventImagePath,
    List<int>? allowedView,
  }) {
    return Events(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      location: location ?? this.location,
      creatorId: creatorId ?? this.creatorId,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      status: status ?? this.status,
      eventImagePath: eventImagePath ?? this.eventImagePath,
      allowedView: allowedView ?? List<int>.from(this.allowedView),
    );
  }

  @override
  String toString() {
    return 'Event{id: $id, title: $title, date: $formattedDate, time: $eventTime}';
  }
}
