import 'package:flutter/foundation.dart';
import 'events.dart';
import 'user.dart';

class Question {
  final String questionText;
  final String type;
  final bool required;
  final List<String> options;

  Question({
    required this.questionText,
    required this.type,
    this.required = true,
    this.options = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionText: json['question'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      required: json['required'] as bool? ?? true,
      options:
          json['options'] != null ? List<String>.from(json['options']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': questionText,
      'type': type,
      'required': required,
      'options': options,
    };
  }

  Question copyWith({
    String? questionText,
    String? type,
    bool? required,
    List<String>? options,
  }) {
    return Question(
      questionText: questionText ?? this.questionText,
      type: type ?? this.type,
      required: required ?? this.required,
      options: options ?? List.from(this.options),
    );
  }
}
