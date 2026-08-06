import 'package:equatable/equatable.dart';

/// Tracks ONE stream's progress on ONE topic — this is what varies
/// between S.3 East and S.3 West even though they share the same
/// SyllabusTopic definitions, since they move at different paces with
/// possibly different teachers.
class SyllabusCoverageMark extends Equatable {
  final String id; // deterministic: "{topicId}_{classId}"
  final String schoolId;
  final String topicId;
  final String classId; // the specific stream
  final String subjectId;
  final String term;
  final bool isCovered;
  final DateTime? coveredAt;
  final String? coveredByTeacherId;
  final bool hodApproved;
  final String? hodApprovedByUserId;
  final DateTime? hodApprovedAt;

  const SyllabusCoverageMark({
    required this.id,
    required this.schoolId,
    required this.topicId,
    required this.classId,
    required this.subjectId,
    required this.term,
    this.isCovered = false,
    this.coveredAt,
    this.coveredByTeacherId,
    this.hodApproved = false,
    this.hodApprovedByUserId,
    this.hodApprovedAt,
  });

  factory SyllabusCoverageMark.fromMap(String id, Map<String, dynamic> map) {
    return SyllabusCoverageMark(
      id: id,
      schoolId: map['schoolId'] as String,
      topicId: map['topicId'] as String,
      classId: map['classId'] as String,
      subjectId: map['subjectId'] as String,
      term: map['term'] as String,
      isCovered: map['isCovered'] as bool? ?? false,
      coveredAt: map['coveredAt'] != null ? DateTime.parse(map['coveredAt'] as String) : null,
      coveredByTeacherId: map['coveredByTeacherId'] as String?,
      hodApproved: map['hodApproved'] as bool? ?? false,
      hodApprovedByUserId: map['hodApprovedByUserId'] as String?,
      hodApprovedAt: map['hodApprovedAt'] != null ? DateTime.parse(map['hodApprovedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'topicId': topicId,
    'classId': classId,
    'subjectId': subjectId,
    'term': term,
    'isCovered': isCovered,
    'coveredAt': coveredAt?.toIso8601String(),
    'coveredByTeacherId': coveredByTeacherId,
    'hodApproved': hodApproved,
    'hodApprovedByUserId': hodApprovedByUserId,
    'hodApprovedAt': hodApprovedAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id, schoolId, topicId, classId, subjectId, term, isCovered, coveredAt,
    coveredByTeacherId, hodApproved, hodApprovedByUserId, hodApprovedAt,
  ];
}