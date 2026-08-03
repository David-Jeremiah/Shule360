import 'package:equatable/equatable.dart';

class SportsEvent extends Equatable {
  final String id;
  final String schoolId;
  final String name;
  final String category; // e.g. "Football", "Athletics"
  final DateTime eventDate;
  final String? resultSummary;

  const SportsEvent({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.category,
    required this.eventDate,
    this.resultSummary,
  });

  factory SportsEvent.fromMap(String id, Map<String, dynamic> map) {
    return SportsEvent(
      id: id,
      schoolId: map['schoolId'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      eventDate: DateTime.parse(map['eventDate'] as String),
      resultSummary: map['resultSummary'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'name': name,
    'category': category,
    'eventDate': eventDate.toIso8601String(),
    'resultSummary': resultSummary,
  };

  @override
  List<Object?> get props => [id, schoolId, name, category, eventDate, resultSummary];
}