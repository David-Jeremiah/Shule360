import 'package:equatable/equatable.dart';

class SyllabusTopic extends Equatable {
  final String id;
  final String schoolId;
  final String subjectId;
  final String classId;
  final String term;
  final String title;
  final bool isCovered;
  final DateTime? coveredAt;

  const SyllabusTopic({
    required this.id,
    required this.schoolId,
    required this.subjectId,
    required this.classId,
    required this.term,
    required this.title,
    this.isCovered = false,
    this.coveredAt,
  });

  factory SyllabusTopic.fromMap(String id, Map<String, dynamic> map) {
    return SyllabusTopic(
      id: id,
      schoolId: map['schoolId'] as String,
      subjectId: map['subjectId'] as String,
      classId: map['classId'] as String,
      term: map['term'] as String,
      title: map['title'] as String,
      isCovered: map['isCovered'] as bool? ?? false,
      coveredAt: map['coveredAt'] != null ? DateTime.parse(map['coveredAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'subjectId': subjectId,
    'classId': classId,
    'term': term,
    'title': title,
    'isCovered': isCovered,
    'coveredAt': coveredAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, schoolId, subjectId, classId, term, title, isCovered, coveredAt];
}