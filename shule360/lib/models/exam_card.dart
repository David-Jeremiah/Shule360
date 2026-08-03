import 'package:equatable/equatable.dart';

class ExamCard extends Equatable {
  final String id;
  final String schoolId;
  final String studentId;
  final String examName;
  final String term;
  final bool feeCleared;
  final DateTime issuedAt;
  final String issuedByUserId;

  const ExamCard({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.examName,
    required this.term,
    required this.feeCleared,
    required this.issuedAt,
    required this.issuedByUserId,
  });

  factory ExamCard.fromMap(String id, Map<String, dynamic> map) {
    return ExamCard(
      id: id,
      schoolId: map['schoolId'] as String,
      studentId: map['studentId'] as String,
      examName: map['examName'] as String,
      term: map['term'] as String,
      feeCleared: map['feeCleared'] as bool,
      issuedAt: DateTime.parse(map['issuedAt'] as String),
      issuedByUserId: map['issuedByUserId'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'studentId': studentId,
    'examName': examName,
    'term': term,
    'feeCleared': feeCleared,
    'issuedAt': issuedAt.toIso8601String(),
    'issuedByUserId': issuedByUserId,
  };

  @override
  List<Object?> get props =>
      [id, schoolId, studentId, examName, term, feeCleared, issuedAt, issuedByUserId];
}