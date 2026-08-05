import 'package:equatable/equatable.dart';

/// One target per subject/class/term, set by the HOD — how many weeks
/// the syllabus should take to cover, and the pass mark expectation.
class SyllabusTarget extends Equatable {
  final String id; // deterministic: "{subjectId}_{classId}_{term}"
  final String schoolId;
  final String subjectId;
  final String classId;
  final String term;
  final int targetWeeks;
  final double passMarkTarget;
  final String setByUserId;
  final DateTime setAt;

  const SyllabusTarget({
    required this.id,
    required this.schoolId,
    required this.subjectId,
    required this.classId,
    required this.term,
    required this.targetWeeks,
    required this.passMarkTarget,
    required this.setByUserId,
    required this.setAt,
  });

  factory SyllabusTarget.fromMap(String id, Map<String, dynamic> map) {
    return SyllabusTarget(
      id: id,
      schoolId: map['schoolId'] as String,
      subjectId: map['subjectId'] as String,
      classId: map['classId'] as String,
      term: map['term'] as String,
      targetWeeks: map['targetWeeks'] as int,
      passMarkTarget: (map['passMarkTarget'] as num).toDouble(),
      setByUserId: map['setByUserId'] as String,
      setAt: DateTime.parse(map['setAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'subjectId': subjectId,
    'classId': classId,
    'term': term,
    'targetWeeks': targetWeeks,
    'passMarkTarget': passMarkTarget,
    'setByUserId': setByUserId,
    'setAt': setAt.toIso8601String(),
  };

  @override
  List<Object?> get props =>
      [id, schoolId, subjectId, classId, term, targetWeeks, passMarkTarget, setByUserId, setAt];
}