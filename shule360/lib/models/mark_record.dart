import 'package:equatable/equatable.dart';

enum TermPeriod { midTerm, endOfTerm }

class MarkRecord extends Equatable {
  final String id;
  final String schoolId;
  final String studentId;
  final String subjectId;
  final String classId;
  final String term; // e.g. "2026-T2"
  final TermPeriod period;
  final double score;
  final double maxScore;
  final String enteredByUserId;
  final DateTime enteredAt;

  const MarkRecord({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.subjectId,
    required this.classId,
    required this.term,
    required this.period,
    required this.score,
    required this.maxScore,
    required this.enteredByUserId,
    required this.enteredAt,
  });

  double get percentage => maxScore == 0 ? 0 : (score / maxScore) * 100;

  factory MarkRecord.fromMap(String id, Map<String, dynamic> map) {
    return MarkRecord(
      id: id,
      schoolId: map['schoolId'] as String,
      studentId: map['studentId'] as String,
      subjectId: map['subjectId'] as String,
      classId: map['classId'] as String,
      term: map['term'] as String,
      period: TermPeriod.values.firstWhere((p) => p.name == map['period']),
      score: (map['score'] as num).toDouble(),
      maxScore: (map['maxScore'] as num).toDouble(),
      enteredByUserId: map['enteredByUserId'] as String,
      enteredAt: DateTime.parse(map['enteredAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'studentId': studentId,
    'subjectId': subjectId,
    'classId': classId,
    'term': term,
    'period': period.name,
    'score': score,
    'maxScore': maxScore,
    'enteredByUserId': enteredByUserId,
    'enteredAt': enteredAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id, schoolId, studentId, subjectId, classId, term, period,
    score, maxScore, enteredByUserId, enteredAt,
  ];
}