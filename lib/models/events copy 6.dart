import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
    // Debug print incoming JSON
    debugPrint('Parsing event JSON: ${json.toString()}');

    // Parse allowedView with extensive error handling
    List<int> parseAllowedView(dynamic rawAllowedView) {
      try {
        if (rawAllowedView == null) {
          debugPrint('allowedView is null, returning empty list');
          return [];
        }

        // If it's already a List
        if (rawAllowedView is List) {
          debugPrint('allowedView is a List: $rawAllowedView');
          return rawAllowedView.map<int>((item) {
            if (item is int) return item;
            if (item is String) return int.parse(item);
            return 0;
          }).toList();
        }

        // If it's a JSON string
        if (rawAllowedView is String) {
          debugPrint('allowedView is a String: $rawAllowedView');
          try {
            final decoded = jsonDecode(rawAllowedView);
            if (decoded is List) {
              return decoded.map<int>((item) {
                if (item is int) return item;
                if (item is String) return int.parse(item);
                return 0;
              }).toList();
            }
          } catch (e) {
            debugPrint('Error decoding allowedView string: $e');
          }
        }

        // If it's a dynamic type that could be converted to string and parsed
        try {
          final stringValue = rawAllowedView.toString();
          if (stringValue.startsWith('[') && stringValue.endsWith(']')) {
            final decoded = jsonDecode(stringValue);
            if (decoded is List) {
              return decoded.map<int>((item) {
                if (item is int) return item;
                if (item is String) return int.parse(item);
                return 0;
              }).toList();
            }
          }
        } catch (e) {
          debugPrint('Error parsing allowedView string representation: $e');
        }

        debugPrint(
            'Unexpected allowedView format: ${rawAllowedView.runtimeType}');
        return [];
      } catch (e) {
        debugPrint('Error parsing allowedView: $e');
        return [];
      }
    }

    // Parse event date
    DateTime parseEventDate(dynamic rawDate) {
      try {
        final dateStr = rawDate.toString();
        return DateTime.parse(dateStr.split('T')[0]);
      } catch (e) {
        debugPrint('Error parsing event date: $e');
        return DateTime.now(); // Fallback to current date
      }
    }

    // Parse event time
    String parseEventTime(dynamic rawTime) {
      try {
        final timeStr = rawTime.toString();
        if (timeStr.contains('T')) {
          // Handle ISO format
          final timeDate = DateTime.parse(timeStr);
          return '${timeDate.hour.toString().padLeft(2, '0')}:${timeDate.minute.toString().padLeft(2, '0')}';
        } else if (timeStr.contains(':')) {
          // Handle HH:mm format
          final timeParts = timeStr.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        }
        throw FormatException('Invalid time format');
      } catch (e) {
        debugPrint('Error parsing event time: $e');
        return '00:00'; // Fallback time
      }
    }

    final allowedViewData = parseAllowedView(json['allowedView']);
    debugPrint('Parsed allowedView: $allowedViewData');

    // Create the Events object with proper parsing
    return Events(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      eventDate: parseEventDate(json['event_date']),
      eventTime: parseEventTime(json['event_time']),
      location: json['location'] as String? ?? '',
      creatorId: json['creator_id'] as int? ?? 0,
      maxParticipants: json['max_participants'] as int? ?? 0,
      status: json['status'] as String? ?? 'draft',
      eventImagePath: json['eventImagePath'] as String?,
      allowedView: allowedViewData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_date': DateFormat('yyyy-MM-dd').format(eventDate),
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
    if (eventImagePath == null || eventImagePath!.isEmpty) {
      return null;
    }

    try {
      // Handle full URLs
      if (eventImagePath!.startsWith('http')) {
        return Uri.parse(eventImagePath!).toString();
      }

      // Handle relative paths
      final path = eventImagePath!.startsWith('/')
          ? eventImagePath!
          : '/$eventImagePath';
      final baseUrl = 'https://eljincorp.com';
      /* 'http://10.151.5.239:8080/'; */

      return Uri.parse('$baseUrl$path').toString();
    } catch (e) {
      debugPrint('Error formatting image URL: $e');
      return null;
    }
  }

  Future<bool> isImageAccessible() async {
    if (imageUrl == null) return false;

    try {
      final response = await http.head(Uri.parse(imageUrl!));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error checking image accessibility: $e');
      return false;
    }
  }

  bool get hasImage =>
      eventImagePath != null &&
      eventImagePath!.isNotEmpty &&
      (eventImagePath!.startsWith('http') ||
          eventImagePath!.endsWith('.jpg') ||
          eventImagePath!.endsWith('.jpeg') ||
          eventImagePath!.endsWith('.png'));

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
