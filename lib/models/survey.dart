import 'package:flutter/foundation.dart';
import 'events.dart';
import 'user.dart';

class Survey {
  final int id;
  final String title;
  final String description;
  final int eventId;
  final int creatorId;
  final String status;
  final List<Map<String, dynamic>> questions;
  final Events? event;
  final User? creator;

  Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.eventId,
    required this.creatorId,
    required this.status,
    required this.questions,
    this.event,
    this.creator,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    try {
      // Handle the questions field properly
      List<Map<String, dynamic>> parseQuestions(dynamic questionsData) {
        if (questionsData == null) return [];

        if (questionsData is List) {
          return questionsData.map((question) {
            if (question is Map) {
              return Map<String, dynamic>.from(question);
            }
            // Handle case where question might be a string or other type
            return <String, dynamic>{
              'question': question.toString(),
              'type': 'text',
              'required': true
            };
          }).toList();
        }

        // If questionsData is not a List, return empty list
        return [];
      }

      return Survey(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        eventId: json['event_id'] as int? ?? 0,
        creatorId: json['creator_id'] as int? ?? 0,
        status: json['status'] as String? ?? 'draft',
        questions: parseQuestions(json['questions']),
        event: json['event'] != null ? Events.fromJson(json['event']) : null,
        creator:
            json['creator'] != null ? User.fromJson(json['creator']) : null,
      );
    } catch (e) {
      debugPrint('Error parsing Survey: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_id': eventId,
      'creator_id': creatorId,
      'status': status,
      'questions': questions,
      'event': event?.toJson(),
      'creator': creator?.toJson(), // Changed to use null-aware operator
    };
  }
}
