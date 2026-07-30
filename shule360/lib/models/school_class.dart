import 'package:equatable/equatable.dart';

/// e.g. "S.2 East", "P.5". classTeacherId is the one teacher who owns this
/// class administratively; subjectTeacherIds maps subjectId -> teacherId
/// for the different teachers who teach subjects into this same class.
class SchoolClass extends Equatable {
  final String id;
  final String schoolId;
  final String name;
  final String? classTeacherId;
  final Map<String, String> subjectTeacherIds;

  const SchoolClass({
    required this.id,
    required this.schoolId,
    required this.name,
    this.classTeacherId,
    this.subjectTeacherIds = const {},
  });

  factory SchoolClass.fromMap(String id, Map<String, dynamic> map) {
    return SchoolClass(
      id: id,
      schoolId: map['schoolId'] as String,
      name: map['name'] as String,
      classTeacherId: map['classTeacherId'] as String?,
      subjectTeacherIds: Map<String, String>.from(map['subjectTeacherIds'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'name': name,
    'classTeacherId': classTeacherId,
    'subjectTeacherIds': subjectTeacherIds,
  };

  @override
  List<Object?> get props => [id, schoolId, name, classTeacherId, subjectTeacherIds];
}