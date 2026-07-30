import 'package:equatable/equatable.dart';

enum AttendanceStatus { onTime, late, absent, wrongRoom, earlyLeave }

class TeacherAttendanceRecord extends Equatable {
  final String id;
  final String schoolId;
  final String teacherId;
  final String classId;
  final String subjectId;
  final String timetableSlotId;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final DateTime? actualCheckIn;
  final DateTime? actualCheckOut;
  final AttendanceStatus status;

  const TeacherAttendanceRecord({
    required this.id,
    required this.schoolId,
    required this.teacherId,
    required this.classId,
    required this.subjectId,
    required this.timetableSlotId,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.actualCheckIn,
    this.actualCheckOut,
    required this.status,
  });

  factory TeacherAttendanceRecord.fromMap(String id, Map<String, dynamic> map) {
    return TeacherAttendanceRecord(
      id: id,
      schoolId: map['schoolId'] as String,
      teacherId: map['teacherId'] as String,
      classId: map['classId'] as String,
      subjectId: map['subjectId'] as String,
      timetableSlotId: map['timetableSlotId'] as String,
      scheduledStart: DateTime.parse(map['scheduledStart'] as String),
      scheduledEnd: DateTime.parse(map['scheduledEnd'] as String),
      actualCheckIn: map['actualCheckIn'] != null ? DateTime.parse(map['actualCheckIn'] as String) : null,
      actualCheckOut: map['actualCheckOut'] != null ? DateTime.parse(map['actualCheckOut'] as String) : null,
      status: AttendanceStatus.values.firstWhere((s) => s.name == map['status']),
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'teacherId': teacherId,
    'classId': classId,
    'subjectId': subjectId,
    'timetableSlotId': timetableSlotId,
    'scheduledStart': scheduledStart.toIso8601String(),
    'scheduledEnd': scheduledEnd.toIso8601String(),
    'actualCheckIn': actualCheckIn?.toIso8601String(),
    'actualCheckOut': actualCheckOut?.toIso8601String(),
    'status': status.name,
  };

  @override
  List<Object?> get props => [
    id, schoolId, teacherId, classId, subjectId, timetableSlotId,
    scheduledStart, scheduledEnd, actualCheckIn, actualCheckOut, status,
  ];
}