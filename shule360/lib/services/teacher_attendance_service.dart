import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_attendance_record.dart';

class TeacherAttendanceService {
  final _db = FirebaseFirestore.instance;

  String _attendancePath(String schoolId) => 'schools/$schoolId/teacherAttendance';

  Future<void> checkIn(TeacherAttendanceRecord record) async {
    await _db.collection(_attendancePath(record.schoolId)).doc(record.id).set(record.toMap());
  }

  Stream<List<TeacherAttendanceRecord>> watchTodaysAttendance(String schoolId) {
    final startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return _db
        .collection(_attendancePath(schoolId))
        .where('scheduledStart', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => TeacherAttendanceRecord.fromMap(d.id, d.data())).toList());
  }
}