import 'package:equatable/equatable.dart';

class SyllabusTopic extends Equatable {
  final String id;
  final String schoolId;
  final String subjectId;
  final String classId;
  final String term;
  final String title;

  /// Teacher marks this true when they've taught the topic — this is a
  /// proposal, not final. HOD approval (below) is the real "done" signal.
  final bool isCovered;
  final DateTime? coveredAt;
  final String? coveredByTeacherId;

  final bool hodApproved;
  final String? hodApprovedByUserId;
  final DateTime? hodApprovedAt;

  const SyllabusTopic({
    required this.id,
    required this.schoolId,
    required this.subjectId,
    required this.classId,
    required this.term,
    required this.title,
    this.isCovered = false,
    this.coveredAt,
    this.coveredByTeacherId,
    this.hodApproved = false,
    this.hodApprovedByUserId,
    this.hodApprovedAt,
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
      coveredByTeacherId: map['coveredByTeacherId'] as String?,
      hodApproved: map['hodApproved'] as bool? ?? false,
      hodApprovedByUserId: map['hodApprovedByUserId'] as String?,
      hodApprovedAt: map['hodApprovedAt'] != null ? DateTime.parse(map['hodApprovedAt'] as String) : null,
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
    'coveredByTeacherId': coveredByTeacherId,
    'hodApproved': hodApproved,
    'hodApprovedByUserId': hodApprovedByUserId,
    'hodApprovedAt': hodApprovedAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id, schoolId, subjectId, classId, term, title, isCovered, coveredAt,
    coveredByTeacherId, hodApproved, hodApprovedByUserId, hodApprovedAt,
  ];
}