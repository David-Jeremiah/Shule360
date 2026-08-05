import 'package:equatable/equatable.dart';

/// A single class, e.g. "S.2 East" or just "P.5" if the school has no
/// streams. [levelLabel] ("S.2") and [streamName] ("East") are stored
/// separately from the combined display [name] so classes can be filtered
/// or regenerated later without parsing strings.
class SchoolClass extends Equatable {
  final String id;
  final String schoolId;
  final String name;
  final String levelLabel;
  final String? streamName;
  final String? classTeacherId;
  final Map<String, String> subjectTeacherIds;

  const SchoolClass({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.levelLabel,
    this.streamName,
    this.classTeacherId,
    this.subjectTeacherIds = const {},
  });

  factory SchoolClass.fromMap(String id, Map<String, dynamic> map) {
    return SchoolClass(
      id: id,
      schoolId: map['schoolId'] as String,
      name: map['name'] as String,
      levelLabel: map['levelLabel'] as String? ?? map['name'] as String,
      streamName: map['streamName'] as String?,
      classTeacherId: map['classTeacherId'] as String?,
      subjectTeacherIds: Map<String, String>.from(map['subjectTeacherIds'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'name': name,
    'levelLabel': levelLabel,
    'streamName': streamName,
    'classTeacherId': classTeacherId,
    'subjectTeacherIds': subjectTeacherIds,
  };

  @override
  List<Object?> get props =>
      [id, schoolId, name, levelLabel, streamName, classTeacherId, subjectTeacherIds];
}