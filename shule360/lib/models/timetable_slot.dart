import 'package:equatable/equatable.dart';

/// A recurring weekly slot: this class, this subject, this teacher, every
/// week on [dayOfWeek] (1 = Monday ... 7 = Sunday) between [startMinutes]
/// and [endMinutes] (minutes since midnight — simpler to store/compare
/// than full DateTimes for a repeating weekly schedule).
class TimetableSlot extends Equatable {
  final String id;
  final String schoolId;
  final String classId;
  final String subjectId;
  final String teacherId;
  final int dayOfWeek;
  final int startMinutes;
  final int endMinutes;

  const TimetableSlot({
    required this.id,
    required this.schoolId,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
  });

  String get startLabel => _formatMinutes(startMinutes);
  String get endLabel => _formatMinutes(endMinutes);

  static String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  factory TimetableSlot.fromMap(String id, Map<String, dynamic> map) {
    return TimetableSlot(
      id: id,
      schoolId: map['schoolId'] as String,
      classId: map['classId'] as String,
      subjectId: map['subjectId'] as String,
      teacherId: map['teacherId'] as String,
      dayOfWeek: map['dayOfWeek'] as int,
      startMinutes: map['startMinutes'] as int,
      endMinutes: map['endMinutes'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'classId': classId,
    'subjectId': subjectId,
    'teacherId': teacherId,
    'dayOfWeek': dayOfWeek,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
  };

  @override
  List<Object?> get props =>
      [id, schoolId, classId, subjectId, teacherId, dayOfWeek, startMinutes, endMinutes];
}

const weekdayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];