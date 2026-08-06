import 'package:equatable/equatable.dart';

/// The syllabus CONTENT — what topics exist for a subject at a given class
/// level (e.g. "S.3"), for a term. Shared across every stream of that
/// level (S.3 East and S.3 West teach the same topics), since the content
/// itself doesn't change — only how far each stream has gotten does (see
/// SyllabusCoverageMark for that per-stream tracking).
class SyllabusTopic extends Equatable {
  final String id;
  final String schoolId;
  final String subjectId;
  final String levelLabel; // e.g. "S.3" — NOT a specific stream/classId
  final String term;
  final String title;

  const SyllabusTopic({
    required this.id,
    required this.schoolId,
    required this.subjectId,
    required this.levelLabel,
    required this.term,
    required this.title,
  });

  factory SyllabusTopic.fromMap(String id, Map<String, dynamic> map) {
    return SyllabusTopic(
      id: id,
      schoolId: map['schoolId'] as String,
      subjectId: map['subjectId'] as String,
      levelLabel: map['levelLabel'] as String,
      term: map['term'] as String,
      title: map['title'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'subjectId': subjectId,
    'levelLabel': levelLabel,
    'term': term,
    'title': title,
  };

  @override
  List<Object?> get props => [id, schoolId, subjectId, levelLabel, term, title];
}