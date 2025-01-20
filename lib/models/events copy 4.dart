import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

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
    final eventDate =
        DateTime.parse(json['event_date'].toString().split('T')[0]);

    String eventTime;
    try {
      final timeDate = DateTime.parse(json['event_time'].toString());
      eventTime =
          '${timeDate.hour.toString().padLeft(2, '0')}:${timeDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('Error parsing event time: $e');
      eventTime = '00:00';
    }

    // Add debug print for image path
    debugPrint('Parsing event image path from JSON: ${json['eventImagePath']}');

    return Events(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      eventDate: eventDate,
      eventTime: eventTime,
      location: json['location'] as String,
      creatorId: json['creator_id'] as int? ?? 0,
      maxParticipants: json['max_participants'] as int,
      status: json['status'] as String,
      eventImagePath: json['eventImagePath']
          as String?, // Make sure this matches your Laravel response
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

  String get formattedDate {
    return "${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}";
  }

  String get readableDate {
    return DateFormat('EEEE, MMMM d, y').format(eventDate);
  }

  String get formattedTime {
    final timeParts = eventTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }

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

  String? get imageUrl {
    debugPrint('Getting imageUrl for eventImagePath: $eventImagePath');
    if (eventImagePath == null || eventImagePath!.isEmpty) {
      return null;
    }
    // If it's already a full URL, return as is
    if (eventImagePath!.startsWith('http')) {
      return eventImagePath;
    }
    // Ensure the path starts with a forward slash
    final path =
        eventImagePath!.startsWith('/') ? eventImagePath! : '/$eventImagePath';
    // Construct the full URL using the base URL
    return 'http://10.151.5.239:8080$path';
  }

  bool get hasImage => eventImagePath != null && eventImagePath!.isNotEmpty;

  bool get isUpcoming => dateTime.isAfter(DateTime.now());

  bool get isOngoing {
    final now = DateTime.now();
    return dateTime.isBefore(now) &&
        dateTime.add(const Duration(hours: 2)).isAfter(now);
  }

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
}
