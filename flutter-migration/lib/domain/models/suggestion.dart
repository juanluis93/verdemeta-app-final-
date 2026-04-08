import 'planner_types.dart';

class Suggestion {
  final String id;
  final DateTime day;
  final SuggestionSeverity severity;
  final SuggestionType type;
  final String message;
  final Map<String, dynamic> actionPayload;

  const Suggestion({
    required this.id,
    required this.day,
    required this.severity,
    required this.type,
    required this.message,
    required this.actionPayload,
  });

  Suggestion copyWith({
    String? id,
    DateTime? day,
    SuggestionSeverity? severity,
    SuggestionType? type,
    String? message,
    Map<String, dynamic>? actionPayload,
  }) {
    return Suggestion(
      id: id ?? this.id,
      day: day ?? this.day,
      severity: severity ?? this.severity,
      type: type ?? this.type,
      message: message ?? this.message,
      actionPayload: actionPayload ?? this.actionPayload,
    );
  }
}
