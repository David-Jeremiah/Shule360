import 'package:equatable/equatable.dart';

enum EducationLevel { nursery, primary, secondary }

class Student extends Equatable {
  final String id;
  final String schoolId;
  final String fullName;
  final String admissionNumber;
  final String rollNumber;
  final EducationLevel level;
  final String classId;
  final String? streamId;
  final String? guardianPhoneNumber;
  final DateTime enrolledOn;
  final bool isActive;

  const Student({
    required this.id,
    required this.schoolId,
    required this.fullName,
    required this.admissionNumber,
    required this.rollNumber,
    required this.level,
    required this.classId,
    this.streamId,
    this.guardianPhoneNumber,
    required this.enrolledOn,
    this.isActive = true,
  });

  factory Student.fromMap(String id, Map<String, dynamic> map) {
    return Student(
      id: id,
      schoolId: map['schoolId'] as String,
      fullName: map['fullName'] as String,
      admissionNumber: map['admissionNumber'] as String,
      // Older records created before roll numbers existed won't have this —
      // fall back to empty rather than throwing.
      rollNumber: map['rollNumber'] as String? ?? '',
      level: EducationLevel.values.firstWhere(
            (l) => l.name == map['level'],
        orElse: () => EducationLevel.primary,
      ),
      classId: map['classId'] as String,
      streamId: map['streamId'] as String?,
      guardianPhoneNumber: map['guardianPhoneNumber'] as String?,
      enrolledOn: DateTime.parse(map['enrolledOn'] as String),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'fullName': fullName,
    'admissionNumber': admissionNumber,
    'rollNumber': rollNumber,
    'level': level.name,
    'classId': classId,
    'streamId': streamId,
    'guardianPhoneNumber': guardianPhoneNumber,
    'enrolledOn': enrolledOn.toIso8601String(),
    'isActive': isActive,
  };

  @override
  List<Object?> get props => [
    id, schoolId, fullName, admissionNumber, rollNumber, level, classId, streamId,
    guardianPhoneNumber, enrolledOn, isActive,
  ];
}